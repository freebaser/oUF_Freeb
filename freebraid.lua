local enable = false
if not enable then return end

local _, ns = ...

local mediaPath = "Interface\\AddOns\\oUF_Freeb\\media\\"
local texture = mediaPath.."Cabaret"
local glowTex = mediaPath.."glowTex"
local font, fontsize = mediaPath.."myriad.ttf", 12
local height, width = 28, 28
local scale = 1.0

local backdrop = {
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local frameBD = {
    edgeFile = glowTex, edgeSize = 5,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
}

local func = function(self, unit)
    self:SetBackdrop(backdrop)
    self:SetBackdropColor(0, 0, 0)

    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)

    self:RegisterForClicks"AnyUp"

    self.FrameBackdrop = ns.backdrop(self, self)

    local hp = CreateFrame("StatusBar", nil, self)
    hp:SetAllPoints(self)
    hp:SetStatusBarTexture(texture)
    hp.frequentUpdates = true
    hp.Smooth = true
    hp.colorClass = true
    hp.colorReaction = true

    local hpbg = hp:CreateTexture(nil, "BORDER")
    hpbg:SetAllPoints(hp)
    hpbg:SetTexture(texture)
    hpbg:SetVertexColor(.15,.15,.15)

    self.Health = hp

    local info = hp:CreateFontString(nil, "OVERLAY")
    info:SetPoint("LEFT", hp)
    info:SetPoint("RIGHT", hp)
    info:SetFont(font, fontsize)
    info:SetShadowOffset(1, -1)
    info:SetTextColor(1, 1, 1)
    self:Tag(info, '[freebraid:info]')

    local ricon = hp:CreateTexture(nil, "OVERLAY")
    ricon:SetPoint("BOTTOM", hp, "TOP", 0 , -10)
    ricon:SetSize(14, 14)
    self.RaidIcon = ricon

    self.Range = {
        insideAlpha = 1,
        outsideAlpha = .3,
    }
end

oUF:RegisterStyle("Freebraid", func)
oUF:SetActiveStyle"Freebraid"

local raid = oUF:SpawnHeader('Raid_Freeb', nil, 'raid,party,solo',
'oUF-initialConfigFunction', ([[
self:SetWidth(%d)
self:SetHeight(%d)
self:SetScale(%d)
]]):format(width, height, scale),
'showPlayer', true,
'showSolo', true,
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
raid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -25)
