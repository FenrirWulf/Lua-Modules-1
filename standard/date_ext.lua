---
-- @Liquipedia
-- wiki=commons
-- page=Module:Date/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')

--[[
Functions for working with dates strings and instants.

An instant is a datetime represented as a number of seconds since UNIX epoch.
]]
local DateExt = {}

-- 0000-01-01 00:00:00
DateExt.minInstant = -62167219200

-- 9999-12-31 23:59:59
DateExt.maxInstant = 253402300799

--[[
Parses a date string into an instant, returning the number of seconds since
UNIX epoch. The timezone offset is incorporated into the instant, and the
timezone is discarded. If the timezone is not specified, then the date is
assumed to be in UTC.

Throws if the input string is non-empty and not a valid date.

Example:

DateExt.readInstant('2021-10-17 17:40 <abbr data-tz="-4:00">EDT</abbr>')
-- Returns 1634506800

DateExt.readInstant('2021-10-17 21:40')
-- Returns 1634506800
]]
function DateExt.readInstant(dateString)
	if String.isEmpty(dateString) then
		return nil
	elseif type(dateString) == 'number' then
		return dateString
	end

	-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
	local tzTemplateOffset = dateString:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
	local datePart = (mw.text.split(dateString, '<', true)[1]):gsub('-', '')
	local instantString = mw.getContentLanguage():formatDate('U', datePart .. (tzTemplateOffset or ''))
	return tonumber(instantString)
end

--[[
Same as DateExt.readInstant, except that it returns nil upon failure.
]]
function DateExt.readInstantOrNil(dateString)
	local success, instant = pcall(DateExt.readInstant, dateString)
	return success and instant or nil
end

--[[
Formats an instant according to the specified format. The format string is the
same used by mw.language.formatDate and {{#time}}.

Example:
DateExt.formatInstant('c', 1634506800)
-- Returns 2021-10-17T21:40:00+00:00

Date format reference:
https://www.mediawiki.org/wiki/Help:Extension:ParserFunctions#.23time
https://www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual#mw.language:formatDate
]]
function DateExt.formatInstant(format, instant)
	return mw.getContentLanguage():formatDate(format, '@' .. instant)
end

--[[
Converts a date string or instant into a format that can be used in the date
param to Module:Cooldown.
]]
function DateExt.toCooldownArg(dateOrInstant)
	local instant = DateExt.readInstant(dateOrInstant)
	return DateExt.formatInstant('F j, Y - H:i', instant) .. '<abbr data-tz="+0:00"></abbr>'
end

--[[
Truncates the time of day in a date string or instant, and returns the date
formatted as yyyy-mm-dd. The time of day is truncated in the UTC timezone. The
time of day and timezone are discarded.

Examples:
DateExt.toYmdInUtc('November 08, 2021 - 13:00 <abbr data-tz="+2:00">CET</abbr>')
-- Returns 2021-11-08

DateExt.toYmdInUtc('2021-11-08 17:00 <abbr data-tz="-8:00">PST</abbr>')
-- Returns 2021-11-09

]]
function DateExt.toYmdInUtc(dateOrInstant)
	return DateExt.formatInstant('Y-m-d', DateExt.readInstant(dateOrInstant))
end

return DateExt
