-- to compat with slua 5.4

if not unpack then unpack = table.unpack end
if not pack then pack = table.pack end

if not getfenv then getfenv = function(k)
	local i=1
	while true do
		local name, val = debug.getupvalue(k, i)
		if name == '_ENV' then return val
			elseif not name then break end
		i = i+1
	end
end end

if not setfenv then setfenv = function(k, v)
	local i=1
	while true do
		local name = debug.getupvalue(k, i)
		if name == '_ENV' then debug.upvaluejoin(k, i, (function() return env end), 1) break
			elseif not name then break end
		i = i+1
	end
end end

if not loadstring then loadstring = load end

