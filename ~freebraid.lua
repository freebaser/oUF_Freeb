local mediaPath = "Interface\\AddOns\\oUF_Freeb\\media\\"
local texture = mediaPath.."Cabaret"
local glowTex = mediaPath.."glowTex"
local height, width = 28, 28

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local frameBD = {
	edgeFile = glowTex, edgeSize = 5,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
}

local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

local updateHealth = function(self, event, unit, bar)
	local r, g, b, t
	if(UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = oUF.colors.class[class]
	else		
		r, g, b = .1, .8, .3
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	bar:SetStatusBarColor(r, g, b)
end


local func = function(self, unit)
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")
	
	self.FrameBackdrop = CreateFrame("Frame", nil, self)
	self.FrameBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", -4, 4)
	self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 4, -4)
	self.FrameBackdrop:SetFrameStrata("LOW")
	self.FrameBackdrop:SetBackdrop(frameBD)
	self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp:SetStatusBarTexture(texture)
	hp.frequentUpdates = true
	hp.Smooth = true

	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hpbg:SetVertexColor(.15,.15,.15)

	hp.bg = hpbg
	self.Health = hp

	self.OverrideUpdateHealth = updateHealth

	local ricon = hp:CreateFontString(nil, "OVERLAY")
	ricon:SetPoint("BOTTOM", hp, "TOP", 0 , -8)
	ricon:SetFont("Fonts\\FRIZQT__.ttf", 13)
	ricon:SetTextColor(1, 1, 1)
	self.RIcon = ricon
	self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
	table.insert(self.__elements, updateRIcon)

	self.Range = true
	self.inRangeAlpha = 1
	self.outsideRangeAlpha = .3
	
	self:SetAttribute('initial-height', height)
	self:SetAttribute('initial-width', width)
end

oUF:RegisterStyle("Freebraid", func)
oUF:SetActiveStyle"Freebraid"

local raid = oUF:Spawn('header', 'Raid_Freeb', nil, 'party')
raid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -20)
raid:SetManyAttributes(
	'showPlayer', true,
	'showSolo', false,
	'showParty', true,
	'showRaid', true,
	'xoffset', 5,
	'yOffset', -5,
	'point', "LEFT",
	'groupFilter', '1,2,3,4,5,6,7,8',
	'groupingOrder', '1,2,3,4,5,6,7,8',
	'groupBy', 'GROUP',
	'maxColumns', 8,
	'unitsPerColumn', 5,
	'columnSpacing', 5,
	'columnAnchorPoint', "TOP"
)
raid:Show()