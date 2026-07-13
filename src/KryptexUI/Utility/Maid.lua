local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid:Give(taskObject)
	table.insert(self._tasks, taskObject)
	return taskObject
end

function Maid:Clean()
	for index = #self._tasks, 1, -1 do
		local taskObject = self._tasks[index]
		self._tasks[index] = nil

		if typeof(taskObject) == "RBXScriptConnection" then
			taskObject:Disconnect()
		elseif typeof(taskObject) == "Instance" then
			taskObject:Destroy()
		elseif type(taskObject) == "function" then
			taskObject()
		elseif type(taskObject) == "table" then
			if type(taskObject.Destroy) == "function" then
				taskObject:Destroy()
			elseif type(taskObject.Clean) == "function" then
				taskObject:Clean()
			end
		end
	end
end

Maid.Destroy = Maid.Clean

return Maid

