local ADDON_NAME, ns = ...

local mediaPath = "Interface\\AddOns\\oUF_Freeb\\media\\"
local texture = mediaPath.."Cabaret"
local font, fontsize, fontflag = mediaPath.."myriad.ttf", 12, "THINOUTLINE" -- "" for none

local glowTex = mediaPath.."glowTex"
local buttonTex = mediaPath.."buttontex"
local height, width = 22, 225
local scale = 1.0
local hpheight = .85 -- .70 - .90 

local overrideBlizzbuffs = false
local castbars = true   -- disable castbars
local auras = true  -- disable all auras
local bossframes = true
local auraborders = false

local classColorbars = false
local powerColor = true
local powerClass = false

local portraits = false
local onlyShowPlayer = false -- only show player debuffs on target

local pixelborder = false

if overrideBlizzbuffs then
    BuffFrame:Hide()
    TemporaryEnchantFrame:Hide()
end

local function multicheck(check, ...)
    for i=1, select('#', ...) do
        if check == select(i, ...) then return true end
    end
    return false
end

local backdrop = {
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local backdrop2 = {
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local frameBD = {
    edgeFile = glowTex, edgeSize = 5,
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {left = 3, right = 3, top = 3, bottom = 3}
}

-- Unit Menu
local dropdown = CreateFrame('Frame', ADDON_NAME .. 'DropDown', UIParent, 'UIDropDownMenuTemplate')

local function menu(self)
    dropdown:SetParent(self)
    return ToggleDropDownMenu(1, nil, dropdown, 'cursor', 0, 0)
end

local init = function(self)
    local unit = self:GetParent().unit
    local menu, name, id

    if(not unit) then
        return
    end

    if(UnitIsUnit(unit, "player")) then
        menu = "SELF"
    elseif(UnitIsUnit(unit, "vehicle")) then
        menu = "VEHICLE"
    elseif(UnitIsUnit(unit, "pet")) then
        menu = "PET"
    elseif(UnitIsPlayer(unit)) then
        id = UnitInRaid(unit)
        if(id) then
            menu = "RAID_PLAYER"
            name = GetRaidRosterInfo(id)
        elseif(UnitInParty(unit)) then
            menu = "PARTY"
        else
            menu = "PLAYER"
        end
    else
        menu = "TARGET"
        name = RAID_TARGET_ICON
    end

    if(menu) then
        UnitPopup_ShowMenu(self, menu, unit, name, id)
    end
end

UIDropDownMenu_Initialize(dropdown, init, 'MENU')

local createBackdrop = function(parent, anchor) 
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetFrameStrata("LOW")

    if pixelborder then
        frame:SetAllPoints(anchor)
        frame:SetBackdrop(backdrop2)
    else
        frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", -4, 4)
        frame:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 4, -4)
        frame:SetBackdrop(frameBD)
    end

    frame:SetBackdropColor(.05, .05, .05, 1)
    frame:SetBackdropBorderColor(0, 0, 0)

    return frame
end
ns.backdrop = createBackdrop

local fixStatusbar = function(bar)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
end

local createStatusbar = function(parent, tex, layer, height, width, r, g, b, alpha)
    local bar = CreateFrame"StatusBar"
    bar:SetParent(parent)
    if height then
        bar:SetHeight(height)
    end
    if width then
        bar:SetWidth(width)
    end
    bar:SetStatusBarTexture(tex, layer)
    bar:SetStatusBarColor(r, g, b, alpha)
    fixStatusbar(bar)

    return bar
end

local createFont = function(parent, layer, font, fontsiz, outline, r, g, b, justify)
    local string = parent:CreateFontString(nil, layer)
    string:SetFont(font, fontsiz, outline)
    string:SetShadowOffset(1, -1)
    string:SetTextColor(r, g, b)
    if justify then
        string:SetJustifyH(justify)
    end

    return string
end

local updateEclipse = function(element, unit)
    if element.hasSolarEclipse then
        element.bd:SetBackdropBorderColor(1, .6, 0)
        element.bd:SetBackdropColor(1, .6, 0)
    elseif element.hasLunarEclipse then
        element.bd:SetBackdropBorderColor(0, .4, 1)
        element.bd:SetBackdropColor(0, .4, 1)
    else
        element.bd:SetBackdropBorderColor(0, 0, 0)
        element.bd:SetBackdropColor(0, 0, 0)
    end
end

local xphide
local AltPower = function(self)
    local barType, minPower, _, _, _, hideFromOthers = UnitAlternatePowerInfo(self.unit)

    if barType and self.Experience:IsShown() then
        self.Experience:Hide()
        xphide = true
    elseif xphide  then
        self.Experience:Show()
        xphide = nil
    end

    self.AltPowerBar.Text:UpdateTag()
end

local PostAltUpdate = function(altpp, min, cur, max)
    local self = altpp.__owner

    local tPath, r, g, b = UnitAlternatePowerTextureInfo(self.unit, 2)

    if(r) then
        altpp:SetStatusBarColor(r, g, b, 1)
    else
        altpp:SetStatusBarColor(1, 1, 1, .8)
    end 
end

local GetTime = GetTime
local floor, fmod = floor, math.fmod
local day, hour, minute = 86400, 3600, 60

local FormatTime = function(s)
    if s >= day then
        return format("%dd", floor(s/day + 0.5))
    elseif s >= hour then
        return format("%dh", floor(s/hour + 0.5))
    elseif s >= minute then
        return format("%dm", floor(s/minute + 0.5))
    end

    return format("%d", fmod(s, minute))
end

local CreateAuraTimer = function(self,elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed

    if self.elapsed < .2 then return end
    self.elapsed = 0

    local timeLeft = self.expires - GetTime()
    if timeLeft <= 0 then
        self.remaining:SetText(nil)
    else
        self.remaining:SetText(FormatTime(timeLeft))
    end
end

local debuffFilter = {
    --Update this
}

local auraIcon = function(auras, button)
    local count = button.count
    count:ClearAllPoints()
    count:SetPoint("BOTTOMRIGHT", 3, -3)
    count:SetFontObject(nil)
    count:SetFont(font, 12, "OUTLINE")
    count:SetTextColor(.8, .8, .8)

    auras.disableCooldown = true

    button.icon:SetTexCoord(.1, .9, .1, .9)
    button.bg = createBackdrop(button, button)

    if auraborders then
        auras.showDebuffType = true
        button.overlay:SetTexture(buttonTex)
        button.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
        button.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        button.overlay:SetTexCoord(0, 1, 0.02, 1)
    else
        button.overlay:Hide()
    end

    local remaining = createFont(button, "OVERLAY", font, 12, "OUTLINE", .8, .8, .8)
    remaining:SetPoint("TOPLEFT", -3, 2)
    button.remaining = remaining
end

local PostUpdateIcon
do
    local playerUnits = {
        player = true,
        pet = true,
        vehicle = true,
    }

    PostUpdateIcon = function(icons, unit, icon, index, offset)
        local name, _, _, _, dtype, duration, expirationTime, unitCaster = UnitAura(unit, index, icon.filter)

        local texture = icon.icon
        if playerUnits[icon.owner] or debuffFilter[name] or UnitIsFriend('player', unit) or not icon.debuff then
            texture:SetDesaturated(false)
        else
            texture:SetDesaturated(true)
        end

        if duration and duration > 0 then
            icon.remaining:Show()
        else
            icon.remaining:Hide()
        end

        --[[if icon.debuff then
        icon.bg:SetBackdropBorderColor(.4, 0, 0)
        else
        icon.bg:SetBackdropBorderColor(0, 0, 0)
        end]]

        icon.duration = duration
        icon.expires = expirationTime
        icon:SetScript("OnUpdate", CreateAuraTimer)
    end
end

local aurafilter = {
    ["Chill of the Throne"] = true,
}

local CustomFilter = function(icons, ...)
    local _, icon, name, _, _, _, _, _, _, caster = ...

    if aurafilter[name] then
        return false
    end

    local isPlayer

    if multicheck(caster, 'player', 'vechicle') then
        isPlayer = true
    end

    if((icons.onlyShowPlayer and isPlayer) or (not icons.onlyShowPlayer and name)) then
        icon.isPlayer = isPlayer
        icon.owner = caster
        return true
    end
end

local PostCastStart = function(castbar, unit)
    if unit ~= 'player' then
        if castbar.interrupt then
            castbar.Backdrop:SetBackdropBorderColor(1, .9, .4)
            castbar.Backdrop:SetBackdropColor(1, .9, .4)
        else
            castbar.Backdrop:SetBackdropBorderColor(0, 0, 0)
            castbar.Backdrop:SetBackdropColor(0, 0, 0)
        end
    end
end

local CustomTimeText = function(castbar, duration)
    if castbar.casting then
        castbar.Time:SetFormattedText("%.1f / %.1f", duration, castbar.max)
    elseif castbar.channeling then
        castbar.Time:SetFormattedText("%.1f / %.1f", castbar.max - duration, castbar.max)
    end
end

--========================--
--  Castbars
--========================--
local castbar = function(self, unit)
    local u = unit:match('[^%d]+')
    if multicheck(u, "target", "player", "focus", "pet", "boss") then
        local cb = createStatusbar(self, texture, "OVERLAY", 16, portraits and 160 or width, 1, .25, .35, .5)
        cb:SetToplevel(true)

        cb.Spark = cb:CreateTexture(nil, "OVERLAY")
        cb.Spark:SetBlendMode("ADD")
        cb.Spark:SetAlpha(0.5)
        cb.Spark:SetHeight(48)

        local cbbg = cb:CreateTexture(nil, "BACKGROUND")
        cbbg:SetAllPoints(cb)
        cbbg:SetTexture(texture)
        cbbg:SetVertexColor(.1,.1,.1)

        cb.Time = createFont(cb, "OVERLAY", font, fontsize, fontflag, 1, 1, 1)
        cb.Time:SetPoint("RIGHT", cb, -2, 0)
        cb.CustomTimeText = CustomTimeText

        cb.Text = createFont(cb, "OVERLAY", font, fontsize, fontflag, 1, 1, 1, "LEFT")
        cb.Text:SetPoint("LEFT", cb, 2, 0)
        cb.Text:SetPoint("RIGHT", cb.Time, "LEFT")

        cb.Icon = cb:CreateTexture(nil, 'ARTWORK')
        cb.Icon:SetSize(22, 22)
        cb.Icon:SetTexCoord(.1, .9, .1, .9)

        if (unit == "player") then
            cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
            cb.Icon:SetPoint("BOTTOMLEFT", cb, "BOTTOMRIGHT", 7, 0)

            cb.SafeZone = cb:CreateTexture(nil,'ARTWORK')
            cb.SafeZone:SetPoint('TOPRIGHT')
            cb.SafeZone:SetPoint('BOTTOMRIGHT')
            cb.SafeZone:SetTexture(texture)
            cb.SafeZone:SetVertexColor(.9,.7,0, 1)
        else
            cb:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -10)
            cb.Icon:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", -7, 0)
        end

        cb.Backdrop = createBackdrop(cb, cb)
        cb.IBackdrop = createBackdrop(cb, cb.Icon)

        cb.PostCastStart = PostCastStart
        cb.PostChannelStart = PostCastStart

        cb.bg = cbbg
        self.Castbar = cb
    end
end

--========================--
--  Shared
--========================--
local func = function(self, unit)
    self.menu = menu

    self:SetBackdrop(backdrop)
    self:SetBackdropColor(0, 0, 0)

    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    self:RegisterForClicks"AnyUp"

    self.FrameBackdrop = createBackdrop(self, self)

    local hp = createStatusbar(self, texture, nil, nil, nil, .1, .1, .1, 1)
    hp:SetPoint"TOP"
    hp:SetPoint"LEFT"
    hp:SetPoint"RIGHT"

    if(unit == "targettarget" or unit == "focustarget") then
        hp:SetHeight(height)
    else
        hp:SetHeight(height*hpheight)
    end

    hp.frequentUpdates = true
    hp.Smooth = true

    local hpbg = hp:CreateTexture(nil, "BORDER")
    hpbg:SetAllPoints(hp)
    hpbg:SetTexture(texture)

    if classColorbars then
        hp.colorClass = true
        hp.colorReaction = true
        hpbg.multiplier = .2
    else
        hpbg:SetVertexColor(.3,.3,.3)
    end

    if not (unit == "targettarget" or unit == "focustarget") then
        local hpp = createFont(hp, "OVERLAY", font, fontsize, fontflag, 1, 1, 1)
        hpp:SetPoint("RIGHT", hp, -2, 0)

        if(unit == "player") then
            self:Tag(hpp, '[freeb:hp]')
        else
            self:Tag(hpp, '[freeb:pp]  [freeb:hp]')
        end
    end

    hp.bg = hpbg
    self.Health = hp

    if not (unit == "targettarget" or unit == "focustarget") then
        local pp = createStatusbar(self, texture, nil, height*-(hpheight-.95), nil, 1, 1, 1, 1)
        pp:SetPoint"LEFT"
        pp:SetPoint"RIGHT"
        pp:SetPoint"BOTTOM" 

        pp.frequentUpdates = false
        pp.Smooth = true

        local ppbg = pp:CreateTexture(nil, "BORDER")
        ppbg:SetAllPoints(pp)
        ppbg:SetTexture(texture) 

        if powerColor then
            pp.colorPower = true
            ppbg.multiplier = .2
        elseif powerClass then
            pp.colorClass = true
            ppbg.multiplier = .2
        else
            ppbg:SetVertexColor(.3,.3,.3)
        end

        pp.bg = ppbg
        self.Power = pp
    end

    local altpp = createStatusbar(self, texture, nil, 4, nil, 1, 1, 1, .8)
    altpp:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
    altpp:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -2)
    altpp.bg = altpp:CreateTexture(nil, 'BORDER')
    altpp.bg:SetAllPoints(altpp)
    altpp.bg:SetTexture(texture)
    altpp.bg:SetVertexColor(.1, .1, .1)
    altpp.bd = createBackdrop(altpp, altpp)

    altpp.Text =  createFont(altpp, "OVERLAY", font, fontsize, fontflag, 1, 1, 1)
    altpp.Text:SetPoint("CENTER")
    self:Tag(altpp.Text, "[freeb:altpower]")

    altpp.PostUpdate = PostAltUpdate
    self.AltPowerBar = altpp

    local leader = hp:CreateTexture(nil, "OVERLAY")
    leader:SetSize(16, 16)
    leader:SetPoint("TOPLEFT", hp, "TOPLEFT", 5, 10)
    self.Leader = leader

    local masterlooter = hp:CreateTexture(nil, 'OVERLAY')
    masterlooter:SetSize(16, 16)
    masterlooter:SetPoint('LEFT', leader, 'RIGHT')
    self.MasterLooter = masterlooter

    local LFDRole = hp:CreateTexture(nil, 'OVERLAY')
    LFDRole:SetSize(16, 16)
    LFDRole:SetPoint('LEFT', masterlooter, 'RIGHT')
    self.LFDRole = LFDRole

    local PvP = hp:CreateTexture(nil, 'OVERLAY')
    PvP:SetSize(24, 24)
    PvP:SetPoint('TOPRIGHT', hp, 12, 8)
    self.PvP = PvP

    local Combat = hp:CreateTexture(nil, 'OVERLAY')
    Combat:SetSize(20, 20)
    Combat:SetPoint('BOTTOMLEFT', hp, -10, -10)
    self.Combat = Combat

    local Resting = hp:CreateTexture(nil, 'OVERLAY')
    Resting:SetSize(20, 20)
    Resting:SetPoint('BOTTOMLEFT', Combat, 'TOPLEFT', 0, 4)
    self.Resting = Resting

    local QuestIcon = hp:CreateTexture(nil, 'OVERLAY')
    QuestIcon:SetSize(24, 24)
    QuestIcon:SetPoint('BOTTOMRIGHT', hp, 15, -20)
    self.QuestIcon = QuestIcon

    local PhaseIcon = hp:CreateTexture(nil, 'OVERLAY')
    PhaseIcon:SetSize(24, 24)
    PhaseIcon:SetPoint('RIGHT', QuestIcon, 'LEFT')
    self.PhaseIcon = PhaseIcon

    local name = createFont(hp, "OVERLAY", font, fontsize, fontflag, 1, 1, 1)
    if(unit == "targettarget" or unit == "focustarget") then
        name:SetPoint("LEFT", hp)
        name:SetPoint("RIGHT", hp)

        if classColorbars then
            self:Tag(name, '[freeb:name]')
        else
            self:Tag(name, '[freeb:color][freeb:name]')
        end
    else
        name:SetPoint("LEFT", hp, 2, 0)
        name:SetPoint("RIGHT", hp, -95, 0)
        name:SetJustifyH"LEFT"

        if(unit == "player") then
            self:Tag(name, '[freeb:pp]')
        elseif classColorbars then
            self:Tag(name, '[freeb:info] [freeb:name]')
        else
            self:Tag(name, '[freeb:info] [freeb:color][freeb:name]')
        end
    end

    local ricon = hp:CreateTexture(nil, 'OVERLAY')
    ricon:SetPoint("BOTTOM", hp, "TOP", 0, -7)
    ricon:SetSize(16, 16)
    self.RaidIcon = ricon

    if castbars then
        castbar(self, unit)
    end

    self:SetSize(width, height)
    if(unit == "targettarget" or unit == "focustarget") then
        self:SetSize(150, height)
    end

    self:SetScale(scale)
