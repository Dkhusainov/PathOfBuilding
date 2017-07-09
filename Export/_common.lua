
json = require("dkjson")

function printf(...)
	print(string.format(...))
end

function round(val, dec)
	if dec then
		return math.floor(val * 10 ^ dec + 0.5) / 10 ^ dec
	else
		return math.floor(val + 0.5)
	end
end

function processTemplateFile(name, directiveTable)
	local state = { }
	local out = io.open(name..".lua", "w")
	out:write("-- This file is automatically generated, do not edit!\n")
	for line in io.lines(name..".txt") do
		local spec, args = line:match("#(%a+) ?(.*)")
		if spec then
			if directiveTable[spec] then
				directiveTable[spec](state, args, out)
			else
				printf("Unknown directive '%s'", spec)
			end
		else
			out:write(line, "\n")
		end
	end
	out:close()
end

local function qFmt(s)
	return '"'..s:gsub("\n","\\n"):gsub("\"","\\\"")..'"'
end
function writeLuaTable(out, t, indent)
	out:write('{')
	if indent then
		out:write('\n')
	end
	for k, v in pairs(t) do
		if indent then
			out:write(string.rep("\t", indent))
		end
		out:write('[')
		if type(k) == "number" then
			out:write(k)
		else
			out:write(qFmt(k))
		end
		out:write(']=')
		if type(v) == "table" then
			writeLuaTable(out, v, indent and indent + 1)
		elseif type(v) == "string" then
			out:write(qFmt(v))
		else
			out:write(tostring(v))
		end
		if next(t, k) ~= nil then
			out:write(',')
		end
		if indent then
			out:write('\n')
		end
	end
	if indent then
		out:write(string.rep("\t", indent-1))
	end
	out:write('}')
end

function loadDat(name)
	if _G[name] then
		return
	end
	printf("Loading '%s'...", name)
	local f = io.open(name..".json", "r")
	if not f then
		os.execute("pypoe_exporter dat json "..name..".json --files "..name..".dat")
		f = io.open(name..".json", "r")
	end
	local text = f:read("*a")
	f:close()
	local t = json.decode(text)[1]
	local headerMap = { }
	for i, header in pairs(t.header) do
		headerMap[header.name] = i
	end
	local rowMeta = {
		__index = function(self, index)
			if index == "print" then
				return function()
					for i, header in pairs(t.header) do
						printf("%s = %s", header.name, type(self[i]) == "table" and ("{ "..table.concat(self[i], ", ").." }") or self[i])
					end
				end
			else
				return rawget(self, headerMap[index])
			end
		end
	}
	_G[name] = setmetatable({ maxRow = #t.data - 1, headerMap = headerMap }, {
		__index = function(self, index)
			if type(index) == "number" then
				return setmetatable(t.data[index + 1], rowMeta)
			elseif headerMap[index] then
				return function(val, match)
					local col = headerMap[index]
					local out = { }
					for index, row in ipairs(t.data) do
						if type(row[col]) == "table" then
							for _, v in pairs(row[col]) do
								if (match and v:match(val)) or (not match and v == val) then
									table.insert(out, index - 1)
									break
								end
							end
						else
							if (match and row[col]:match(val)) or (not match and row[col] == val) then
								table.insert(out, index - 1)
							end
						end
					end
					return out
				end
			end
		end
	})
	_G[name:gsub("%l","")] = _G[name]
end
