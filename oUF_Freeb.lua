--[[
	Version: 1.5
	Supported oUF Version: 1.3.x

	Based Code provided by oUF_Lily

	Credits to
	P3lim and Caellian 
	-- for letting me use some of their code to modify the layout
	 
	Haste
	-- for oUF and oUF_Lily

	Supported Plugins
	-- oUF_BarFader
	-- oUF_DebuffHighlight
	-- oUF_Experience
	-- oUF_CombatFeedback
	-- oUF_Smooth
]]

local _, class = UnitClass('player')
local texture = "Interface\\AddOns\\oUF_Freeb\\media\\Cabaret"
local border = "Interface\\AddOns\\oUF_Freeb\\media\\border"
local font = "Interface\\AddOns\\oUF_Freeb\\media\\font.ttf"
local fontsize = 11
local height, width = 27, 270

-- Toggle Castbars
local castBars = true
local castsafeZone = false

RuneFrame:Hide()

local function GetHexColor(color)
	return ("|cff%.2x%.2x%.2x"):format(color.r * 255, color.g * 255, color.b * 255)
end

oUF.Tags["[Freebdifficulty]"] = function(u) 
	local level = UnitLevel(u)
	local color = GetQuestDifficultyColor(level)
	return GetHexColor(color)
end

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local colors = setmetatable({
	power = setmetatable({
		['MANA'] = {.31,.45,.63},
		['RAGE'] = {.69,.31,.31},
		['FOCUS'] = {.71,.43,.27},
		['ENERGY'] = {.65,.63,.35},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

-- Druid Power Credits to P3lim
local function UpdateDruidPower(self)
	local bar = self.DruidPower
	local num, str = UnitPowerType('player')
	local min = UnitPower('player', (num ~= 0) and 0 or 3)
	local max = UnitPowerMax('player', (num ~= 0) and 0 or 3)

	bar:SetMinMaxValues(0, max)

	if(min ~= max) then
		bar:SetValue(min)
		bar:SetAlpha(1)

		if(num ~= 0) then
			bar:SetStatusBarColor(unpack(colors.power['MANA']))
			bar.Text:SetFormattedText('%d - %d%%', min, math.floor(min / max * 100))
		else
			bar:SetStatusBarColor(unpack(colors.power['ENERGY']))
			bar.Text:SetText()
		end
	else
		bar:SetAlpha(0)
		bar.Text:SetText()
	end
end

local function updateCombo(self, event, unit)
	if(unit == PlayerFrame.unit and unit ~= self.CPoints.unit) then
		self.CPoints.unit = unit
	end
end

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

-- Shorten Values
local function ShortValue(value)
	if value >= 1e7 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e6 then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e5 then
		return ('%.0fk'):format(value / 1e3)
	elseif value >= 1e3 then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

-- Icon
local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

-- Health Function
local updateHealth = function(self, event, unit, bar, min, max)
	if(max ~= 0) then
		r, g, b = self.ColorGradient(min/max, .69,.31,.31, .65,.63,.35, .33,.59,.33)
	end

	if(not UnitIsConnected(unit)) then
		bar:SetValue(0)
		bar.value:SetText('|cffD7BEA5'..'Offline')
	elseif(unit == 'targettarget' or unit == 'pet' or unit == 'focus') then
		bar.value:SetText()
	elseif(UnitIsDead(unit)) then
		bar.value:SetText('|cffD7BEA5'..'Dead')
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText('|cffD7BEA5'..'Ghost')
	else
		if(min~=max) then
			bar.value:SetFormattedText('|cffAF5050%s|r |cffD7BEA5-|r |cff%02x%02x%02x%d%%|r', ShortValue(min), r*255, g*255, b*255, (min/max)*100)
		
		else
			bar.value:SetText('|cff559655'..ShortValue(max))
		end
	end

	-- BarColor
	--bar:SetStatusBarColor(.3,.3,.3)
	if(max ~= 0)then
	  x,y,z = self.ColorGradient((min/max), .65,.25,.25, .25,.25,.25, .25,.25,.25)
  	else
	  x,y,z = .25,.25,.25
	end
	  bar:SetStatusBarColor(x,y,z)
end


-- Power Function
local updatePower = function(self, event, unit, bar, min, max)
	if(min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) or unit == 'pet' or unit == 'focus' or not UnitIsConnected(unit)) then
	  bar.value:SetText()
  	else
	  bar.value:SetFormattedText(ShortValue(min))
	end
	local _, pType = UnitPowerType(unit)
	local color = self.colors.power[pType]
	if(color) then bar.value:SetTextColor(color[1], color[2], color[3]) end
end

-- Aura
local auraIcon = function(self, button, icons)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint("BOTTOM", button, 7, -3)
	icons.showDebuffType = true
	button.cd:SetReverse()
	button.overlay:SetTexture(border)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end
end

-- Style
local func = function(self, unit)
	self.colors = colors
	self.menu = menu

	self:EnableMouse(true)
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	-- Health
	local hp = CreateFrame"StatusBar"
	if(unit == 'targettarget')then
	  hp:SetHeight(height)
	else
	  hp:SetHeight(height*.85)
	end
	hp:SetStatusBarTexture(texture)
	-- Smooth
	hp.Smooth = true

	hp.frequentUpdates = true

	hp:SetParent(self)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	-- Background color
	hpbg:SetTexture(.08, .08, .08)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)

	-- Health Text
	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetFont(font, fontsize)
	hpp:SetShadowOffset(1, -1)
	hpp:SetTextColor(1, 1, 1)
	hpp:SetPoint("RIGHT",hp, -2, 0)

	hp.bg = hpbg
	hp.value = hpp
	self.Health = hp
	self.OverrideUpdateHealth = updateHealth
	-- Power
	if not(unit == 'targettarget') then
	  local pp = CreateFrame"StatusBar"
	  pp:SetHeight(height*.11)
	  pp:SetStatusBarTexture(texture)

	  pp.frequentUpdates = true
	  pp.colorTapping = true
	  pp.colorHappiness = true
  	  pp.colorClass = true
	  pp.colorReaction = true
	  -- Smooth
	  pp.Smooth = false

	  pp:SetParent(self)
	  pp:SetPoint("BOTTOM")
	  pp:SetPoint("LEFT", .2, 0)
	  pp:SetPoint("RIGHT", -.2, 0)

	  local ppbg = pp:CreateTexture(nil, "BORDER")
	  ppbg:SetAllPoints(pp)
	  ppbg:SetTexture(texture)
	  ppbg.multiplier = .3
	  
	  -- Power Text
	  local ppp = pp:CreateFontString(nil, "OVERLAY")
	  ppp:SetFont(font, fontsize)
	  ppp:SetShadowOffset(1, -1)
	  ppp:SetPoint("RIGHT",hpp,"LEFT", -3, 0)
	  ppp:SetTextColor(1, 1, 1)

	  pp.value = ppp
	  pp.bg = ppbg
	  self.Power = pp
	  self.PostUpdatePower = updatePower
	end
	
	-- CastBar
	if(castBars)then
	  if not (unit == "targettarget") then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(texture)
		-- CastBar Color
		cb:SetStatusBarColor(.9,.7,0)
		if(unit == 'focus' or unit == 'pet') then
			cb:SetWidth(150)
		else
			cb:SetWidth(width - 16)
		end
		cb:SetHeight(14)
		cb:SetParent(self)
		cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
		cb:SetBackdrop(backdrop)
		cb:SetBackdropColor(0, 0, 0)
		cb:SetToplevel(true)
		self.Castbar = cb
		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(.1, .1, .1)
		self.Castbar.Text = self.Castbar:CreateFontString(nil, "OVERLAY")
		self.Castbar.Text:SetFont(font, fontsize)
		self.Castbar.Text:SetShadowOffset(1, -1)
		self.Castbar.Text:SetPoint("LEFT", self.Castbar, "LEFT", 2, 0)
		self.Castbar.Text:SetHeight(fontsize)
		self.Castbar.Text:SetWidth(110)
		self.Castbar.Text:SetJustifyH"LEFT"
		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Time:SetFont(font, fontsize)
		self.Castbar.Time:SetShadowOffset(1, -1)
		self.Castbar.Time:SetPoint("RIGHT", self.Castbar, "RIGHT",  -2, 0)
		self.Castbar.CustomTimeText = function(self, duration)
                  if self.casting then
                    self.Time:SetFormattedText("%.1f", self.max - duration)
                  elseif self.channeling then
                    self.Time:SetFormattedText("%.1f", duration)
                  end
            	end
		
		if(castsafeZone and unit == 'player') then
		  self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'ARTWORK')
		  self.Castbar.SafeZone:SetPoint('TOPRIGHT')
		  self.Castbar.SafeZone:SetPoint('BOTTOMRIGHT')
		  self.Castbar.SafeZone:SetTexture(texture)
		  self.Castbar.SafeZone:SetVertexColor(.69,.31,.31)
		end

		if not(unit == 'focus' or unit == 'pet')then
		self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'ARTWORK')
		self.Castbar.Icon:SetHeight(15)
		self.Castbar.Icon:SetWidth(15)
		self.Castbar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
		self.Castbar.Icon:SetPoint("LEFT", self.Castbar, "LEFT", -16, 0)
		end
	  end

	end
	
	-- Leader/MasterLoot Icon
	if(unit == 'player') then
	  local leader = hp:CreateTexture(nil, "OVERLAY")
	  leader:SetHeight(16)
	  leader:SetWidth(16)
	  leader:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", -5, -8)
	  leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
	  self.Leader = leader

	  local masterlooter = hp:CreateTexture(nil, 'OVERLAY')
	  masterlooter:SetHeight(16)
	  masterlooter:SetWidth(16)
	  masterlooter:SetPoint('LEFT', leader, 'RIGHT')
	  self.MasterLooter = masterlooter
	end
	
	--PvP
	local pvp = hp:CreateTexture(nil, "OVERLAY") 
	pvp:SetPoint("BOTTOMRIGHT", hp, "TOPRIGHT", 18, -20)
	pvp:SetHeight(28)
	pvp:SetWidth(28)
	self.PvP = pvp
	
	-- Raid Icon
	local ricon = hp:CreateFontString(nil, "OVERLAY")
	ricon:SetFontObject(GameFontNormalSmall)
	ricon:SetTextColor(1, 1, 1)
	ricon:SetPoint("CENTER", hp, 0, 12)
	ricon:SetHeight(24)
	ricon:SetWidth(24)
	self.RIcon = ricon
	self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
	table.insert(self.__elements, updateRIcon)
	
	if(unit~='player')then
	-- Name
	  local name = hp:CreateFontString(nil, "OVERLAY")
	  if(unit == "targettarget") then
	      name:SetPoint("CENTER")
	    else
	      name:SetPoint("LEFT", hp, "LEFT", 2, 0)
	      name:SetJustifyH"LEFT"
	  end
	  name:SetFont(font, fontsize)
	  name:SetShadowOffset(1, -1)
 	  name:SetTextColor(1, 1, 1)
	  name:SetWidth(125)		-- length of the Name
	  name:SetHeight(fontsize)
	  self.Info = name
	  if(unit == 'target')then
	    self:Tag(self.Info,'[Freebdifficulty][level][shortclassification] [raidcolor][name]')
	  else
	    self:Tag(self.Info,'[raidcolor][name]')
	  end
	end 

	-- Buffs
	if(unit == "target") then
		local auras = CreateFrame("Frame", nil, self)
		auras:SetHeight(height)
		auras:SetWidth(width)
		auras.initialAnchor = "TOPLEFT"
		auras.num = 40
		auras.gap = true
		auras.spacing = 1
		auras["growth-x"] = "RIGHT"
		auras["growth-y"] = "UP"
		auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		auras.size = height
		self.Auras = auras
		
		-- Combo Points
		self.CPoints = self:CreateFontString(nil, 'OVERLAY')
		self.CPoints:SetFont(font, 18)
		self.CPoints:SetShadowOffset(1, -1)
		self.CPoints:SetPoint('RIGHT', self, 'LEFT', -4, 0)
		self.CPoints:SetTextColor(.8, .8, 0)
		self.CPoints:SetJustifyH('RIGHT')
		self.CPoints.unit = PlayerFrame.unit
		self:RegisterEvent('UNIT_COMBO_POINTS', updateCombo)
	end

	if(unit) then
	    local debuffs = CreateFrame("Frame", nil, self)
	    debuffs:SetHeight(height)
	    debuffs:SetWidth(width)
	  if(unit == 'pet') then
		  debuffs:SetPoint("LEFT", self, "RIGHT", 2, 0)
		  debuffs["growth-x"] = "RIGHT"
		  debuffs.initialAnchor = "LEFT"
	  elseif(unit == 'player' or unit == 'focus' or unit == 'targettarget') then
		  debuffs:SetPoint("RIGHT", self, "LEFT", -2, 0)
		  debuffs["growth-x"] = "LEFT"
		  debuffs.initialAnchor = "RIGHT"
	  end
	    debuffs.size = height		
	    debuffs.spacing = 1
	  if(unit == "targettarget" or unit == "focus" or unit == "player" or unit == "pet") then
	    debuffs.num = 3
    	  else
	    debuffs.num = 30
	  end
	    self.Debuffs = debuffs 
	end	

	if(unit == 'player' and UnitLevel('player') ~= MAX_PLAYER_LEVEL) then
		self.Resting = self.Power:CreateTexture(nil, 'OVERLAY')
		self.Resting:SetHeight(18)
		self.Resting:SetWidth(20)
		self.Resting:SetPoint('BOTTOMLEFT', -8.5, -8.5)
		self.Resting:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
		self.Resting:SetTexCoord(0,0.5,0,0.421875)
	end


	-- DebuffHidghtlight
	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true

	if(unit == 'player') then
		if class == 'DEATHKNIGHT' then
			local runes = CreateFrame("Frame", nil, self)
			runes:SetBackdrop(backdrop)
			runes:SetBackdropColor(0, 0, 0, 1)
			runes:SetHeight(4)
			runes:SetWidth(width)
			runes.spacing = 1
			runes.anchor = "TOPLEFT"
			runes.growth = "RIGHT"
			runes.height = 4
			runes.width = (width / 6) - 1
			runes.order = { 1, 2, 3, 4, 5, 6 }
			runes:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
 
			for i = 1, 6 do
				local bar = CreateFrame("Statusbar", nil, runes)
				bar:SetStatusBarTexture(texture)
				bar.bg = bar:CreateTexture(nil, "BACKGROUND")
				bar.bg:SetTexture(texture)
				bar.bg:SetAllPoints(bar)
				bar.bg:SetAlpha(0.3)
				runes[i] = bar
			end
			self.Runes = runes	
		end

		-- Experience
		if(IsAddOnLoaded('oUF_Experience') and unit == "player" and UnitLevel(self.unit) ~= MAX_PLAYER_LEVEL) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -18)
			self.Experience:SetStatusBarTexture(texture)
			self.Experience:SetStatusBarColor(0,.7,1)
			self.Experience:SetHeight(10)
			self.Experience:SetWidth(width)
			self.Experience:SetBackdrop(backdrop)
			self.Experience:SetBackdropColor(0, 0, 0)

			self.Experience.Tooltip = true

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY')
			self.Experience.Text:SetFont(font, 10)
			self.Experience.Text:SetShadowOffset(1, -1)
			self.Experience.Text:SetPoint('CENTER', self.Experience)
			self.Experience.bg = self.Experience:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.25, 0.25, 0.25)
		end
		
		if(class == 'DRUID') then
			self.DruidPower = CreateFrame('StatusBar', nil, self)
			self.DruidPower:SetBackdrop(backdrop)
			self.DruidPower:SetBackdropColor(0, 0, 0)
			self.DruidPower:SetPoint('TOP', self, 'BOTTOM', 0, -1)
			self.DruidPower:SetStatusBarTexture(texture)
			self.DruidPower:SetHeight(5)
			self.DruidPower:SetWidth(width)
			self.DruidPower:SetAlpha(0)

			self.DruidPower.Text = self.DruidPower:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
			self.DruidPower.Text:SetPoint('CENTER', self.DruidPower)
			self.DruidPower.Text:SetTextColor(1, 1, 1)

			self:RegisterEvent('UNIT_MANA', UpdateDruidPower)
			self:RegisterEvent('UNIT_ENERGY', UpdateDruidPower)
			self:RegisterEvent('PLAYER_LOGIN', UpdateDruidPower)
		end

	end

	if(unit == 'player' or unit == 'pet' or unit == 'focus') then
	  -- BarFader
	  self.BarFade = true
	  self.BarFadeMinAlpha = .1
	end

	-- CombatFeedback 
	if not (unit == "player")then
	  local cbft = hp:CreateFontString(nil, "OVERLAY")
	  cbft:SetPoint("CENTER", self)
	  cbft:SetFont(font, fontsize)
	  cbft:SetShadowOffset(1, -1)
	  self.CombatFeedbackText = cbft
	  self.CombatFeedbackText.maxAlpha = 1
	end

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	if(unit == "targettarget" or unit == "focus" or unit == "pet") then 
	  self:SetAttribute('initial-height', height)
	  self:SetAttribute('initial-width', 150)
	else
	  self:SetAttribute('initial-height', height)
	  self:SetAttribute('initial-width', width)
	end

	self.disallowVehicleSwap = true

	self.PostCreateAuraIcon = auraIcon

	return self
end

oUF:RegisterStyle("Freeb", func)

oUF:SetActiveStyle"Freeb"

local player = oUF:Spawn("player")
player:SetPoint("CENTER", UIParent, -325, -175)
local target = oUF:Spawn("target")
target:SetPoint("CENTER", UIParent, 325, -175)
local tot = oUF:Spawn("targettarget")
tot:SetPoint("CENTER", UIParent, 0, -175)

local pet = oUF:Spawn("pet")
pet:SetPoint("BOTTOMLEFT", oUF.units.player, "TOPLEFT", 0, 18)
local focus = oUF:Spawn("focus")
focus:SetPoint("TOPRIGHT", oUF.units.player, "BOTTOMLEFT", -2, -4)
