-- The options specified here are defaults. So if you agree with them, you don't need to set them in your configuration. Matter of fact, you don't even need to call the setup function in that case.
local default_opts = {
	-- Interpret the `width` option as the amount of columns, rather than a percentage.
	absolute_width = false,
	-- Same as above, but for `height`
	absolute_height = false,
	-- The percentage of terminal window width that the floating window should occupy. 60% by default.
	width = 0.6,
	-- Same as above, but for height. 30% by default.
	height = 0.3,
	-- If unset, center the floating window vertically. If set to a number, offset the window that many columns from the left side of your neovim window.
	columns = nil,
	-- Same as above, but *horizontally* instead, and from the top side of your neovim window. If you don't set `rows` and `columns`, the floating window is fully centered.
	rows = nil,
	-- Expects the same thing as the `border` option in `:h nvim_open_win()`. No borders by default.
	border = nil,
}

return default_opts
