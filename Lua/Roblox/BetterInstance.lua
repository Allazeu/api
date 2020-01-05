--[[
  BetterInstance by Centurian.
  Basically is an "improvement" to the Instance library already provided by ROBLOX.
--]]

local Instance;

do
	local fenv = getfenv(0);
	local _o = {
		instance = fenv.Instance;
	};
	
	Instance = {
		new = function(Class, Parent, prop)
			if (type(Parent) == 'table') then
				prop = Parent;
				Parent = nil;
			end
			
			local inst = _o.instance.new(Class, Parent);
			if (not prop) then return inst; end
			local wf = false;
			
			for Property, Value in pairs(prop) do
				local Property = tostring(Property);
				xpcall(function()
					inst[Property] = Value;
				end, function() error('Property "' .. tostring(Property) .. '" does not exist for instance "' .. tostring(inst.ClassName) .. '"'); end);
			end
			
			return inst;
		end;
		
		clone = function(Object, prop)
			local inst = Object:Clone();
			if (not prop) then return inst; end
			if (typeof(prop) ~= 'table') then inst.Parent = prop; return inst; end
			for Property, Value in pairs(prop) do
				local Property = tostring(Property);
				xpcall(function()
					inst[Property] = Value;
				end, function() error('Property "' .. tostring(Property) .. '" does not exist for instance "' .. tostring(inst.ClassName) .. '"'); end);
			end
			
			return inst;
		end;
		
		destroy = function(instance, Delay)
			if (instance) then
				game:GetService('Debris'):AddItem(instance, Delay or 0);
			end
		end;
		
		set = function(inst, prop)
			if (not prop) then return inst; end
			if (typeof(prop) ~= 'table') then inst.Parent = prop; return inst; end
			for Property, Value in pairs(prop) do
				local Property = tostring(Property);
				xpcall(function()
					inst[Property] = Value;
				end, function() error('Property "' .. tostring(Property) .. '" does not exist for instance "' .. tostring(inst.ClassName) .. '"'); end);
			end
			
			return inst;
		end;
	};
end

return Instance;
