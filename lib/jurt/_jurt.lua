-- utils for lua scripting

function switch(key, es, default, finally)
	local cont = nil
	local ok, err = pcall(function()
		cont = es[key]()
	end)
	if ok then
		-- if finally then finally() end
		return cont
	end
	if default then
		-- if finally then finally() end
		return default(err)
	end
end