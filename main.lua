local ADDON_NAME, ns = ...

local SCALE = 1.1
local WIDTH = 210
local HEIGHT = 32
local hpHeight = HEIGHT*.88
local ppHeight = HEIGHT*.1
local FADEALPHA = .25

-------------------------------------------------------------------------------
--[[ Update Funcs ]]--

local fadeOut = function(self)
	local unit = self.unit
	if(unit == "pet") then unit = "player" end

	local inCombat = UnitAffectingCombat(unit)
	if(inCombat or UnitExists(unit.."target")
		or not self.isMax or self.isCasting) then
		self:SetAlpha(1)
	else
		self:SetAlpha(FADEALPHA)
	end
end

local fadeMe = function(self)
	self:RegisterEvent("UNIT_TARGET", fadeOut)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", fadeOut)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", fadeOut)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", fadeOut)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", fadeOut)
	table.insert(self.__elements, fadeOut)

	self.fadeOut = true
end

local PostHealthUpdate = function(hp, unit, min, max)
	local self = hp.__owner
	if(self.fadeOut) then
		self.isMax = min == max
		fadeOut(self)
	end
end

local PostPowerUpdate = function(pp, unit, min, max)
	local self = pp.__owner

	if(min == 0 or UnitIsDeadOrGhost(unit)) then
		self.Health:SetHeight(HEIGHT)
		pp:SetHeight(0.01)
	else
		self.Health:SetHeight(hpHeight)
		pp:SetHeight(ppHeight)
	end
end

local updateThreat = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local status = UnitThreatSituation(unit)
	if(status and status > 1) then
		local r, g, b = GetThreatStatusColor(status)
		self.Border:SetColor(r, g, b, 1)
	else
		self.Border:SetColor(0, 0, 0, 0)
	end
end

local threatMe = function(self)
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", updateThreat)
	table.insert(self.__elements, updateThreat)
end
-------------------------------------------------------------------------------
--[[ Shared ]]--

local Shared = function(self, unit)
	self:RegisterForClicks"AnyUp"
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self.colors = ns.colors

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetStatusBarTexture(ns.statusbar)
	hp:SetStatusBarColor(.11, .11, .11)
	hp:SetHeight(hpHeight)
	hp.frequentUpdates = true
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"
	hp.PostUpdate = PostHealthUpdate

	self.Health = hp

	local hpbg = hp:CreateTexture(nil, 'BORDER')
	hpbg:SetColorTexture(.35, .1, .1)
	hpbg:SetAllPoints(hp)

	local overlay = CreateFrame("Frame", nil, self.Health)
	overlay:SetAllPoints(self.Health)

	local hpText = overlay:CreateFontString(nil, "OVERLAY")
	hpText:SetPoint("BOTTOMRIGHT", -2, 1)
	hpText:SetJustifyH"RIGHT"
	hpText:SetFontObject(ns.FreebFontSmall)
	self:Tag(hpText, "[dead][offline][freeb:hp]")

	local perhpText = overlay:CreateFontString(nil, "OVERLAY")
	perhpText:SetPoint("TOPRIGHT", -2, -2)
	perhpText:SetJustifyH"RIGHT"
	perhpText:SetFontObject(ns.FreebFont)
	self:Tag(perhpText, "[>perhp<%]")

	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetStatusBarTexture(ns.statusbar)
	pp:SetStatusBarColor(1, 1, 1)
	pp:SetHeight(ppHeight)
	pp.frequentUpdates = true
	pp.colorPower = true
	pp.displayAltPower = true
	pp:SetPoint"LEFT"
	pp:SetPoint"RIGHT"
	pp:SetPoint"BOTTOM"
	pp.PostUpdate = PostPowerUpdate

	self.Power = pp

	local ppText = overlay:CreateFontString(nil, "OVERLAY")
	ppText:SetPoint("BOTTOM", hp, 0, 1)
	ppText:SetJustifyH"LEFT"
	ppText:SetFontObject(ns.FreebFontSmall)
	self:Tag(ppText, "[freeb:pp]")

	local nameText = overlay:CreateFontString(nil, "OVERLAY")
	nameText:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 2, -2)
	nameText:SetPoint("TOPRIGHT", perhpText, "BOTTOMLEFT")
	nameText:SetHeight(self.Health:GetHeight()/2)
	nameText:SetJustifyH"LEFT"
	nameText:SetFontObject(ns.FreebFont)
	nameText:SetTextColor(1, 1, 1)
	self:Tag(nameText, "[freeb:name]")

	local lvlText = overlay:CreateFontString(nil, "OVERLAY")
	lvlText:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMLEFT", 2, 1)
	lvlText:SetJustifyH"LEFT"
	lvlText:SetFontObject(ns.FreebFontSmall)
	lvlText:SetTextColor(1, 1, 1)
	self:Tag(lvlText, "[level][plus] [|cffCC00FF>rare<|r][resting]")

	local leader = hp:CreateTexture(nil, "OVERLAY")
	leader:SetSize(14, 14)
	leader:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", 2, -4)

	self.Leader = leader

	local masterlooter = hp:CreateTexture(nil, 'OVERLAY')
	masterlooter:SetSize(14, 14)
	masterlooter:SetPoint('LEFT', leader, 'RIGHT')

	self.MasterLooter = masterlooter

	local PvP = hp:CreateTexture(nil, "OVERLAY")
	PvP:SetSize(18, 18)
	PvP:SetPoint("TOPRIGHT", self, 8, 8)

	self.PvP = PvP

	local QuestIcon = hp:CreateTexture(nil, "OVERLAY")
	QuestIcon:SetSize(16, 16)
	QuestIcon:SetAllPoints(PvP)

	self.QuestIcon = QuestIcon

	local Combat = hp:CreateTexture(nil, "OVERLAY")
	Combat:SetSize(18, 18)
	Combat:SetPoint("BOTTOMLEFT", self, -8, -8)

	self.Combat = Combat

	local PhaseIcon = hp:CreateTexture(nil, "OVERLAY")
	PhaseIcon:SetSize(20, 20)
	PhaseIcon:SetPoint("TOP", hp)

	self.PhaseIcon = PhaseIcon

	local ricon = hp:CreateTexture(nil, "OVERLAY")
	ricon:SetPoint("BOTTOM", hp, "TOP", 0, -6)
	ricon:SetSize(14, 14)

	self.RaidIcon = ricon

	self:SetSize(WIDTH, HEIGHT)
	self:SetScale(SCALE)

	ns.sbSmooth(self.Health)
	ns.sbSmooth(self.Power)
	ns.createBackdrop(self)
	ns.createBorder(self, ns.mediapath.."glow")
