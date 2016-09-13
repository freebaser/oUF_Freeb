local ADDON_NAME, ns = ...

oUF.Tags.Methods["freeb:hp"] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then
		return
	end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	return ns.numberize(cur)
end
oUF.Tags.Events["freeb:hp"] = "UNIT_HEALTH UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"

oUF.Tags.Methods["freeb:pp"] = function(unit)
	if(UnitIsDeadOrGhost(unit)) then return end

	local ptype, ptoken = UnitPowerType(unit)
	local t = ns.colors.power[ptoken] or ns.colors.power[ptype]

	local cur, max = UnitPower(unit, ptype), UnitPowerMax(unit, ptype)
	if(cur ~= 0) then
		return Hex(t)..ns.numberize(cur)
	end
end
oUF.Tags.Events["freeb:pp"] = "UNIT_POWER UNIT_POWER_FREQUENT UNIT_MAXPOWER"

oUF.Tags.Methods["freeb:name"] = function(unit)
	local name = UnitName(unit)
	local r, g, b = ns.unitColor(unit)
	if(name) then
		return Hex(r, g, b)..name
	end
end
oUF.Tags.Events["freeb:name"] = "UNIT_NAME UNIT_REACTION"

local cpChar = "+"
oUF.Tags.Methods["freeb:cp"] = function(unit)
	local cp, max = UnitPower(unit, SPELL_POWER_COMBO_POINTS), UnitPowerMax(unit, SPELL_POWER_COMBO_POINTS)
	if(cp > 0) then
		local str = ""
		for i=1, cp do
			if(i == max) then
				str = ("%s|cffFF0000 %d|r"):format(str, i)
			elseif(i == (max-1)) then
				str = ("%s|cffFF8800 %d|r"):format(str, i)
			else
				str = ("%s|cffFFFF00 %d|r"):format(str, i)
			end
		end
		return str
	end
end
oUF.Tags.Events["freeb:cp"] = "UNIT_POWER UNIT_POWER_FREQUENT UNIT_MAXPOWER"