end

local UnitSpecific = {

    --========================--
    --  Player
    --========================--
    player = function(self, ...)
        func(self, ...)

        if portraits then
            self.Portrait = CreateFrame("PlayerModel", nil, self)
            self.Portrait:SetWidth(60)
            self.Portrait:SetHeight(36)
            self.Portrait:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -10)
            self.PorBackdrop = createBackdrop(self, self.Portrait)
        end

        local _, class = UnitClass("player")
        -- Runes, Shards, HolyPower
        if multicheck(class, "DEATHKNIGHT", "WARLOCK", "PALADIN") then
            local count
            if class == "DEATHKNIGHT" then 
                count = 6 
            else 
                count = 3 
            end

            local bars = CreateFrame("Frame", nil, self)
            bars:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -31)
            bars:SetSize(160/count - 5, 16)

            local i = count
            for index = 1, count do
                bars[i] = createStatusbar(bars, texture, nil, 14, (portraits and 160 or width)/count-5, 1, 1, 1, 1)

                if class == "WARLOCK" then
                    local color = self.colors.power["SOUL_SHARDS"]
                    bars[i]:SetStatusBarColor(color[1], color[2], color[3])
                elseif class == "PALADIN" then
                    local color = self.colors.power["HOLY_POWER"]
                    bars[i]:SetStatusBarColor(color[1], color[2], color[3])
                end 

                if i == count then
                    bars[i]:SetPoint("TOPRIGHT", bars, "TOPRIGHT")
                else
                    bars[i]:SetPoint("RIGHT", bars[i+1], "LEFT", -5, 0)
                end

                bars[i].bg = bars[i]:CreateTexture(nil, "BACKGROUND")
                bars[i].bg:SetAllPoints(bars[i])
                bars[i].bg:SetTexture(texture)
                bars[i].bg.multiplier = .2

                bars[i].bd = createBackdrop(bars[i], bars[i])
                i=i-1
            end

            if class == "DEATHKNIGHT" then
                bars[3], bars[4], bars[5], bars[6] = bars[5], bars[6], bars[3], bars[4]
                self.Runes = bars
            elseif class == "WARLOCK" then
                self.SoulShards = bars
            elseif class == "PALADIN" then
                self.HolyPower = bars
            end
        end

        if class == "DRUID" then
            local ebar = CreateFrame("Frame", nil, self)
            ebar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -31)
            ebar:SetSize(portraits and 160 or width, 14)
            ebar.bd = createBackdrop(ebar, ebar)

            local lbar = createStatusbar(ebar, texture, nil, 16, portraits and 160 or width, 0, .4, 1, 1)
            lbar:SetPoint("LEFT", ebar, "LEFT")
            ebar.LunarBar = lbar

            local sbar = createStatusbar(ebar, texture, nil, 16, portraits and 160 or width, 1, .6, 0, 1)
            sbar:SetPoint("LEFT", lbar:GetStatusBarTexture(), "RIGHT")
            ebar.SolarBar = sbar

            ebar.Spark = sbar:CreateTexture(nil, "OVERLAY")
            ebar.Spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
            ebar.Spark:SetBlendMode("ADD")
            ebar.Spark:SetAlpha(0.5)
            ebar.Spark:SetHeight(48)
            ebar.Spark:SetPoint("LEFT", sbar:GetStatusBarTexture(), "LEFT", -15, 0)

            self.EclipseBar = ebar
            self.EclipseBar.PostUnitAura = updateEclipse

            --EclipseBarFrame:ClearAllPoints()
            --EclipseBarFrame:SetParent(self)
            --EclipseBarFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -55)
        end

        if IsAddOnLoaded("oUF_TotemBar") and class == "SHAMAN" then
            self.TotemBar = {}
            self.TotemBar.Destroy = true
            for i = 1, 4 do
                self.TotemBar[i] = createStatusbar(self, texture, nil, 16, 160/4-5, 1, 1, 1, 1)

                if (i == 1) then
                    self.TotemBar[i]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -33)
                else
                    self.TotemBar[i]:SetPoint("RIGHT", self.TotemBar[i-1], "LEFT", -5, 0)
                end
                self.TotemBar[i]:SetBackdrop(backdrop)
                self.TotemBar[i]:SetBackdropColor(0.5, 0.5, 0.5)
                self.TotemBar[i]:SetMinMaxValues(0, 1)

                self.TotemBar[i].bg = self.TotemBar[i]:CreateTexture(nil, "BORDER")
                self.TotemBar[i].bg:SetAllPoints(self.TotemBar[i])
                self.TotemBar[i].bg:SetTexture(texture)
                self.TotemBar[i].bg.multiplier = 0.3

                self.TotemBar[i].bd = createBackdrop(self, self.TotemBar[i])
            end
        end

        if(IsAddOnLoaded('oUF_Experience')) then
            local OnEnter = function(self)
                UnitFrame_OnEnter(self)
                self.Experience.text:Show()	
            end

            local OnLeave = function(self)
                UnitFrame_OnLeave(self)
                self.Experience.text:Hide()	
            end

            self.Experience = createStatusbar(self, texture, nil, 4, nil, 0, .7, 1, 1)
            self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
            self.Experience:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -2)

            self.Experience.Rested = createStatusbar(self.Experience, texture, nil, nil, nil, 0, .4, 1, .6)
            self.Experience.Rested:SetAllPoints(self.Experience)
            self.Experience.Rested:SetBackdrop(backdrop)
            self.Experience.Rested:SetBackdropColor(0, 0, 0)

            self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BORDER')
            self.Experience.bg:SetAllPoints(self.Experience)
            self.Experience.bg:SetTexture(texture)
            self.Experience.bg:SetVertexColor(.1, .1, .1)

            self.Experience.bd = createBackdrop(self.Experience, self.Experience)

            self.Experience.text = createFont(self.Experience, "OVERLAY", font, fontsize, fontflag, 1, 1, 1)
            self.Experience.text:SetPoint("CENTER")
            self.Experience.text:Hide()
            self:Tag(self.Experience.text, '[freeb:curxp] / [freeb:maxxp] - [freeb:perxp]%')

            self:SetScript("OnEnter", OnEnter)
            self:SetScript("OnLeave", OnLeave)

            self:RegisterEvent('UNIT_POWER_BAR_SHOW', AltPower)
            self:RegisterEvent('UNIT_POWER_BAR_HIDE', AltPower)
        end

        if overrideBlizzbuffs then
            local buffs = CreateFrame("Frame", nil, self)
            buffs:SetHeight(36)
            buffs:SetWidth(36*12)
            buffs.initialAnchor = "TOPRIGHT"
            buffs.spacing = 5
            buffs.num = 40
            buffs["growth-x"] = "LEFT"
            buffs["growth-y"] = "DOWN"
            buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -20)
            buffs.size = 36

            buffs.PostCreateIcon = auraIcon
            buffs.PostUpdateIcon = PostUpdateIcon

            self.Buffs = buffs

            if (IsAddOnLoaded('oUF_WeaponEnchant')) then
                self.Enchant = CreateFrame('Frame', nil, self)
                self.Enchant.size = 32
                self.Enchant:SetHeight(32)
                self.Enchant:SetWidth(self.Enchant.size * 3)
                self.Enchant:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -390, -140)
                self.Enchant["growth-y"] = "DOWN"
                self.Enchant["growth-x"] = "LEFT"
                self.Enchant.spacing = 5
                self.PostCreateEnchantIcon = auraIcon
            end
        end

        if auras then 
            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(height+2)
            debuffs:SetWidth(width)
            debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            debuffs.spacing = 4
            debuffs.size = height+2
            debuffs.initialAnchor = "BOTTOMLEFT"

            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon
            debuffs.CustomFilter = CustomFilter

            self.Debuffs = debuffs
            self.Debuffs.num = 5 
        end
    end,

    --========================--
    --  Target
    --========================--
    target = function(self, ...)
        func(self, ...)

        if portraits then
            self.Portrait = CreateFrame("PlayerModel", nil, self)
            self.Portrait:SetWidth(60)
            self.Portrait:SetHeight(40)
            self.Portrait:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
            self.PorBackdrop = createBackdrop(self, self.Portrait)
        end

        if auras then
            local buffs = CreateFrame("Frame", nil, self)
            buffs:SetHeight(height)
            buffs:SetWidth(180)
            buffs.initialAnchor = "TOPLEFT"
            buffs.spacing = 4
            buffs.num = 20
            buffs["growth-x"] = "RIGHT"
            buffs["growth-y"] = "DOWN"
            buffs:SetPoint("LEFT", self, "RIGHT", 4, 0)
            buffs.size = height

            buffs.PostCreateIcon = auraIcon
            buffs.PostUpdateIcon = PostUpdateIcon

            self.Buffs = buffs

            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(height+2)
            debuffs:SetWidth(width)
            debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            debuffs.spacing = 4
            debuffs.size = height+2
            debuffs.initialAnchor = "BOTTOMLEFT"
            debuffs.onlyShowPlayer = onlyShowPlayer

            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon
            debuffs.CustomFilter = CustomFilter

            self.Debuffs = debuffs
            self.Debuffs.num = 16

            local Auras = CreateFrame("Frame", nil, self)
            Auras:SetHeight(height+2)
            Auras:SetWidth(width)
            Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            Auras.spacing = 4
            Auras.gap = true
            Auras.size = height+2
            Auras.initialAnchor = "BOTTOMLEFT"

            Auras.PostCreateIcon = auraIcon
            Auras.PostUpdateIcon = PostUpdateIcon
            Auras.CustomFilter = CustomFilter

            --self.Auras = Auras
            --self.Auras.numDebuffs = 16
            --self.Auras.numBuffs = 15
        end

        local cpoints = createFont(self, "OVERLAY", font, 24, "THINOUTLINE", 1, 0, 0)
        cpoints:SetPoint('RIGHT', self, 'LEFT', -4, 0)
        self:Tag(cpoints, '[cpoints]')
    end,

    --========================--
    --  Focus
    --========================--
    focus = function(self, ...)
        func(self, ...)

        if portraits then
            self.Portrait = CreateFrame("PlayerModel", nil, self)
            self.Portrait:SetWidth(60)
            self.Portrait:SetHeight(40)
            self.Portrait:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
            self.PorBackdrop = createBackdrop(self, self.Portrait)
        end

        if auras then 
            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(height+2)
            debuffs:SetWidth(width)
            debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            debuffs.spacing = 4
            debuffs.size = height+2
            debuffs.initialAnchor = "BOTTOMLEFT"

            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon

            self.Debuffs = debuffs
            self.Debuffs.num = 8

            local buffs = CreateFrame("Frame", nil, self)
            buffs:SetHeight(height)
            buffs:SetWidth(100)
            buffs.initialAnchor = "TOPLEFT"
            buffs.spacing = 4
            buffs.num = 20
            buffs["growth-x"] = "RIGHT"
            buffs["growth-y"] = "DOWN"
            buffs:SetPoint("LEFT", self, "RIGHT", 4, 0)
            buffs.size = height

            buffs.PostCreateIcon = auraIcon
            buffs.PostUpdateIcon = PostUpdateIcon

            self.Buffs = buffs
        end
    end,

    --========================--
    --  Focus Target
    --========================--
    focustarget = function(self, ...)
        func(self, ...)

    end,

    --========================--
    --  Pet
    --========================--
    pet = function(self, ...)
        func(self, ...)

        if auras then 
            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(height+2)
            debuffs:SetWidth(width)
            debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            debuffs.spacing = 4
            debuffs.size = height+2
            debuffs.initialAnchor = "BOTTOMLEFT"

            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon

            self.Debuffs = debuffs
            self.Debuffs.num = 8
        end
    end,

    --========================--
    --  Target Target
    --========================--
    targettarget = function(self, ...)
        func(self, ...)

        if auras then 
            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(height+2)
            debuffs:SetWidth(width)
            debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            debuffs.spacing = 4
            debuffs.size = height+2
            debuffs.initialAnchor = "BOTTOMLEFT"

            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon
            debuffs.CustomFilter = CustomFilter

            self.Debuffs = debuffs
            self.Debuffs.num = 5 
        end
    end,

    --========================--
    --  Boss
    --========================--
    boss = function(self, ...)
        func(self, ...)

        local Auras = CreateFrame("Frame", nil, self)
        Auras:SetHeight(height+2)
        Auras:SetWidth(width)
        Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
        Auras.spacing = 4
        Auras.gap = true
        Auras.size = height+2
        Auras.initialAnchor = "BOTTOMLEFT"

        Auras.PostCreateIcon = auraIcon
        Auras.PostUpdateIcon = PostUpdateIcon
        Auras.CustomFilter = CustomFilter

        --self.Auras = Auras
        --self.Auras.numDebuffs = 4
        --self.Auras.numBuffs = 3
    end,
}

