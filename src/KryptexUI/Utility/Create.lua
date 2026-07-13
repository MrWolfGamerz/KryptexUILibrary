local Create = {}

local function applyProperties(instance, properties)
	local children = properties.Children
	local events = properties.Events

	properties.Children = nil
	properties.Events = nil

	for property, value in pairs(properties) do
		instance[property] = value
	end

	if events then
		for eventName, callback in pairs(events) do
			instance[eventName]:Connect(callback)
		end
	end

	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end

	return instance
end

function Create.new(className, properties)
	return applyProperties(Instance.new(className), properties or {})
end

return Create

