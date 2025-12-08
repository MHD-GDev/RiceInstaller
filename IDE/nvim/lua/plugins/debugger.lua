return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"jay-babu/mason-nvim-dap.nvim",
	},
	config = function()
		local dap, dapui, nio = require("dap"), require("dapui"), require("nio")

		-- mason-nvim-dap
		require("mason-nvim-dap").setup({
			ensure_installed = { "codelldb", "bash-debug-adapter", "debugpy" },
			automatic_installation = true,
			handlers = {},
		})

		-- dapui
		require("dapui").setup()
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		-- cpp
		dap.configurations.cpp = {
			{
				name = "Launch file",
				type = "codelldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
		dap.configurations.c = dap.configurations.cpp
		dap.configurations.rust = dap.configurations.cpp

		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = vim.fn.expand("~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb"),
				args = { "--port", "${port}" },
			},
		}

		-- gdscript
		dap.adapters.godot = {
			type = "server",
			host = "127.0.0.1",
			port = 6006,
		}
		dap.configurations.gdscript = {
			{
				type = "godot",
				request = "launch",
				name = "Launch scene",
				project = "${workspaceFolder}",
				launch_scene = true,
			},
		}

		-- bash
		dap.adapters.bashdb = {
			type = "executable",
			command = vim.fn.expand("~/.local/share/nvim/mason/packages/bash-debug-adapter/bash-debug-adapter"),
			name = "bashdb",
		}
		dap.configurations.sh = {
			{
				type = "bashdb",
				request = "launch",
				name = "Launch file",
				showDebugOutput = true,
				pathBashdb = vim.fn.expand(
					"~/.local/share/nvim/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb"
				),
				pathBashdbLib = vim.fn.expand(
					"~/.local/share/nvim/mason/packages/bash-debug-adapter/extension/bashdb_dir"
				),
				trace = true,
				file = "${file}",
				program = "${file}",
				cwd = "${workspaceFolder}",
				pathCat = "cat",
				pathBash = "/bin/bash",
				pathMkfifo = "mkfifo",
				pathPkill = "pkill",
				args = {},
				env = {},
				terminalKind = "integrated",
			},
		}

		--python
		dap.adapters.python = function(cb, config)
			if config.request == "attach" then
				local port = (config.connect or config).port
				local host = (config.connect or config).host or "127.0.0.1"
				cb({
					type = "server",
					port = assert(port, "`connect.port` is required for a python `attach` configuration"),
					host = host,
					options = {
						source_filetype = "python",
					},
				})
			else
				cb({
					type = "executable",
					command = vim.fn.expand("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"),
					args = { "-m", "debugpy.adapter" },
					options = {
						source_filetype = "python",
					},
				})
			end
		end
		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				pythonPath = function()
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
						return cwd .. "/venv/bin/python"
					elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
						return cwd .. "/.venv/bin/python"
					else
						return "/usr/bin/python"
					end
				end,
			},
		}

		-- keymaps
		vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "Debugger Breakpoint" })
		vim.keymap.set("n", "<leader>ds", dap.continue, { desc = "Debugger Start" })
	end,
}
