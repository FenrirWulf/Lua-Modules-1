---
-- @Liquipedia
-- wiki=commons
-- page=Module:Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Flags = require('Module:Flags')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')

--[[
Structural type representation of an opponent.

Examples:
{type = 'solo', players = {displayName = 'Neeb'}}
{type = 'team', template = 'alpha x 2020'}
{type = 'literal', name = 'B2'}

See Opponent.isOpponent for the exact encoding scheme and required fields.

- For opponent display components, see Module:OpponentDisplay.
- For input from wikicode, use {{1Opponent|...}}, {{TeamOpponent|...}} etc.
- Used by: PrizePool, GroupTableLeague, match2 Matchlist/Bracket,
StarcraftMatchSummary
- Wikis may add additional wiki-specific fields to the opponent representation.

]]
local Opponent = {}

Opponent.partyTypes = {'solo', 'duo', 'trio', 'quad'}
Opponent.types = Array.extend(Opponent.partyTypes, {'team', 'literal'})

Opponent.partySizes = {
	solo = 1,
	duo = 2,
	trio = 3,
	quad = 4,
}

function Opponent.typeIsParty(type)
	return Opponent.partySizes[type] ~= nil
end

--[[
Returns the player count for a party type, or nil otherwise.

Opponent.partySize('duo') == 2
]]
function Opponent.partySize(type)
	return Opponent.partySizes[type]
end

--[[
Creates a blank opponent of the specified type
]]
function Opponent.blank(type)
	if type == 'team' then
		return {type = type, template = 'tbd'}
	elseif type == 'literal' then
		return {type = type, name = ''}
	else
		assert(Opponent.typeIsParty(type))
		return {
			type = type,
			players = Array.map(
				Array.range(1, Opponent.partySize(type)),
				function(_) return {displayName = ''} end
			),
		}
	end
end

--[[
Creates a TBD opponent of the specified type
]]
function Opponent.tbd(type)
	if type == 'team' then
		return {type = type, template = 'tbd'}
	elseif type == 'literal' then
		return {type = type, name = 'TBD'}
	else
		assert(Opponent.typeIsParty(type))
		return {
			type = type,
			players = Array.map(
				Array.range(1, Opponent.partySize(type)),
				function(_) return {displayName = 'TBD'} end
			),
		}
	end
end

--[[
Whether an opponent is TBD
]]
function Opponent.isTbd(opponent)
	if opponent.type == 'team' then
		return opponent.template == 'tbd'

			-- The following can't occur in valid opponents, but we check for them anyway
			or opponent.name == 'TBD'
			or String.isEmpty(opponent.template)

	elseif opponent.type == 'literal' then
		return true

	else
		return Array.any(opponent.players, Opponent.playerIsTbd)
	end
end

function Opponent.playerIsTbd(player)
	return player.displayName == '' or player.displayName == 'TBD'
end

--[[
Whether an arbitary value is a valid representation of an opponent
]]
function Opponent.isOpponent(opponent)
	if not (type(opponent) == 'table' and type(opponent.type) == 'string') then
		return false
	end

	if opponent.type == 'team' then
		return type(opponent.template) == 'string'
			and opponent.template ~= ''

	elseif opponent.type == 'literal' then
		return type(opponent.name) == 'string'

	elseif Opponent.typeIsParty(opponent.type) then
		return type(opponent.players) == 'table'
			and #opponent.players == Opponent.partySize(opponent.type)
			and Array.all(opponent.players, Opponent.isPlayer)

	else
		return false
	end
end

function Opponent.isPlayer(player)
	return type(player) == 'table'
		and type(player.displayName) == 'string'
		and (type(player.pageName) == 'string' or player.pageName == nil)
		and (type(player.flag) == 'string' or player.flag == nil)
end

function Opponent.isType(type)
	return Table.includes(Opponent.types, type)
end

function Opponent.readType(type)
	return Table.includes(Opponent.types, type) and type or nil
end

--[[
Asserts that an arbitary value is a valid representation of an opponent
]]
function Opponent.assertOpponent(opponent)
	assert(Opponent.isOpponent(opponent), 'Invalid opponent')
end

--[[
Coerces an arbitary table into an opponent
]]
function Opponent.coerce(opponent)
	assert(type(opponent) == 'table')

	opponent.type = Opponent.isType(opponent.type) and opponent.type or 'literal'
	if opponent.type == 'literal' then
		opponent.name = type(opponent.name) == 'string' and opponent.name or ''
	elseif opponent.type == 'team' then
		if String.isEmpty(opponent.template) or type(opponent.template) ~= 'string' then
			opponent.template = 'tbd'
		end
	else
		if type(opponent.players) ~= 'table' then
			opponent.players = {}
		end
		local partySize = Opponent.partySize(opponent.type)
		opponent.players = Array.sub(opponent.players, 1, partySize)
		for _, player in ipairs(opponent.players) do
			if type(player.displayName) ~= 'string' then
				player.displayName = ''
			end
		end
		for i = #opponent.players + 1, partySize do
			opponent.players[i] = {displayName = ''}
		end
	end
end

--[[
Returns the match mode for two or more opponent types.

Example:

Opponent.toMode('duo', 'duo') == '2_2'
]]
function Opponent.toMode(...)
	local modeParts = Array.map(arg, function(opponentType)
		return Opponent.partySize(opponentType) or opponentType
	end)
	return table.concat(modeParts, '_')
end

--[[
Returns the legacy match mode for two or more opponent types.

Used by LPDB placement and tournament records, and smw records.

Example:

Opponent.toLegacyMode('duo', 'duo') == '2v2'
]]
function Opponent.toLegacyMode(...)
	local modeParts = Array.map(arg, function(opponentType)
		return Opponent.partySize(opponentType) or opponentType
	end)
	local mode = table.concat(modeParts, 'v')
	if mode == 'teamvteam' then
		return 'team'
	else
		return mode
	end
end

--[[
Converts a opponent to a name. The name is the same as the one used in the
match2opponent.name field.
]]
function Opponent.toName(opponent)
	if opponent.type == 'team' then
		return TeamTemplate.getPageName(opponent.template)
	elseif opponent.type == 'literal' then
		return opponent.name
	elseif Opponent.typeIsParty(opponent.type) then
		local pageNames = Array.map(opponent.players, function(player) return player.pageName end)
		return table.concat(pageNames, ' / ')
	end
end

--[[
Creates an opponent struct from a match2opponent record. Wiki specific fields
are not included.
]]
function Opponent.fromMatch2Record(record)
	if record.type == 'team' then
		return {type = 'team', template = record.template}
	elseif record.type == 'literal' then
		return {type = 'literal', template = record.name}
	elseif Opponent.typeIsParty(record.type) then
		return {
			type = record.type,
			players = Array.map(record.match2players, function(playerRecord)
				return {
					displayName = playerRecord.displayname,
					flag = String.nilIfEmpty(Flags.CountryName(playerRecord.flag)),
					pageName = playerRecord.name,
				}
			end),
		}
	else
		return nil
	end
end

return Opponent
