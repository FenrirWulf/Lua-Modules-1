---
-- @Liquipedia
-- wiki=commons
-- page=Module:Date/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')

local DateExt = {}

-- 0000-01-01 00:00:00
DateExt.minInstant = -62167219200

-- 9999-12-31 23:59:59
DateExt.maxInstant = 253402300799

--[[
Parses a date string into an instant, returning the number of seconds since
UNIX epoch. The timezone offset is incorporated into the instant, and the
timezone is discarded.

Throws if the input string is non-empty and not a valid date.

Example:

DateExt.readInstant('2021-10-17 17:40 <abbr data-tz="-4:00">EDT</abbr>')
-- Returns 1634506800
]]
function DateExt.readInstant(dateString)
	if String.isEmpty(dateString) then
		return nil
	end

	-- Extracts the '-4:00' out of <abbr data-tz="-4:00" title="Eastern Daylight Time (UTC-4)">EDT</abbr>
	local timezoneOffset = dateString:match('data%-tz%=[\"\']([%d%-%+%:]+)[\"\']')
	local matchDate = (mw.text.split(dateString, '<', true)[1]):gsub('-', '')
	return mw.getContentLanguage():formatDate('U', matchDate .. (timezoneOffset or ''))
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
	local instant = type(dateOrInstant) == 'string'
		and DateExt.readInstant(dateOrInstant)
		or dateOrInstant
	return DateExt.formatInstant('F j, Y - H:i', instant) .. '<abbr data-tz="+0:00"></abbr>'
end

return DateExt
