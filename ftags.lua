local CC = select(4, GetBuildInfo()) == 4e4
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

oUF.colors.power['MANA'] = {.31,.45,.63}
oUF.colors.power['RAGE'] = {.69,.31,.31}

oUF.Tags['freeb:lvl'] = function(u) 
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

oUF.Tags['freeb:hp']  = function(u) 
			   local min, max = UnitHealth(u), UnitHealthMax(u)
			   return siValue(min).." | "..math.floor(min/max*100+.5).."%"
			end
oUF.TagEvents['freeb:hp'] = 'UNIT_HEALTH'

oUF.Tags['freeb:pp'] = function(u)
			  local _, str = UnitPowerType(u)
			  if str then
			     return hex(oUF.colors.power[str])..siValue(UnitPower(u))
			  end
		       end
if CC then
   oUF.TagEvents['freeb:pp'] = 'UNIT_POWER'
else
   oUF.TagEvents['freeb:pp'] = 'UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE UNIT_RUNIC_POWER'
end

oUF.Tags['freeb:color'] = function(u, r)
			     local _, class = UnitClass(u)
			     local reaction = UnitReaction(u, "player")
			     
			     if (UnitIsTapped(u) and not UnitIsTappedByPlayer(u)) then
				return hex(oUF.colors.tapped)
			     elseif (u == "pet") and GetPetHappiness() then
				return hex(oUF.colors.happiness[GetPetHappiness()])
			     elseif (UnitIsPlayer(u)) then
				return hex(oUF.colors.class[class])
			     elseif reaction then
				return hex(oUF.colors.reaction[reaction])
			     else
				return hex(1, 1, 1)
			     end
			  end
oUF.TagEvents['freeb:color'] = 'UNIT_REACTION UNIT_HEALTH UNIT_HAPPINESS'

oUF.Tags['freeb:name'] = function(u, r)
			    local name = string.upper(UnitName(r or u))
			    return name
			 end
oUF.TagEvents['freeb:name'] = 'UNIT_NAME_UPDATE'

oUF.Tags['freeb:info'] = function(u)
			    if UnitIsDead(u) then
			       return oUF.Tags['freeb:lvl'](u).."|cffCFCFCF Dead|r"
			    elseif UnitIsGhost(u) then
			       return oUF.Tags['freeb:lvl'](u).."|cffCFCFCF Ghost|r"
			    elseif not UnitIsConnected(u) then
			       return oUF.Tags['freeb:lvl'](u).."|cffCFCFCF D/C|r"
			    else
			       return oUF.Tags['freeb:lvl'](u)
			    end
			 end
oUF.TagEvents['freeb:info'] = 'UNIT_HEALTH'

oUF.Tags['freebraid:info'] = function(u)
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
oUF.TagEvents['freebraid:info'] = 'UNIT_HEALTH'
