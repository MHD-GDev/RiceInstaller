return {
	"mfussenegger/nvim-dap",
	event = "VeryLazy",

	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"jay-babu/mason-nvim-dap.nvim",
	},

	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		local data_dir = vim.fn.stdpath("data")
		local mason_packages = vim.fs.joinpath(data_dir, "mason", "packages")

		local function package_path(package, ...)
			return vim.fs.joinpath(mason_packages, package, ...)
		end

		local function find_executable(paths)
			for _, path in ipairs(paths) do
				if vim.fn.executable(path) == 1 then
					return path
				end
			end

			return nil
		end

		require("mason-nvim-dap").setup({
			ensure_installed = {},
			automatic_installation = false,
		})

		dapui.setup()

		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end

		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end

		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		local codelldb = find_executable({
			package_path("codelldb", "extension", "adapter", "codelldb"),
			package_path("codelldb", "extension", "adapter", "codelldb.exe"),
			package_path("codelldb", "codelldb"),
			package_path("codelldb", "codelldb.exe"),
		})

		if codelldb then
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = codelldb,
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input(
							"Path to executable: ",
							vim.fn.getcwd() .. "/",
							"file"
						)
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			dap.configurations.c = dap.configurations.cpp
			dap.configurations.rust = dap.configurations.cpp
		end

		local debugpy_python = find_executable({
			package_path("debugpy", "venv", "bin", "python"),
			package_path("debugpy", "venv", "Scripts", "python.exe"),
		})

		if debugpy_python then
			dap.adapters.python = {
				type = "executable",
				command = debugpy_python,
				args = { "-m", "debugpy.adapter" },
				options = {
					source_filetype = "python",
				},
			}

			local function find_python()
				local cwd = vim.fn.getcwd()
				local windows_python = package_path(
					"debugpy",
					"venv",
					"Scripts",
					"python.exe"
				)

				local candidates

				if vim.fn.executable(windows_python) == 1 then
					candidates = {
						vim.fs.joinpath(cwd, ".venv", "Scripts", "python.exe"),
						vim.fs.joinpath(cwd, "venv", "Scripts", "python.exe"),
					}
				else
					candidates = {
						vim.fs.joinpath(cwd, ".venv", "bin", "python"),
						vim.fs.joinpath(cwd, "venv", "bin", "python"),
					}
				end

				local project_python = find_executable(candidates)

				return project_python
					or vim.fn.exepath("python3")
					or vim.fn.exepath("python")
			end

			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = find_python,
				},
			}
		end

		local bash_adapter = find_executable({
			package_path("bash-debug-adapter", "bash-debug-adapter"),
			package_path("bash-debug-adapter", "bash-debug-adapter.cmd"),
		})

		local bash = vim.fn.exepath("bash")
		local cat = vim.fn.exepath("cat")
		local mkfifo = vim.fn.exepath("mkfifo")
		local pkill = vim.fn.exepath("pkill")

		local bashdb_dir = package_path(
			"bash-debug-adapter",
			"extension",
			"bashdb_dir"
		)

		local bashdb = vim.fs.joinpath(bashdb_dir, "bashdb")

		if bash_adapter
			and bash ~= ""
			and cat ~= ""
			and mkfifo ~= ""
			and pkill ~= ""
			and vim.fn.filereadable(bashdb) == 1
		then
			dap.adapters.bashdb = {
				type = "executable",
				command = bash_adapter,
				name = "bashdb",
			}

			dap.configurations.sh = {
				{
					name = "Launch file",
					type = "bashdb",
					request = "launch",
					showDebugOutput = true,
					pathBashdb = bashdb,
					pathBashdbLib = bashdb_dir,
					trace = true,
					file = "${file}",
					program = "${file}",
					cwd = "${workspaceFolder}",
					pathCat = cat,
					pathBash = bash,
					pathMkfifo = mkfifo,
					pathPkill = pkill,
					args = {},
					env = {},
					terminalKind = "integrated",
				},
			}
		end

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

		vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, {
			desc = "Debugger: Toggle breakpoint",
		})

		vim.keymap.set("n", "<leader>ds", dap.continue, {
			desc = "Debugger: Start / Continue",
		})

		vim.keymap.set("n", "<leader>du", dapui.toggle, {
			desc = "Debugger: Toggle UI",
		})
	end,
}
