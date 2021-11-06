---
-- @Liquipedia
-- wiki=commons
-- page=Module:Stream/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
Streaming specific subset of Module:Links
]]
local StreamExt = {}

--[[
List of streaming platforms supported in Module:Countdown
]]
StreamExt.countdownPlatformNames = {
	'afreeca',
	'afreecatv',
	'bilibili',
	'cc163',
	'dailymotion',
	'douyu',
	'facebook',
	'huomao',
	'huya',
	'loco',
	'mildom',
	'nimo',
	'pandatv',
	'play2live',
	'smashcast',
	'stream',
	'tl',
	'trovo',
	'twitch',
	'twitch2',
	'youtube',
}

--[[
Extracts the streaming platform args from an argument table for use in
Module:Countdown.
]]
function StreamExt.readCountdownStreams(args)
	local stream = {}
	for _, platformName in ipairs(StreamExt.platformNames) do
		stream[platformName] = args[platformName]
	end
	return stream
end

return StreamExt
