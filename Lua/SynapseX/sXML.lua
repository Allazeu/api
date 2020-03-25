--[[
	sXML - Synapse X(ML)
	Library for parsing XML files for use in Synapse X
	
	Based off: https://github.com/Cluain/Lua-Simple-XML-Parser
	- centurian
--]]

local file = { };
do
	function file.exists(path)
		return isfile(path);
	end
	
	function file.read(path)
		if (file.exists(path)) then
			return readfile(path);
		end
	end
	
	function file.write(path, data)
		if (file.exists(path)) then
			writefile(path, data);
		end
	end
end

local function newNode(name)
	local node = {
		___value = nil,
		___name = name,
		___children = { },
		___props = { },
	};
	
	function node:value()
		return self.___value;
	end
	
	function node:setValue(val)
		self.___value = val;
	end
	
	function node:name()
		return self.___name;
	end
	
	function node:setName(name)
		self.___name = name;
	end
	
	function node:addChild(child)
		if self[child:name()] ~= nil then
			if type(self[child:name()].name) == "function" then
				local tempTable = { };
				table.insert(tempTable, self[child:name()]);
				self[child:name()] = tempTable;
			end
			
			table.insert(self[child:name()], child);
		else
			self[child:name()] = child;
		end
		table.insert(self.___children, child);
	end
	
	function node:properties()
		return self.___props;
	end
	
	function node:numProperties()
		return #self.___props;
	end
	
	function node:addProperty(name, value)
		local lName = "@" .. name;
		if self[lName] ~= nil then
			if type(self[lName]) == "string" then
				local tempTable = { };
				table.insert(tempTable, self[lName]);
				self[lName] = tempTable;
			end
			table.insert(self[lName], value);
		else
			self[lName] = value;
		end
		
		table.insert(self.___props, { name = name, value = self[name] });
	end
	
	setmetatable(node, {
		__len = function(self)
			return #self.__children;
		end,
	});
	
	return node
end

return function()
	local XmlParser = { };

	function XmlParser.output(value)
		value = string.gsub(value, "&", "&amp;"); -- '&' -> "&amp;"
		value = string.gsub(value, "<", "&lt;"); -- '<' -> "&lt;"
		value = string.gsub(value, ">", "&gt;"); -- '>' -> "&gt;"
		value = string.gsub(value, "\"", "&quot;"); -- '"' -> "&quot;"
		value = string.gsub(value, "([^%w%&%;%p%\t% ])",
			function(c)
				return string.format("&#x%X;", string.byte(c))
			end);
		return value;
	end
	
	function XmlParser.input(value)
		value = string.gsub(value, "&#x([%x]+)%;",
			function(h)
				return string.char(tonumber(h, 16));
			end);
		value = string.gsub(value, "&#([0-9]+)%;",
			function(h)
				return string.char(tonumber(h, 10));
			end);
		value = string.gsub(value, "&quot;", "\"");
		value = string.gsub(value, "&apos;", "'");
		value = string.gsub(value, "&gt;", ">");
		value = string.gsub(value, "&lt;", "<");
		value = string.gsub(value, "&amp;", "&");
		return value;
	end
	
	function XmlParser.ParseArgs(node, s)
		string.gsub(s, "(%w+)=([\"'])(.-)%2", function(w, _, a)
			node:addProperty(w, XmlParser.input(a));
		end);
	end
	
    function XmlParser.parse(xmlText)
		local stack = {}
		local top = newNode();
		table.insert(stack, top)
		local ni, c, label, xarg, empty
		local i, j = 1, 1
		while true do
			ni, j, c, label, xarg, empty = string.find(xmlText, "<(%/?)([%w_:]+)(.-)(%/?)>", i)
			if not ni then break; end
			local text = string.sub(xmlText, i, ni - 1);
			if not string.find(text, "^%s*$") then
				local lVal = (top:value() or "") .. XmlParser.input(text);
				stack[#stack]:setValue(lVal);
			end
			
			if (empty == '/') then -- empty element tag
				local lNode = newNode(label);
				XmlParser.ParseArgs(lNode, xarg);
				top:addChild(lNode);
			elseif (c == '') then -- start tag
				local lNode = newNode(label);
				XmlParser.ParseArgs(lNode, xarg);
				
				table.insert(stack, lNode);
				top = lNode;
			else -- end tag
				local toclose = table.remove(stack); -- remove top
				
				top = stack[#stack];
				if #stack < 1 then
					error("LXML: nothing to close with " .. label);
				end
				
				if toclose:name() ~= label then
					error("LXML: trying to close " .. toclose.name .. " with " .. label);
				end
				top:addChild(toclose);
			end
			
			i = j + 1;
		end
		
		local text = string.sub(xmlText, i);
		if #stack > 1 then
			error("LXML: unclosed " .. stack[#stack]:name());
		end
		
		return top;
	end
	
	function XmlParser.open(xmlFilename)
		local rval;
		local s, e = pcall(function()
			local xmlText = file.read(xmlFilename) -- read file content
			rval = XmlParser.parse(xmlText);
		end);
		
		if (not s) then
			warn("LXML: " .. e);
			return nil;
		end
		
		return rval;
	end
	
	return XmlParser, file;
end
