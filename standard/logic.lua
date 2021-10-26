---
-- @Liquipedia
-- wiki=commons
-- page=Module:Logic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = {}

function Logic.emptyOr(val1, val2, default)
	if not Logic.isEmpty(val1) then
		return val1
	elseif not Logic.isEmpty(val2) then
		return val2
	else
		return default
	end
end

function Logic.nilOr(...)
	local args = require('Module:Table').pack(...)
	for i = 1, args.n do
		local arg = args[i]
		local val = type(arg) == 'function' and arg() or arg
		if val ~= nil then
			return val
		end
	end
	return nil
end

function Logic.isEmpty(val)
	if type(val) == 'table' then
		return require('Module:Table').isEmpty(val)
	else
		return val == '' or val == nil
	end
end

function Logic.isNotEmpty(val)
	if type(val) == 'table' then
		return require('Module:Table').isNotEmpty(val)
	else
		return val ~= nil and val ~= ''
	end
end

function Logic.readBool(val)
	return val == 'true' or val == true or val == '1' or val == 1
end

function Logic.readBoolOrNil(val)
	if val == 'true' or val == true or val == '1' or val == 1 then
		return true
	elseif val == 'false' or val == false or val == '0' or val == 0 then
		return false
	else
		return nil
	end
end

function Logic.nilThrows(val)
	if val == nil then
		error('Unexpected nil', 2)
	end
	return val
end

function Logic.tryCatch(try, catch)
	local ran, result = pcall(try)
	if not ran then
		catch(result)
	else
		return result
	end
end

function Logic.try(f)
	return require('Module:ResultOrError').try(f)
end

--[[
Returns the result of a function if successful. Otherwise it returns the result
of the second function.

If the first function fails, its error is logged to the console and stashed
away for display.

Parameters:

f() -> any
Parameterless function, and returns at most a single value. Additional return
values beyond the first are ignored.

other(error: Error) -> any
The thrown Error instance is its sole parameter. Additional return values
beyond the first are ignored.

makeError(error: Error) -> Error
optional function that allows customizing the Error instance being logged and stashed.

]]
function Logic.tryOrElseLog(f, other, makeError)
	return Logic.try(f)
		:catch(function(error)
			error.header = 'Error occured while calling a function: (caught by Logic.tryOrElseLog)'
			if makeError then
				error = makeError(error)
			end

			require('Module:Error/Util').logAndStash(error)

			if other then
				return other(error)
			end
		end)
		:get()
end

--[[
Returns the result of a function if successful. Otherwise it returns nil.

If the first function fails, its error is logged to the console and stashed
away for display.
]]
function Logic.tryOrLog(f, makeError)
	return Logic.tryOrElseLog(f, nil, makeError)
end

function Logic.isNumeric(val)
	return tonumber(val) ~= nil
end

return Logic
