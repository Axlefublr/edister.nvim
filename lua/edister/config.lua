---@class EdisterOpts
---Interpret the `width` option as the amount of columns, rather than a percentage.
---@field absolute_width boolean?
---Same as above, but for `height`.
---@field absolute_height boolean?
---The percentage of terminal window width that the floating window should occupy. 60% by default.
---Expects a float by default, an integer with the `absolute_width` option on.
---@field width number?
---Same as above, but for height. 30% by default.
---@field height number?
---If unset (nil), center the floating window vertically.
---If set to a number, offset the window that many columns from the left side of your neovim window.
---@field columns number?
---Same as above, but *horizontally* instead, and from the top side of your neovim window.
---If you don't set `rows` and `columns`, the floating window is fully centered.
---@field rows number?
---Expects the same thing as the `border` option in `:h nvim_open_win()`.
---No borders by default.
---@field border 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|string[]|nil

-- The options specified here are defaults. So if you agree with them, you don't need to set them in your configuration. Matter of fact, you don't even need to call the setup function in that case.
---@type EdisterOpts
local default_opts = {
	absolute_width = false,
	absolute_height = false,
	width = 0.6,
	height = 0.3,
	columns = nil,
	rows = nil,
	border = nil,
}

return default_opts