end

-------------------------------------------------------------------------------
--[[ Shared Small ]]--

local SharedSmall = function(self, unit)
	self:RegisterForClicks"AnyUp"
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self.colors = ns.colors

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetStatusBarTexture(ns.statusbar)
	hp:SetStatusBarColor(.11, .11, .11)
	hp:SetHeight(22)
	hp.frequentUpdates = true
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"
	hp.PostUpdate = PostHealthUpdate

	self.Health = hp

	local hpbg = hp:CreateTexture(nil, 'BORDER')
	hpbg:SetColorTexture(.35, .1, .1)
	hpbg:SetAllPoints(hp)

	local nameText = hp:CreateFontString(nil, "OVERLAY")
	nameText:SetPoint"TOPLEFT"
	nameText:SetPoint"BOTTOMRIGHT"
	nameText:SetJustifyH"CENTER"
	nameText:SetFontObject(ns.FreebFont)
	self:Tag(nameText, "[freeb:name]")

	self:SetSize(WIDTH/2, self.Health:GetHeight())
	self:SetScale(SCALE)

	ns.sbSmooth(self.Health)
	ns.createBackdrop(self)
end

-------------------------------------------------------------------------------
--[[ Castbar ]]--

local PostCastStart = function(cb, unit)
	if(cb.interrupt) then
		cb.Icon:SetDesaturated(true)
		cb:SetStatusBarColor(.66, .66, .66, .8)
	else
		cb.Icon:SetDesaturated(false)
		cb:SetStatusBarColor(1, 1, 0, .8)
	end

	local self = cb.__owner
	self.Failed:Hide()
	self.isCasting = cb.casting or cb.channeling
	fadeOut(self)
end

local PostCastStop = function(cb, unit)
	local self = cb.__owner
	self.isCasting = cb.casting or cb.channeling
	fadeOut(self)
end

local PostCastFailed = function(cb, unit)
	local self = cb.__owner
	self.Failed.fade = 2
	self.Failed:SetAlpha(1)
	self.Failed.Text:SetFormattedText("|cffFF0000%s|r", FAILED)
	self.Failed:Show()
end

local PostCastInterrupted = function(cb, unit)
	local self = cb.__owner
	self.Failed.fade = 2
	self.Failed:SetAlpha(1)
	self.Failed.Text:SetFormattedText("|cffFF0000%s|r", INTERRUPTED)
	self.Failed:Show()
end

