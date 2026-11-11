local M = {}

local platform = require("configs.platform")

local config_dir = vim.fn.stdpath("config")
local colors_file = config_dir .. "/rice_colors.lua"
local colors_filename = vim.fn.fnamemodify(colors_file, ":t")

local callbacks = {}
local current_colors
local watcher
local reload_pending = false

local function load_colors()
	if not platform.is_desktop_linux then
		return nil
	end

	if vim.fn.filereadable(colors_file) ~= 1 then
		return nil
	end

	local ok, colors = pcall(dofile, colors_file)

	if not ok or type(colors) ~= "table" then
		return nil
	end

	return colors
end

local function notify_callbacks()
	for name, callback in pairs(callbacks) do
		local ok, err = pcall(callback, current_colors)

		if not ok then
			vim.notify(
				("Rice color callback '%s' failed: %s"):format(name, err),
				vim.log.levels.ERROR
			)
		end
	end
end

function M.get_colors()
	return current_colors
end

function M.register(name, callback)
	assert(type(name) == "string", "Callback name must be a string")
	assert(type(callback) == "function", "Callback must be a function")

	callbacks[name] = callback

	local ok, err = pcall(callback, current_colors)

	if not ok then
		vim.notify(
			("Rice color callback '%s' failed: %s"):format(name, err),
			vim.log.levels.ERROR
		)
	end
end

function M.reload()
	if not platform.is_desktop_linux then
		return false
	end

	local new_colors = load_colors()

	if not new_colors then
		return false
	end

	current_colors = new_colors
	notify_callbacks()

	return true
end

function M.start()
	if not platform.is_desktop_linux or watcher then
		return
	end

	-- Load the current palette before plugins register callbacks.
	current_colors = load_colors()

	watcher = vim.uv.new_fs_event()

	local ok, err = watcher:start(
		config_dir,
		{},
		function(_, filename)
			if filename and filename ~= colors_filename then
				return
			end

			vim.schedule(function()
				if reload_pending then
					return
				end

				reload_pending = true

				vim.defer_fn(function()
					reload_pending = false
					M.reload()
				end, 200)
			end)
		end
	)

	if not ok then
		watcher:close()
		watcher = nil

		vim.notify(
			"Could not watch rice_colors.lua: " .. tostring(err),
			vim.log.levels.WARN
		)
	end
end

return M
