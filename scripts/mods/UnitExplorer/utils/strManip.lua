local mod = get_mod("UnitExplorer")

strManip = {}
strManip.__index = strManip

--replaces special pattern matching characters with less common patterns
function strManip:replacer(someString, revBool)
	
	local replacement_table = {
		bigSpess = "	",
		spess = "\n",
		openPara ="%(",
		closePara ="%)",
		period ="%.",
		percent ="%%",
		plus ="%+",
		minus ="%-",
		star ="%*",
		quest ="%?",
		openBracket ="%[",
		carrot ="%^",
		money ="%$"
	}
	
	if revBool then 
		for k,v in pairs(replacement_table) do
			someString = string.gsub(someString, v, tostring(k))
		end
	else
		for k,v in pairs(replacement_table) do
			someString = string.gsub(someString, tostring(k), v)
		end
	end
	
	return someString
end

--only considers the first 3 decimal places to reduce the error from rounding when normalizing the rotation vector
function strManip:ceil(tableFloatString)
	floatString = ""
	for k,v in pairs(tableFloatString) do
		local i,j = string.find(v, '%.')
		if i ~= nil then
			v = v:sub(0, i+3)
		end
		floatString = floatString..v.."\n"
	end
	return floatString
end