local CustomTimeText = function(cb, duration)
	if(cb.casting) then
		duration = cb.max - duration
	end

	if(cb.delay ~= 0) then
		local delay = math.abs(cb.delay)
		cb.Time:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, delay)
	else
		cb.Time:SetFormattedText("%.1f", duration)
	end
end

local Castbar = function(self, unit)
	local cb = CreateFrame("StatusBar", nil, self)
	cb:SetStatusBarTexture(ns.statusbar)
	cb:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
	cb:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT")
	cb:SetHeight(20)
	cb:SetToplevel(true)

	cb.Time = cb:CreateFontString(nil, "OVERLAY")
	cb.Time:SetPoint("BOTTOMRIGHT", cb, 0, -2)
	cb.Time:SetPoint("TOPRIGHT", cb)
	cb.Time:SetJustifyH"RIGHT"
	cb.Time:SetFontObject(ns.FreebFont)

	cb.Text = cb:CreateFontString(nil, "OVERLAY")
	cb.Text:SetPoint("BOTTOMLEFT", cb, 0, -2)
	cb.Text:SetPoint("TOPLEFT", cb)
	cb.Text:SetPoint("RIGHT", cb.Time, "LEFT")
	cb.Text:SetJustifyH"LEFT"
	cb.Text:SetFontObject(ns.FreebFont)

	cb.Icon = cb:CreateTexture(nil, "OVERLAY")
	cb.Icon:SetSize(28, 28)
	cb.Icon:SetTexCoord(.08, .92, .08, .92)
	cb.Icon:SetPoint("TOPRIGHT", cb, "TOPLEFT", -4, 0)

	if(unit == "player") then
		cb.SafeZone = cb:CreateTexture(nil,'ARTWORK')
		cb.SafeZone:SetPoint('TOPRIGHT')
		cb.SafeZone:SetPoint('BOTTOMRIGHT')
		cb.SafeZone:SetTexture(ns.statusbar)
		cb.SafeZone:SetVertexColor(0, 1, .6, .5)
	end

	self.Failed = CreateFrame("Frame", nil, self)
	self.Failed:Hide()
	self.Failed:SetScript("OnUpdate", function(self, elapsed)
		self.fade = self.fade - elapsed
		if(self.fade <= 1 and self.fade >= 0) then
			self:SetAlpha(self.fade)
		elseif(self.fade < 0) then
			self:Hide()
		end
	end)

	self:HookScript("OnHide", function(self)
		self.Failed:Hide()
	end)

	self.Failed.Text = self.Failed:CreateFontString(nil, "OVERLAY")
	self.Failed.Text:SetPoint("BOTTOM", self, "TOP", 0, 1)
	self.Failed.Text:SetFontObject(ns.FreebFont)

	cb.PostCastStart = PostCastStart
	cb.PostChannelStart = PostCastStart
	cb.PostCastStop = PostCastStop
	cb.PostChannelStop = PostCastStop
	cb.PostCastFailed = PostCastFailed
	cb.PostCastInterrupted = PostCastInterrupted

	cb.CustomTimeText = CustomTimeText
	cb.CustomDelayText = CustomTimeText

	self.Castbar = cb

	ns.createBackdrop(cb)
	ns.createBackdrop(cb, cb.Icon)
end

-------------------------------------------------------------------------------
--[[ Auras ]]--

local bFilter = {
	[212283] = true, -- Symbols of Death
}

local buffFilter = function(icons, unit, icon, ...)
	local spellid = select(11, ...)

	if(icon.isPlayer and bFilter[spellid]) then
		return true
	end
end

local PostUpdateGapIcon = function(icons, unit, icon, visibleBuffs)
	icon.Border:SetColor(0, 0, 0, 0)
	icon.duration = nil
	icon.remaining:SetText(nil)
end

local PostUpdateIcon = function(icons, unit, icon, index, offset)
	local _, _, _, _, _, _, expirationTime = UnitAura(unit, index, icon.filter)

	local texture = icon.icon
	if(icon.isPlayer or not icon.isDebuff) then
		texture:SetDesaturated(false)
	else
		texture:SetDesaturated(true)
	end

	local duration = expirationTime - GetTime()
	if(duration > 0) then
		icon.duration = duration
		icon.remaining:SetText(ns.formatTime(duration))
	else
		icon.duration = nil
		icon.remaining:SetText(nil)
	end
end

local auraTimer = function(self, elapsed)
	if(not self.duration or (self.duration < .5)) then return end
	self.duration = self.duration - elapsed
	self.remaining:SetText(ns.formatTime(self.duration))
end

local overlayProxy = function(overlay, ...)
	overlay:GetParent().Border:SetColor(...)
