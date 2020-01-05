--[[
	Event module created by Centurian.
	This can be used in "Pure Lua"
--]]

local ev = { };
do
	local function spawn(f) coroutine.resume(coroutine.create(f)); end
	
	local a = { };
	local b = { };
	
	setmetatable(b, {
		__index = function(self, index)
			return rawget(a, index);
		end;
		
		__newindex = function(self, index, new)
			if (index == '!rem') then
				a[new] = nil;
				return;
			end
			rawset(a, index, new)
		end
	})
	
	function ev:EventExists(name)
		if (b[name]) then return true; else return false; end
	end
	
	function ev:AddEvent(name, f)
		if (ev:EventExists(name)) then
			table.insert(b[name], f);
		else
			b[name] = { f };
		end
	end
	
	function ev:WaitForEvent(name, ...)
		local extargs = {...};
		local args;
		local function condition(...)
			local wegood = true;
			for _, v in next, extargs do
				local broke = false;
				for _, w in next, {...} do
					if (v == w) then
						broke = true;
						break;
					end
				end
				
				wegood = broke;
				if (not wegood) then
					break;
				end
			end
			
			if (wegood) then
				spawn(function()
					ev:RemoveEvent(name);
				end);
				
				args = {...};
			end
		end
		
		if (ev:EventExists(name)) then
			table.insert(b[name], condition);
		else
			b[name] = { condition };
		end
		
		repeat wait(); until not ev:EventExists(name);
		return unpack(args or { });
	end
	
	function ev:GetEvent(name)
		return b[name] or {};
	end
	
	function ev:FireEvent(name, ...)
		local args = {...};
		if (ev:EventExists(name)) then
			for _, f in next, ev:GetEvent(name) do
				spawn(function() f(unpack(args)); end);
			end
		end
	end
	
	function ev:RemoveEvent(name)
		b['!rem'] = name;
	end
end

return ev;
