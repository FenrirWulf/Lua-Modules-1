---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local ErrorUtil = {}

function ErrorUtil.logAndStash(error)
	require('Module:Error/Stash').add(error)
	ErrorUtil.log(error)
end

function ErrorUtil.log(error)
	mw.log(ErrorUtil.makeFullDetails(error))
	mw.log()
end

local function tableOrEmpty(tbl)
	return type(tbl) == 'table' and tbl or {}
end

function ErrorUtil.makeFullDetails(error)
	local parts = Array.extend(
		error.header,
		error.message,
		ErrorUtil.makeFullStackTrace(error),
		ErrorUtil.printExtraProps(error)
	)
	return table.concat(parts, '\n')
end

--[[
Builds a string for fields not covered by the other functions in this module.
Returns nil if there are no extra fields.
]]
function ErrorUtil.printExtraProps(error)
	local extraProps = Table.copy(error)
	extraProps.message = nil
	extraProps.header = nil
	extraProps.stacks = nil
	extraProps.originalErrors = nil
	if type(extraProps.childErrors) == 'table' then
		extraProps.childErrors = Array.map(extraProps.childErrors, ErrorUtil.makeFullDetails)
	end

	if Table.isNotEmpty(extraProps) then
		return 'Additional properties: \n' .. mw.dumpObject(extraProps)
	else
		return nil
	end
end

function ErrorUtil.makeFullStackTrace(error)
	local parts = Array.extend(
		error.stacks,
		Array.flatMap(tableOrEmpty(error.originalErrors), function(originalError)
			return {
				'',
				'Error was thrown while handling:',
				originalError.message,
				ErrorUtil.makeFullStackTrace(originalError),
			}
		end)
	)
	return table.concat(parts, '\n')
end

--[[
Variant of Array.map that wraps an error handler around each element
transformation. At the end, the successfully transformed elements are separated
from the errors, and both are returned.
]]
function ErrorUtil.mapTry(elems, f)
	local errors = {}
	local results = Array.map(elems, function(elem, index)
		return Logic.try(function() return f(elem, index) end)
			:catch(function(error)
				error.elem = elem
				error.index = index
				table.insert(errors, error)
			end)
			:get()
	end)
	return results, errors
end

return ErrorUtil