end

local overlayHide = function(overlay)
	overlay:GetParent().Border:SetColor(0, 0, 0, 1)
end

local PostCreateIcon = function(icons, button)
	icons.disableCooldown = true
	icons.showDebuffType = true

	local count = button.count
	count:ClearAllPoints()
	count:SetFontObject(ns.FreebFontSmall)
	count:SetTextColor(1, 1, 0)
	count:SetPoint"BOTTOMRIGHT"

	button.icon:SetTexCoord(.08, .92, .08, .92)

	local overlay = button.overlay
	overlay.SetVertexColor = overlayProxy
	overlay:Hide()
	overlay.Show = overlay.Hide
	overlay.Hide = overlayHide

	ns.createBorder(button, ns.mediapath.."glow")
	button.Border:SetColor(0, 0, 0, 1)

	button.remaining = button:CreateFontString(nil, "OVERLAY")
	button.remaining:SetFontObject(ns.FreebFontSmall)
	button.remaining:SetPoint("TOP")

	button:SetScript("OnUpdate", auraTimer)
end

local createAuras = function(self, size, num)
	local auras = CreateFrame("Frame", nil, self)

	auras:SetSize(num * (size + 4), size)
	auras.num = num
	auras.numBuffs = num
	auras.numDebuffs = num
	auras.size = size
	auras.spacing = 4

	auras.PostCreateIcon = PostCreateIcon
	auras.PostUpdateIcon = PostUpdateIcon
	auras.PostUpdateGapIcon = PostUpdateGapIcon

	return auras
end

-------------------------------------------------------------------------------
--[[ UnitSpecific ]]--

local UnitSpecific = {

	player = function(self, ...)
		Shared(self, ...)
		Castbar(self, ...)
		fadeMe(self)
		threatMe(self)

		local buffs = createAuras(self, 20, 3)
		buffs:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -4, 0)
		buffs.initialAnchor = "BOTTOMRIGHT"
		buffs["growth-x"] = "LEFT"
		buffs['growth-y'] = "DOWN"
		buffs.CustomFilter = buffFilter

		self.Buffs = buffs

		local cpText = self:CreateFontString(nil, "OVERLAY")
		cpText:SetPoint("BOTTOM", self, "TOP", 0, 4)
		cpText:SetFontObject(ns.FreebFont)
		self:Tag(cpText, "[freeb:cp]")
	end,

	pet = function(self, ...)
		SharedSmall(self, ...)
		fadeMe(self)
	end,

	target = function(self, ...)
		Shared(self, ...)
		Castbar(self, ...)

		local debuffs = createAuras(self, 22, 16)
		debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
		debuffs.initialAnchor = "BOTTOMLEFT"
		debuffs["growth-x"] = "RIGHT"
		debuffs['growth-y'] = "DOWN"

		self.Debuffs = debuffs

		local buffs = createAuras(self, 20, 3)
		buffs:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -4, 0)
		buffs.initialAnchor = "BOTTOMRIGHT"
		buffs["growth-x"] = "LEFT"
		buffs['growth-y'] = "DOWN"
		buffs.showStealableBuffs = true

		self.Buffs = buffs
	end,

	targettarget = function(self, ...)
		SharedSmall(self, ...)
	end,

	focus = function(self, ...)
		Shared(self, ...)
		Castbar(self, ...)
	end,

}

-------------------------------------------------------------------------------
--[[ oUF ]]--

oUF:RegisterStyle("Freeb", Shared)
for unit, layout in next, UnitSpecific do
	oUF:RegisterStyle("Freeb - " .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle("Freeb - " .. unit:gsub("^%l", string.upper))
	elseif(UnitSpecific[unit:match('%D+')]) then
		self:SetActiveStyle("Freeb - " .. unit:match('%D+'):gsub("^%l", string.upper))
	else
		self:SetActiveStyle"Freeb"
	end

	local object = self:Spawn(unit)
	object:SetPoint(...)
	return object
end

oUF:Factory(function(self)
	spawnHelper(self, "player", "BOTTOM", 0, 240)
	spawnHelper(self, "pet", "TOPLEFT", oUF_FreebPlayer, "BOTTOMLEFT", 0, -20)
	spawnHelper(self, "target", "LEFT", oUF_FreebPlayer, "RIGHT", 20, 65)
	spawnHelper(self, "targettarget", "TOPLEFT", oUF_FreebTarget, "TOPRIGHT", 10, 0)
	spawnHelper(self, "focus", "RIGHT", oUF_FreebPlayer, "LEFT", -50, 0)
end)
