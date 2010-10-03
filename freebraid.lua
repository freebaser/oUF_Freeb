local enable = false
if not enable then return end

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

local updateHealth = function(health, unit)
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

    health:SetStatusBarColor(r, g, b)
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

    hp.PostUpdate = updateHealth

    local info = hp:CreateFontString(nil, "OVERLAY")
    info:SetPoint("LEFT", hp)
    info:SetPoint("RIGHT", hp)
    info:SetFont(font, fontsize)
    info:SetShadowOffset(1, -1)
    info:SetTextColor(1, 1, 1)
    self:Tag(info, '[freebraid:info]')

    local ricon = hp:CreateTexture(nil, "HIGHLIGHT")
    ricon:SetPoint("BOTTOM", hp, "TOP", 0 , -10)
    ricon:SetSize(14, 14)
    self.RaidIcon = ricon

    self.Range = {
        insideAlpha = 1,
        outsideAlpha = .3,
    }

    self:SetAttribute('initial-height', height)
    self:SetAttribute('initial-width', width)
    self:SetAttribute('initial-scale', scale)
end

oUF:RegisterStyle("Freebraid", func)
oUF:SetActiveStyle"Freebraid"

local raid = oUF:SpawnHeader('Raid_Freeb', nil, 'raid,party,solo',
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
raid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -20)