oUF:RegisterStyle("Freeb", func)
for unit,layout in next, UnitSpecific do
    oUF:RegisterStyle('Freeb - ' .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
    if(UnitSpecific[unit]) then
        self:SetActiveStyle('Freeb - ' .. unit:gsub("^%l", string.upper))
    elseif(UnitSpecific[unit:match('[^%d]+')]) then -- boss1 -> boss
        self:SetActiveStyle('Freeb - ' .. unit:match('[^%d]+'):gsub("^%l", string.upper))
    else
        self:SetActiveStyle'Freeb'
    end

    local object = self:Spawn(unit)
    object:SetPoint(...)
    return object
end

oUF:Factory(function(self)
    spawnHelper(self, "player", "CENTER", -225, -175)
    spawnHelper(self, "target", "CENTER", 225, -175)
    spawnHelper(self, "targettarget", "CENTER", 0, -175)
    spawnHelper(self, "focus", "CENTER", 580, -60)
    spawnHelper(self, "focustarget", "RIGHT", self.units.focus, "LEFT", -10, 0)
    spawnHelper(self, "pet", "RIGHT", self.units.player, "LEFT", -10, 0)

    if bossframes then
        for i = 1, MAX_BOSS_FRAMES do
            spawnHelper(self,'boss' .. i, "CENTER", 580, 320 - (60 * i))
        end
    end
end)
