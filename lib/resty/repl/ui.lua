
-- MIT License
-- 
-- Copyright (c) 2017 Aliaksandr Rahalevich
--
-- Modification by 2021 @ JulianDroske
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


local readline = require 'resty.repl.readline'
local new_completer = require('resty.repl.completer').new
local new_sources = require('resty.repl.sources').new

local context = function()
	if _G.ngx and _G.ngx.get_phase then
		return 'ngx(' .. _G.ngx.get_phase() .. ')'
	else
		return 'lua(main)'
	end
end

local function startsWith(str, str2)
	if str == nil and str2 == nil then return true end
	if str == nil or str2 == nil then return false end
	if str == str2 or str:sub(1,#str2+1) == str2..' ' then return true end
	return false
end

local commands = {}

commands[{nil, '.exit'}] = function(_, input)
	readline.teardown()
	readline.puts()
	input.stop = true
end

commands[{'.exit!'}] = function(_, input)
	input.exit = true
	readline.teardown()
end

commands[{'.where'}] = function(self, input)
	self:whereami()
	input.code = nil
end

commands[{'.load'}] = function(_, input)
	local code = input.code
	input.code = nil
	local ok, err = pcall(function() readline.clear_repl_history() end)
	if not ok then print('Warning: Cannot clear REPL history in current session.') end
	local file = code:match('.load%S(.+)')
	if not file or file == '' then file = '.slua_repl_history' end
	local fp, error = io.open(file, 'r')
	if fp then
		while true do
			local line = fp:read()
			if not line then break end
			readline.add_to_history(line)
		end
		fp:close()
		print('Done.')
	else print(error) end
end

commands[{'.save'}] = function(_, input)
	local code = input.code
	input.code = nil
	local file = code:match('.save%S(.+)')
	local history = nil
	local ok, err = pcall(function() history = readline.get_repl_history() end)
	if not ok then print('Error: Getting history from current session is not supported.') return; end
	history = (function(hist) local h = '' for i in pairs(hist) do h = h..'\n'..hist[i] end return h end)(history)
	if not file or file == '' then file = '.slua_repl_history' end
	local fp, error = io.open(file, 'w+')
	if fp then
		fp:write(history)
		fp:flush()
		fp:close()
		print('Done.')
	else print(error) end
end

local command_codes = {}
for all_codes, _ in pairs(commands) do
	local codes_len = select('#', unpack(all_codes))
	for i = 1, codes_len do
		local code = all_codes[i]
		if code then table.insert(command_codes, code) end
	end
end

local InstanceMethods = {}
function InstanceMethods:readline()
	local input = { code = readline(self:prompt_line()) }

	for all_command_codes, command_handler in pairs(commands) do
		local codes_len = select('#', unpack(all_command_codes))
		for i = 1, codes_len do
			-- if input.code == all_command_codes[i] then
			if startsWith(input.code, all_command_codes[i]) then
				command_handler(self, input)
				return input
			end
		end
	end

	return input
end

function InstanceMethods:prompt_line()
	local res = '[' .. self.line_count .. '] ' .. context() .. '> '
	self.line_count = self.line_count + 1
	return res
end

function InstanceMethods.add_to_history(_, text)
	readline.add_to_history(text)
end

function InstanceMethods:whereami()
	local ctx = self.sources:whereami()
	if ctx then readline.puts(ctx) end
end

local mt = { __index = InstanceMethods }

local function new(binding)
	local ui = setmetatable({
		completer = new_completer(binding, command_codes),
		sources   = new_sources(binding),
		line_count = 1,
	}, mt)

	readline.set_attempted_completion_function(function(word)
		return ui.completer:find_matches(word)
	end)

	readline.set_startup_hook(function()
		if 2 == ui.line_count then ui:whereami() end
	end)

	return ui
end

return { new = new }
