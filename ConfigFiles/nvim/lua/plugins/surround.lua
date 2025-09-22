return {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup({
        })
    end,
}

-- add command : ys + {motion(i,n,v)} + {char(the one you want to add)}

-- change command: cs + {target} + {replacement}

-- delete command : ds + {char}
