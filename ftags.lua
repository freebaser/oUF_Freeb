local siValue = function(val)
	if(val >= 1e6) then
		return ('%.1f'):format(val / 1e6):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

local function hex(r, g, b)
	if(type(r) == 'table') then
		if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {.31,.45,.63},
		['RAGE'] = {.69,.31,.31},
		['FOCUS'] = {.71,.43,.27},
		['ENERGY'] = {.65,.63,.35},
		['RUNIC_POWER'] = {0,.8,.9},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

oUF.Tags["[freebLvl]"] = function(u) 
	local level = UnitLevel(u)
	local typ = UnitClassification(u)
	local color = GetQuestDifficultyColor(level)
	
	if level <= 0 then
		level = "??" 
		color.r, color.g, color.b = 1, 0, 0
	end
	
	if typ=="rareelite" then
		return hex(color)..level..'r+'
	elseif typ=="elite" then
		return hex(color)..level..'+'
	elseif typ=="rare" then
		return hex(color)..level..'r'
	else
		return hex(color)..level
	end
end

oUF.Tags['[freebHp]']  = function(u) 
	local min, max = UnitHealth(u), UnitHealthMax(u)
	local perc = (min/max)*100
	
	return siValue(min).." | "..oUF.Tags['[perhp]'](u).."%"
end
oUF.TagEvents['[freebHp]'] = 'UNIT_HEALTH'

oUF.Tags['[freebPp]'] = function(u)
	local _, str = UnitPowerType(u)
	return hex(colors.power[str])..siValue(UnitPower(u))
end
oUF.TagEvents['[freebPp]'] = 'UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE UNIT_RUNIC_POWER'

oUF.Tags["[freebName]"] = function(u, r)
	local name = string.upper(UnitName(r or u))
	local _, class = UnitClass(u)
	local t
	
	if (UnitIsTapped(u) and not UnitIsTappedByPlayer(u)) then
		t = hex(oUF.colors.tapped)..name
	elseif (UnitClass("player") == 'HUNTER') and (u == "pet") then
		t = hex(oUF.colors.happiness[GetPetHappiness()])..name
	elseif (UnitIsPlayer(u)) then
		t = hex(oUF.colors.class[class])..name
	else
		t = hex(oUF.colors.reaction[UnitReaction(u, "player")])..name
	end
	
	if t then
		if UnitIsDead(u) then
			return t.." "..oUF.Tags['[freebLvl]'](u).."|cffCFCFCF Dead|r"
		elseif UnitIsGhost(u) then
			return t.." "..oUF.Tags['[freebLvl]'](u).."|cffCFCFCF Ghost|r"
		elseif not UnitIsConnected(u) then
			return t.." "..oUF.Tags['[freebLvl]'](u).."|cffCFCFCF D/C|r"
		else
			return t.." "..oUF.Tags['[freebLvl]'](u)
		end
	end
end
oUF.TagEvents['[freebName]'] = 'UNIT_NAME_UPDATE UNIT_REACTION UNIT_HEALTH UNIT_HAPPINESS'