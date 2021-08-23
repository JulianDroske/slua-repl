-- utils for lua scripting

function switch(key, es, default, finally)
	local ok, res = pcall(function()
		return table.pack(es[key]())
	end)
	if ok then
		-- if finally then finally() end
		return table.unpack(res)
	end
	if default then
		-- if finally then finally() end
		return default(res)
	end
end

function swimatch(key, es, default, finally)
	local ok, res = pcall(function()
		-- return table.pack(es[key]())
		if type(key) ~= 'string' then return nil end
		for i in pairs(es) do
			
			if type(i) == 'string' and key:match(i) then
				
				return table.pack(es[i]())
			end
		end
	end)
	if ok then
		-- if finally then finally() end
		return table.unpack(res)
	end
	if default then
		-- if finally then finally() end
		return default(res)
	end
end

function printSync(...)
	io.stdout:write(...)
	io.stdout:flush()
end

function string.tobtable(str)
	if not str then return nil end
	local t = {}
	for i=1,#str do
		t[i] = str:sub(i,i):byte()
	end
	return t
end

function string.totable(str)
	if not str then return nil end
	local t = {}
	for i=1,#str do
		t[i] = str:sub(i,i)
	end
	return t
end

function table.tostring(self)
	local str = '\n{\n'
	for i in pairs(self) do str = string.format('%s  %s = %s,\n', str, i, self[i]) end
	str = str..'}\n'
	return str
end

local term = {}

function term.getTermSize(maxX, maxY)
	local ln = term.ln
	maxX = maxX or 999
	maxY = maxY or 999
	printSync('\x1b[s')	-- save pos
	printSync(string.format('\x1b[%d;%dH', maxY, maxX))
	printSync('\x1b[6n')
	local ansi = (function()
		local dat, s = '', ''
		local backup = ln.getmode()
		ln.setrawmode(1)
		while true do
			s = io.stdin:read(1)
			if s == 'R' then break end
			dat = dat..s
		end
		ln.setmode(backup)
		return dat
	end)()
	printSync('\x1b[u')	-- restore pos
	local y,x = ansi:match('(%d+);(%d+)')
	return x,y
end

if pcall(function() assert((require 'linenoise').setrawmode) end) then
	term.ln = require('linenoise')
	package.preload['term'] = function() return term end
	term.getTermSize()
end
