local floor = math.floor

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
    if not r then return "|cffFFFFFF" end

    if(type(r) == 'table') then
        if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
    end
    return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

oUF.colors.power['MANA'] = {.31,.45,.63}
oUF.colors.power['RAGE'] = {.69,.31,.31}

oUF.Tags.Methods['freeb:lvl'] = function(u) 
    local level = UnitLevel(u)
    local typ = UnitClassification(u)
    local color = GetQuestDifficultyColor(level)

    if level <= 0 then
        level = "??" 
        color.r, color.g, color.b = 1, 0, 0
    end

    if typ=="rareelite" then
        return hex(color)..level..'r+|r'
    elseif typ=="elite" then
        return hex(color)..level..'+|r'
    elseif typ=="rare" then
        return hex(color)..level..'r|r'
    else
        return hex(color)..level..'|r'
    end
end

oUF.Tags.Methods['freeb:hp']  = function(u) 
    local min, max = UnitHealth(u), UnitHealthMax(u)
    return siValue(min).." | "..floor(min/max*100+.5).."%"
end
oUF.Tags.Events['freeb:hp'] = 'UNIT_HEALTH'

oUF.Tags.Methods['freeb:pp'] = function(u) 
    local power, powermax = UnitPower(u), UnitPowerMax(u)

    if power > 0 then
        local _, str, r, g, b = UnitPowerType(u)
        local t = oUF.colors.power[str]

        if t then
            r, g, b = t[1], t[2], t[3]
        end

        local perc = floor((power/powermax)*100+.5)
        perc = powermax > 150 and " | "..perc.."%|r" or ""
        
        return hex(r, g, b)..siValue(power)..perc.."|r"
    end
end
oUF.Tags.Events['freeb:pp'] = 'UNIT_POWER'

oUF.Tags.Methods['freeb:color'] = function(u, r)
    local reaction = UnitReaction(u, "player")

    if (UnitIsTapped(u) and not UnitIsTappedByPlayer(u)) then
        return hex(oUF.colors.tapped)
    elseif (UnitIsPlayer(u)) then
        local _, class = UnitClass(u)
        return hex(oUF.colors.class[class])
    elseif reaction then
        return hex(oUF.colors.reaction[reaction])
    else
        return hex(1, 1, 1)
    end
end
oUF.Tags.Events['freeb:color'] = 'UNIT_REACTION UNIT_HEALTH'

oUF.Tags.Methods['freeb:name'] = function(u, r)
    local name = UnitName(r or u)
    return name
end
oUF.Tags.Events['freeb:name'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['freeb:info'] = function(u)
    if UnitIsDead(u) then
        return oUF.Tags.Methods['freeb:lvl'](u).."|cffCFCFCF RIP|r"
    elseif UnitIsGhost(u) then
        return oUF.Tags.Methods['freeb:lvl'](u).."|cffCFCFCF Gho|r"
    elseif not UnitIsConnected(u) then
        return oUF.Tags.Methods['freeb:lvl'](u).."|cffCFCFCF D/C|r"
    else
        return oUF.Tags.Methods['freeb:lvl'](u)
    end
end
oUF.Tags.Events['freeb:info'] = 'UNIT_HEALTH'

oUF.Tags.Methods['freebraid:info'] = function(u)
    local _, class = UnitClass(u)

    if class then
        if UnitIsDead(u) then
            return hex(oUF.colors.class[class]).."RIP|r"
        elseif UnitIsGhost(u) then
            return hex(oUF.colors.class[class]).."Gho|r"
        elseif not UnitIsConnected(u) then
            return hex(oUF.colors.class[class]).."D/C|r"
        end
    end
end
oUF.Tags.Events['freebraid:info'] = 'UNIT_HEALTH UNIT_CONNECTION'

oUF.Tags.Methods['freeb:curxp'] = function(unit)
    return siValue(UnitXP(unit))
end

oUF.Tags.Methods['freeb:maxxp'] = function(unit)
    return siValue(UnitXPMax(unit))
end

oUF.Tags.Methods['freeb:perxp'] = function(unit)
    return floor(UnitXP(unit) / UnitXPMax(unit) * 100 + 0.5)
end

oUF.Tags.Events['freeb:curxp'] = 'PLAYER_XP_UPDATE PLAYER_LEVEL_UP'
oUF.Tags.Events['freeb:maxxp'] = 'PLAYER_XP_UPDATE PLAYER_LEVEL_UP'
oUF.Tags.Events['freeb:perxp'] = 'PLAYER_XP_UPDATE PLAYER_LEVEL_UP'

oUF.Tags.Methods['freeb:altpower'] = function(u)
    local cur = UnitPower(u, ALTERNATE_POWER_INDEX)
    local max = UnitPowerMax(u, ALTERNATE_POWER_INDEX)

    if max > 0 then
        local per = floor(cur/max*100)

        return format("%d", per > 0 and per or 0).."%"
    end
end
oUF.Tags.Events['freeb:altpower'] = "UNIT_POWER UNIT_MAXPOWER"
