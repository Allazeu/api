--[[
	DualPriority
		A dual-threaded priority call queue for Lua.
		Usage:
			Once the API has been required, setup the number of queues needed (queues can be added during runtime)
			Adding queues is as easy as typing "queue.add(priority)". The priority is the level of priority to use (lower is more prioritized)
			To initialize the queue, run in a seperate thread "queue.run()"
		Includes:
			Error-handling - "seq-catch" catches errors that functions in a queue raise and safely logs them
			Fluidity - dynamically change the priorities of queues and the priorities of their functions
			Cancelling - stop the queue from running after the current function has finished
		Notes:
			I (wriaith) created this to improve performance issues with my new scripts. I will most likely by improving this design in the future.
--]]

local queue = { };
do
	local tray = { };
	local queue_disable = false;
	
	local order = { };
	do
		function order.new(priority)
			local stack = {
				sequence = { },
			};
			
			function stack.add(index, fn, ...)
				table.insert(stack.sequence, index or #stack.sequence + 1, { fn, {...} });
			end
			
			function stack.rm(index)
				table.remove(stack.sequence, index);
			end
			
			function stack.mov(index, newindex)
				local order = stack.sequence[index];
				table.remove(stack.sequence, index);
				
				table.insert(stack.sequence, newindex, order);
			end
			
			return stack;
		end
	end
	
	local function errorCall(message)
		print("seq catch: " .. message);
	end
	
	function queue.new(priority)
		local order = order.new(priority or 1);
		table.insert(tray, priority or 1, order);
		
		return order;
	end
	
	function queue.get(priority)
		return tray[priority];
	end
	
	function queue.rm(priority)
		table.remove(tray, priority);
	end
	
	function queue.mov(priority, newPriority)
		local order = tray[priority];
		table.remove(tray, priority);
		
		table.insert(tray, newPriority, order);
	end
	
	function queue.run()
    queue_disable = false;
		while not queue_disable do
			local stack = tray[1];
			if (stack) then
				if (#stack.sequence > 0) then
					local current = stack.sequence[1];
					table.remove(stack.sequence, 1);
					
					local fn, args = current[1], current[2];
					local function mainfn()
						fn(unpack(args));
					end
					
					xpcall(mainfn, errorCall);
				else
					table.remove(tray, 1);
				end
			else
				break;
			end
			
			wait(1 / 7e7);
		end
	end
	
	function queue.stop()
		queue_disable = true;
	end
end

return queue;
