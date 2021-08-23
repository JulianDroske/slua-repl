local ln = require('linenoise')
require 'jurt._jurt'
local term = assert(require('term'))

local orimod = nil

local termX, termY = 80, 24

local function teardown()
	local ok,err = ln.setmode(orimod)
	if not ok then print(err) end
end

local function strinsert(target, str, i)
	local left = target:sub(1, i)
	local right = target:sub(i+#str)
	return left..str..right
end

local function strdel(target, i)
	if i < 0 or i > #target then return target end
	local left = target:sub(1, i)
	local right = target:sub(i+2)
	return left..right
end

local function findDupStart(str1, str2)
	if str1 == str2 then return #str1, str1 end
	local n = math.min(#str1, #str2)
	local right = nil
	for i=1,n do if str1:byte(i) ~=  str2:byte(i) then break end right = i end
	if right == nil then return 0, '' end
	return right, str1:sub(1, right)
end

local function puts(text)
	if nil == text then
		text = ''
	else
		text = tostring(text)
	end

	return print('\n'..text)
end

local comp = nil

local function set_attempted_completion_function(callback)
	comp = callback
end

local function get_repl_history()
	return ln.gethistory()
end

local function clear_repl_history()
	ln.clearhistory()
end

local function add_to_history(text)
	if text and text ~= '' then ln.addhistory(text) end
end

local function putc(c)
	io.write(c)
	io.stdout:flush()
end

local function toLeft()
	putc('\x1b[A\n')
end

local function byCol(i)
	if i > 0 then putc('\x1b['..(i)..'C')
	else putc('\x1b['..(-i)..'D') end
end

local function toCol(i)
	toLeft()
	-- putc('\x1b['..(i)..'C')
	byCol(i)
end
	

local function clearline()
	putc('\x1b[A\n\x1b[K')
end

local function restore(prompt, did)
	if not did then did = '' end
	toLeft()
	io.write(prompt..did)
	io.stdout:flush()
	-- io.input(io.stdin)
end

local function backspace()
	putc('\x1b[1D \x1b[1D')
end

local function debug(key, prompt, inp)
	keys = key:byte(1)
	for i=2,#key do keys = keys..', '..tostring(key:byte(i)) end
	print('\n :::key press::: '..keys)
	restore(prompt, inp)
end

local lastW = '\x03'	

local function readline(prompt)
	-- io.write(prompt)
	-- io.stdout:flush()
	-- io.input(io.stdin)
	-- return io.read()
	
	-- return ln.linenoise(prompt)

	restore(prompt)
	local inputs = ''
	local curr = 0
	local curline = #ln.gethistory()+1	-- now editing
	local curbackup = ''
	local valid <const> = termX - #prompt - 1 - 1	-- lua feature, cursor itself
	local disoff = 1	-- display offset
	local function setcurrinput(str, pos)	-- str, curr(+1)
		pos = pos or #str
		if pos < 0 then pos = 0 elseif pos > #str then pos = #str end
		-- if pos + 1 < valid then disoff = 1
		-- elseif pos > disoff+valid then disoff = pos - valid end
		if pos > valid then disoff = pos - valid end
		-- disoff = math.max(math.min(pos+1, disoff), pos - valid)
		clearline()
		restore(prompt)
		local m = disoff + math.min(#str, valid)
		printSync(str:sub(disoff, m))	-- from jurt
		inputs = str
		curr = pos
		toCol(#prompt + pos - disoff + 1)
		return str
	end

	-- local accs = {'[', ']', '\'', '"'}
	local accs = {'_', '[', ']', '{', '}', "'", '"', ':'}
	local function ikW(byt)	-- English letter
		for i=1,#accs do if accs[i] == byt then return true end end
		return byt:match('%w')~=nil
	end
	local function searchBack()
		local last = nil
		local left = curr+1
		for i=curr,1,-1 do
			local byt = inputs:byte(i)
			if not ikW(inputs:sub(i, i)) then
				if byt == 46 then	-- dot
					if last and last == 46 then left = left + 1 break end
					goto continue
				else break end
			end
			::continue::
			left = i
			last = byt
		end
		return left-1, inputs:sub(left, curr)
	end
	
	while true do
		local w = io.stdin:read(1)
		local brk = false
		local exit = false
		local remain = switch(w, {
			['\x09'] = function()	-- Tab
				local str = 'Completion not set.'
				if comp	then
					local ileft, cont = searchBack()
					-- puts(cont) restore(prompt, inputs)
					local left = inputs:sub(1, ileft)
					local right = inputs:sub(curr+1)
					str = comp(cont)
					if not str or #str == 0 then return nil end
					
					local i, dup = nil, str[1]
					local p = function(...) print(...) end
					if #str == 1 then p = function() end end
					p()	-- new line
					for k,v in pairs(str) do i, dup = findDupStart(dup, v) p(v) end
					-- fill the duplicated part --
					local s = dup
					local space = ''
					if s:byte(#s) == 41 then space = ' ' end
					setcurrinput(left..dup..space..right) return nil
				else puts(str) end
				return inputs
			end,
			['\x0a'] = function()	-- LF
				putc('\n')
				brk = true
			end,
			['\x0d'] = function()	-- Enter
				putc('\n')
				brk = true
			end,
			['\x03'] = function()	-- Ctrl+C
				if lastW ~= '\x03' then puts 'Press Ctrl+C again to exit.' setcurrinput(inputs, curr)
				else exit = true end
			end,
			['\x7f'] = function()	-- Backspace
				if curr > 0 then
					-- backspace()
					if curr > 0 then curr = curr - 1 end
					setcurrinput(strdel(inputs, curr), curr)
				end
			end,
			['\x1b'] = function()	-- Esc, Direction controls
				local x = io.stdin:read(1)
				return switch(x, {
					['['] = function()
						local y = io.stdin:read(1)
						return switch(y, {	-- compact with ANSI
							['A'] = function()	-- Up
								local hist = ln.gethistory()
								if curline > #hist then curbackup = inputs end
								if curline > 1 then
									curline = curline - 1
								end
								if #hist == 0 then return inputs end
								setcurrinput(hist[curline])
							end,
							['B'] = function()	-- Down
								local hist = ln.gethistory()
								if curline < #hist then
									curline = curline + 1
									setcurrinput(hist[curline])
									return nil
								elseif curline == #hist then
									curline = #hist+1
								elseif curline == #hist+1 then
									curbackup = inputs
								end
								setcurrinput(curbackup)
							end,
							['C'] = function()	-- Right
								if curr < #inputs then
									curr = curr + 1
									-- putc('\x1b[C')
									setcurrinput(inputs, curr)
								end
							end,
							['D'] = function()	-- Left
								if curr > 0 then
									curr = curr - 1
									-- putc('\x1b[D')
									setcurrinput(inputs, curr)
								end
							end
						}, function(err)
							debug(w..x..y, prompt, inputs)
							puts(err)
							setcurrinput(inputs, curr)
						end)
					end
				}, function()
					debug(w..x, prompt, inputs)
					setcurrinput(inputs, curr)
				end)
			end
		}, function(err)
			local wb = w:byte()
			if wb > 31 and wb < 127 then
				-- inputs = strinsert(inputs, w, curr)
				-- restore(prompt, inputs)
				curr = curr + 1
				-- toCol(#prompt+curr)
				setcurrinput(strinsert(inputs, w, curr-1), curr)
			else print('\n'..err) debug(w, prompt, inputs) setcurrinput(inputs, curr) end
		end)
		if exit then inputs=nil break end
		if remain then restore(prompt, remain) end
		lastW = w
		if brk then break end
	end
	return inputs
end

local set_startup_hook = function()
	orimod, err = ln.getmode()
	if not orimod then print(err) end
	local ok,err = ln.setrawmode(1)
	if not ok then print(err) end

	termX, termY = term.getTermSize()
end

local _M = setmetatable({
	set_startup_hook = set_startup_hook,
	teardown = teardown,
	puts = puts,
	set_attempted_completion_function = set_attempted_completion_function,
	add_to_history = add_to_history,
	get_repl_history = get_repl_history,
	clear_repl_history = clear_repl_history
}, { __call = function(_, ...) return readline(...) end })

return _M
