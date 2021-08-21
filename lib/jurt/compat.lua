-- to compat with slua 5.4

unpack = table.unpack
pack = table.pack

getfenv = function(k)
	local i=1
	while true do
		local name, val = debug.getupvalue(k, i)
		if name == '_ENV' then return val
			elseif not name then break end
		i = i+1
	end
end

setfenv = function(k, v)
	local i=1
	while true do
		local name = debug.getupvalue(k, i)
		if name == '_ENV' then debug.upvaluejoin(k, i, (function() return env end), 1) break
			elseif not name then break end
		i = i+1
	end
end

loadstring = load

