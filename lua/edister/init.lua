local M = {}
local plugin_opts = require('edister.config')

-- You can make the argument that "oh you could use [blank] instead to write this smarter as a character range" or whatever,
-- at this point I don't even think it's worth it.
-- Thanks to the power of vim, writing out all of these took maybe 30 seconds;
-- And I believe it'll be easier to understand to the potential code reader, rather than looking at some appended character range.
-- Because it's literally just every single character that is allowed. Very simple and direct.
local read_write_registers = {
	"'",
	'"',
	'+',
	'*',
	'#',
	'/',
	'=',
	'_',
	'0',
	'1',
	'2',
	'3',
	'4',
	'5',
	'6',
	'7',
	'8',
	'9',
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
	'g',
	'h',
	'i',
	'j',
	'k',
	'l',
	'm',
	'n',
	'o',
	'p',
	'q',
	'r',
	's',
	't',
	'u',
	'v',
	'w',
	'x',
	'y',
	'z',
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z',
}

local writable_registers = read_write_registers

local readable_registers = {
	':',
	';',
	'.',
	'%'
}
vim.list_extend(readable_registers, read_write_registers)

---Get a character from the user, unless they press escape, in which case return nil, usually to cancel whatever action the user wanted to do.
---@param prompt string what text to show when asking the user for the character.
local function get_char(prompt)
	prompt = prompt or ''
	vim.api.nvim_echo({ { prompt, 'Input' } }, true, {})
	local char = vim.fn.getcharstr()
	-- That's the escape character (`<Esc>`). Not sure how to specify it smarter
	-- In other words, if you pressed escape, we return nil
	---@diagnostic disable-next-line: cast-local-type
	if char == '' then return nil end
	return char
end

---@param table any[]
---@param element any
---@return boolean
function table.contains(table, element)
	for _, thingy in ipairs(table) do
		if thingy == element then return true end
	end
	return false
end

---@return table win_opts to be used in `vim.api.nvim_open_win()`
local function build_win_opts()
	local width = plugin_opts.absolute_width and plugin_opts.width or math.floor(vim.o.columns * plugin_opts.width)
	local height = plugin_opts.absolute_height and plugin_opts.height or math.floor(vim.o.lines * plugin_opts.height)
	local columns = plugin_opts.columns or math.min((vim.o.columns - width) / 2)
	local rows = plugin_opts.rows or math.min((vim.o.lines - height) / 2)
	return {
		relative = 'editor',
		width = width,
		height = height,
		col = columns,
		row = rows,
		border = plugin_opts.border,
	}
end

local function ask_reg_type()
	local picked = vim.fn.confirm('Pick register type', 'Keep\nLine\nChar\nBlock')
	if picked == 0 then return nil end
	if picked == 1 then
		return 'keep'
	elseif picked == 2 then
		return 'l'
	elseif picked == 3 then
		return 'c'
	elseif picked == 4 then
		return 'b'
	end
end

local function resolve_default_register()
	if vim.go.clipboard == 'unnamedplus' or vim.go.clipboard == 'unnamedplus,unnamed' then
		return '+'
	elseif vim.go.clipboard == 'unnamed' or vim.go.clipboard == 'unnamed,unnamedplus' then
		return '*'
	else
		return '"'
	end
end

---@param register string?
---@param message string?
---@param readable boolean?
local function validate_register(register, message, readable)
	if not register then
		local char = get_char(message or 'enter a register: ')
		if not char then return nil end -- no error message here because if you press escape, it is obvious you did that to cancel the action.
		register = char
	end

	if register:match('%u') then
		register = register:lower() -- the `%u` pattern catches uppercase letters
	elseif register == "'" then
		register = resolve_default_register()
	elseif register == ';' then
		register = ':'
	end

	if not table.contains(readable and readable_registers or writable_registers, register) then
		vim.notify('edister: only ' .. (readable and 'readable' or 'writable') .. ' registers are allowed\nyou passed: ' .. register)
		return nil
	end

	return register
end

---The register you want to edit.
---If you don't pass this argument, you're going to be asked for a register interactively (this lets you have to have only a single mapping for this plugin, that will work for every register, rather than having to make ~26 separate mappings).
---Only writable registers are allowed (", +, *, 0-9, a-z, A-Z (they get lowercased.
---This way you can accidentally press shift and for it to still work), #, =, _ (you can never *read* from this register, so it's useless to edit.
---You can use it as a hack to get a blank floating window to quickly do something in), /, ' gets resolved to whatever your default register effectively is, according to the clipboard option — if clipboard is unnamed or unnamed,unnamedplus, gets resolved to *; if it's unnamedplus or unnamedplus,unnamed, gets resolved to +, if clipboard option is anything else, gets resolved to ". ; gets turned into :).
---@param register string?
---The register type, as accepted in `:h setreg()`.
---If `nil` (not passed), the register type is kept the same.
---For example, if you're editing a linewise register, it stays linewise.
---If it was blockwise, it would stay blockwise.
---This parameter is useful if you want to *switch* a linewise register into a characterwise register, for example.
---If passed "ask", once you close the editing window, you will be asked one of l / c / b (single character that you're expected to press) to change the register into linewise / characterwise / blockwise.
---If you press escape in that prompt, your edit won't be saved at all.
---If you press the wrong character, that isn't one of l / c / b, the register type will not be changed, and the result will be like you didn't pass `reg_type` to begin with.
---@param reg_type string|'ask'?
function M.edit_register(register, reg_type)
	register = validate_register(register)
	if not register then return end

	local ask = false
	if reg_type == 'ask' then
		ask = true
		reg_type = nil
	end

	if not reg_type then reg_type = vim.fn.getregtype(register) end
	---@diagnostic disable-next-line: redundant-parameter
	local lines = vim.fn.getreg(register, 1, true)

	local buf = vim.api.nvim_create_buf(false, true)
	---@diagnostic disable-next-line: param-type-mismatch
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local win_opts = build_win_opts()
	local window = vim.api.nvim_open_win(buf, true, win_opts)
	vim.api.nvim_win_set_option(window, 'foldcolumn', '0') -- I do see that it's deprecated, but how the hell else do you do this then?
	vim.api.nvim_win_set_option(window, 'number', false)
	vim.api.nvim_win_set_option(window, 'relativenumber', false)

	vim.api.nvim_create_autocmd('BufWinLeave', {
		pattern = '<buffer>',
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			if ask then
				local entered = ask_reg_type()
				if not entered then return end
				if entered ~= 'keep' then reg_type = entered end
			end
			vim.fn.setreg(register, lines, reg_type)
		end,
	})
end

---@param one string? the register to move from. Everything from the comment about the register parameter in `edit_register` applies here too.
---@param another string? the register to move into. Everything applies here too.
---@param reg_type string|'ask'? everything from the comment about the `reg_type` parameter in `edit_register` applies here too.
function M.move_from_one_to_another(one, another, reg_type)
	one = validate_register(one, 'enter the register to move from: ', true)
	if not one then return end
	another = validate_register(another, 'enter the register to move into: ')
	if not another then return end

	local ask = false
	if reg_type == 'ask' then
		ask = true
		reg_type = nil
	end

	if not reg_type then reg_type = vim.fn.getregtype(one) end
	---@diagnostic disable-next-line: redundant-parameter
	local lines = vim.fn.getreg(one, 1, true)

	if ask then
		local entered = ask_reg_type()
		if not entered then return end
		if entered ~= 'keep' then reg_type = entered end
	end
	vim.fn.setreg(another, lines, reg_type)
end

function M.setup(opts) plugin_opts = vim.tbl_deep_extend('force', plugin_opts, opts) end

return M
