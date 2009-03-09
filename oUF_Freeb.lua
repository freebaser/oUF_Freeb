--[[
	Version: 1.3
	Supported oUF Version: 1.3.1

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
	-- oUF_HealComm
	-- oUF_Smooth
	
	
]]
local texture = "Interface\\AddOns\\oUF_Freeb\\media\\Cabaret"
local border = "Interface\\AddOns\\oUF_Freeb\\media\\border"
local font = "Interface\\AddOns\\oUF_Freeb\\media\\font.ttf"
local height, width = 27, 252

-- Toggle Castbars
local castBars = true
local partycastBars = false
local castsafeZone = false

-- Toggle Raid Power bars
local raidpowerBars = false

RuneFrame:Hide() --------- Hides the Rune Frame, DKs will need to get a Rune Addon

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
	elseif(unit == 'targettarget') then
		bar.value:SetText()
	elseif(UnitIsDead(unit)) then
		bar.value:SetText('|cffD7BEA5'..'Dead')
	elseif(UnitIsGhost(unit)) then
		bar.value:SetText('|cffD7BEA5'..'Ghost')
	elseif(self:GetParent():GetName():match"oUF_Raid" or self:GetParent():GetName():match"oUF_Party")then
		if(min==max)then
		  bar.value:SetText()
		else
		  bar.value:SetText(min-max)
		end
	else
		if(min~=max) then
			if(unit == 'player') then
				bar.value:SetFormattedText('|cffAF5050%d|r |cffD7BEA5-|r |cff%02x%02x%02x%d%%|r', min, r*255, g*255, b*255, (min/max)*100)
			elseif(not unit or (unit and unit ~= 'player' and unit ~= 'target')) then
				bar.value:SetFormattedText('|cff%02x%02x%02x%d%%|r', r*255, g*255, b*255, (min/max)*100)
			else
				bar.value:SetFormattedText('|cffAF5050%s|r |cffD7BEA5-|r |cff%02x%02x%02x%d%%|r', ShortValue(min), r*255, g*255, b*255, (min/max)*100)
			end
		else
			if(unit ~= 'player' and unit ~= 'pet') then
				bar.value:SetText('|cff559655'..ShortValue(max))
			else
				bar.value:SetText('|cff559655'..max)
			end
		end
	end

	-- BarColor
	--bar:SetStatusBarColor(.3,.3,.3)
	if(max ~= 0)then
	  x,y,z = self.ColorGradient((min/max), .25,.35,.43, .25,.35,.43, .25,.25,.25)
  	else
	  x,y,z = .25,.25,.25
	end
	  bar:SetStatusBarColor(x,y,z)
end


-- Power Function
local updatePower = function(self, event, unit, bar, min, max)
	if(min == 0 or UnitIsDead(unit) or UnitIsGhost(unit) or self:GetParent():GetName():match"oUF_Party" or not UnitIsConnected(unit)) then
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

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")
	-- Health
	local hp = CreateFrame"StatusBar"
	if(unit == 'targettarget')then
	  hp:SetHeight(height)
	elseif(self:GetParent():GetName():match"oUF_Raid")then
	  hp:SetHeight(18)
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
	hpbg:SetTexture(.1, .1, .1)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)

	-- Health Text
	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetFont(font, 12)
	hpp:SetShadowOffset(1, -1)
	if(self:GetParent():GetName():match"oUF_Raid" or self:GetParent():GetName():match"oUF_Party")then
	  hpp:SetTextColor(.9, .3, .4)
	  hpp:SetPoint("RIGHT", -2, 0)
	else
	  hpp:SetTextColor(1, 1, 1)
	  hpp:SetPoint("BOTTOMRIGHT",hp,"TOPRIGHT", -2, 2)
	end

	hp.bg = hpbg
	hp.value = hpp
	self.Health = hp
	self.OverrideUpdateHealth = updateHealth
	-- Power
	if not(unit == 'targettarget' or self:GetParent():GetName():match"oUF_Raid") then
	  local pp = CreateFrame"StatusBar"

	  pp:SetHeight(height*.12)
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
	  pp:SetPoint("LEFT")
	  pp:SetPoint("RIGHT")

	  local ppbg = pp:CreateTexture(nil, "BORDER")
	  ppbg:SetAllPoints(pp)
	  ppbg:SetTexture(texture)
	  ppbg.multiplier = .25
	  
	  -- Power Text
	  local ppp = pp:CreateFontString(nil, "OVERLAY")
	  ppp:SetFont(font, 12)
	  ppp:SetShadowOffset(1, -1)
	  ppp:SetPoint("BOTTOMLEFT",hp,"TOPLEFT", 2, 2)
	  ppp:SetTextColor(1, 1, 1)

	  pp.value = ppp
	  pp.bg = ppbg
	  self.Power = pp
	  self.PostUpdatePower = updatePower
	end
	
	-- Raid Power
	if(raidpowerBars and self:GetParent():GetName():match"oUF_Raid")then
	  local pp = CreateFrame"StatusBar"
	  pp:SetHeight(2)
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
	  pp:SetPoint("LEFT")
	  pp:SetPoint("RIGHT")

	  local ppbg = pp:CreateTexture(nil, "BORDER")
	  ppbg:SetAllPoints(pp)
	  ppbg:SetTexture(texture)
	  ppbg.multiplier = .25

	  pp.bg = ppbg
	  self.Power = pp
  	end
	
	
	-- CastBar
	if(castBars)then
	  if not (unit == "targettarget" or self:GetParent():GetName():match"oUF_Raid" or self:GetParent():GetName():match"oUF_Party") then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(texture)
		-- CastBar Color
		cb:SetStatusBarColor(.9,.7,0)
		if(unit == 'focus' or unit == 'pet') then
			cb:SetWidth(150)
		else
			cb:SetWidth(width)
		end
		cb:SetHeight(14)
		cb:SetParent(self)
		cb:SetPoint("BOTTOM", 0, -16)
		cb:SetBackdrop(backdrop)
		cb:SetBackdropColor(0, 0, 0)
		cb:SetToplevel(true)
		self.Castbar = cb
		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(.1, .1, .1)
		self.Castbar.Text = self.Castbar:CreateFontString(nil, "OVERLAY")
		self.Castbar.Text:SetFont(font, 11)
		self.Castbar.Text:SetShadowOffset(1, -1)
		self.Castbar.Text:SetPoint("LEFT", self.Castbar, "LEFT", 2, 0)
		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Time:SetFont(font, 11)
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

	  end
	
	  if(partycastBars and self:GetParent():GetName():match"oUF_Party")then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(texture)
		-- CastBar Color
		cb:SetStatusBarColor(.9,.7,0)
		cb:SetWidth(150)
		cb:SetHeight(14)
		cb:SetParent(self)
		cb:SetPoint("BOTTOM", 0, -16)
		cb:SetBackdrop(backdrop)
		cb:SetBackdropColor(0, 0, 0)
		cb:SetToplevel(true)
		self.Castbar = cb
		self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
		self.Castbar.bg:SetAllPoints(self.Castbar)
		self.Castbar.bg:SetTexture(.1, .1, .1)
		self.Castbar.Text = self.Castbar:CreateFontString(nil, "OVERLAY")
		self.Castbar.Text:SetFont(font, 11)
		self.Castbar.Text:SetShadowOffset(1, -1)
		self.Castbar.Text:SetPoint("LEFT", self.Castbar, "LEFT", 2, 0)
		self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
		self.Castbar.Time:SetFont(font, 11)
		self.Castbar.Time:SetShadowOffset(1, -1)
		self.Castbar.Time:SetPoint("RIGHT", self.Castbar, "RIGHT",  -2, 0)
		self.Castbar.CustomTimeText = function(self, duration)
                  if self.casting then
                    self.Time:SetFormattedText("%.1f", self.max - duration)
                  elseif self.channeling then
                    self.Time:SetFormattedText("%.1f", duration)
                  end
            	end
	  end

	end
	
	-- Leader Icon
	if(self:GetParent():GetName():match'oUF_Raid' or self:GetParent():GetName():match'oUF_Party' or unit == 'player') then
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
	  
	  self.ReadyCheck = hp:CreateTexture(nil, 'OVERLAY')
	  self.ReadyCheck:SetHeight(24)
	  self.ReadyCheck:SetWidth(24)
	  self.ReadyCheck:SetPoint('CENTER')
	  
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
	  if(unit == "targettarget" or self:GetParent():GetName():match"oUF_Party") then
	      name:SetPoint("CENTER")
	    elseif(self:GetParent():GetName():match"oUF_Raid")then
	      name:SetPoint("LEFT", self, "RIGHT", 2, 0)
	    else
	      name:SetPoint("RIGHT", self, -2, 0)
	      name:SetJustifyH"RIGHT"
	  end
	  name:SetFont(font, 12)
	  name:SetShadowOffset(1, -1)
 	  name:SetTextColor(1, 1, 1)
	  self.Info = name
	  if(unit == 'target')then
	    self:Tag(self.Info,'[raidcolor][name] [difficulty][smartlevel][rare]')
	  else
	    self:Tag(self.Info,'[raidcolor][name]')
	  end
	end 

	-- Buffs
	if(unit == "target") then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetHeight(24)
		buffs:SetWidth(5*24)
		buffs.initialAnchor = "TOPLEFT"
		buffs.num = 20
		buffs["growth-y"] = "DOWN"
		buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, 0)
		buffs.size = 24
		buffs.spacing = 2
		self.Buffs = buffs
		-- Combo Points
		self.CPoints = self:CreateFontString(nil, 'OVERLAY')
		self.CPoints:SetFont(font, 12)
		self.CPoints:SetShadowOffset(1, -1)
		self.CPoints:SetPoint('RIGHT', self, 'LEFT', -2, 0)
		self.CPoints:SetTextColor(.8, .8, 0)
		self.CPoints:SetJustifyH('RIGHT')
		self.CPoints.unit = 'player'
	end

	if(unit) then
	    local debuffs = CreateFrame("Frame", nil, self)
	    debuffs:SetHeight(24)
	    debuffs:SetWidth(10*24)
	  if(unit == 'focus') then
		  debuffs:SetPoint("LEFT", self, "RIGHT", 2, 0)
		  debuffs["growth-x"] = "RIGHT"
		  debuffs.initialAnchor = "LEFT"
	  elseif(unit == 'player' or unit == 'targettarget') then
		  debuffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 15)
		  debuffs["growth-x"] = "LEFT"
		  debuffs.initialAnchor = "TOPRIGHT"
	  else
		  debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 15)
		  debuffs["growth-y"] = "UP"
		  debuffs.initialAnchor = "BOTTOMLEFT"
	  end
	    debuffs.size = 24		
	    debuffs.spacing = 2
	  if(unit == "targettarget" or unit == "focus" or unit == "player") then
	    debuffs.num = 5
    	  else
	    debuffs.num = 32
	  end
	    self.Debuffs = debuffs
	end

	--self.sortAuras = {}
	--self.sortAuras.reverse = true
	--self.sortAuras.selfFirst = true
	

	if(unit == 'player' and UnitLevel('player') ~= MAX_PLAYER_LEVEL) then
		self.Resting = self.Power:CreateTexture(nil, 'OVERLAY')
		self.Resting:SetHeight(18)
		self.Resting:SetWidth(18)
		self.Resting:SetPoint('BOTTOMLEFT', -8.5, -8.5)
		self.Resting:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
		self.Resting:SetTexCoord(0,0.5,0,0.421875)
	end


	-- DebuffHidghtlight
	self.DebuffHighlightBackdrop = true
	self.DebuffHighlightFilter = true

	if(unit == 'player' or unit == 'pet') then
		-- BarFader
		self.BarFade = true

		-- Experience
		if(IsAddOnLoaded('oUF_Experience') and unit == 'player') then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -20)
			self.Experience:SetStatusBarTexture(texture)
			self.Experience:SetStatusBarColor(0,.7,1)
			self.Experience:SetHeight(11)
			self.Experience:SetWidth((unit == 'pet') and 130 or 220)
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

	end

	-- CombatFeedback
	if not (self:GetParent():GetName():match"oUF_Raid" or unit == "player")then
	  local cbft = hp:CreateFontString(nil, "OVERLAY")
	  cbft:SetPoint("LEFT", hp, 5, 0)
	  cbft:SetFont(font, 12)
	  cbft:SetShadowOffset(1, -1)
	  self.CombatFeedbackText = cbft
	  self.CombatFeedbackText.maxAlpha = 1
	end

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	if(unit == "targettarget" or unit == "focus" or unit == "pet" or self:GetParent():GetName():match"oUF_Party") then 
	  self:SetAttribute('initial-height', height)
	  self:SetAttribute('initial-width', 150)
	elseif(self:GetParent():GetName():match"oUF_Raid")then
	  if(raidpowerBars)then
	    self:SetAttribute('initial-height', 20)
	    self:SetAttribute('initial-width', 125)
    	  else
	    self:SetAttribute('initial-height', 18)
	    self:SetAttribute('initial-width', 125)
	  end
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
player:SetPoint("CENTER", UIParent, -220, -200)
local target = oUF:Spawn("target")
target:SetPoint("CENTER", UIParent, 220, -200)

local tot = oUF:Spawn("targettarget")
tot:SetPoint("LEFT", oUF.units.player, "RIGHT", 19, 0)
local pet = oUF:Spawn("pet")
pet:SetPoint("RIGHT", oUF.units.player, "LEFT", -20, 0)
local focus = oUF:Spawn("focus")
focus:SetPoint("BOTTOMLEFT", oUF.units.player, "TOPLEFT", -170, 28)

local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("LEFT", oUF.units.player, 0, -70)
party:SetManyAttributes("showParty", true, "xOffset", 30.5, "point", "LEFT" )

local partyToggle = CreateFrame('Frame')

local raid = {}
for i = 1, 5 do
	local raidgroup = oUF:Spawn('header', 'oUF_Raid'..i)
	if(raidpowerBars)then
	  raidgroup:SetManyAttributes('groupFilter', tostring(i), 'showRaid', true, 'yOffSet', -3)
	else
	  raidgroup:SetManyAttributes('groupFilter', tostring(i), 'showRaid', true, 'yOffSet', -2)
	end
	table.insert(raid, raidgroup)
	if(i==1) then
		raidgroup:SetPoint('TOPLEFT', UIParent, 5, -150)
	else
		raidgroup:SetPoint('TOP', raid[i-1], 'BOTTOM', 0, -10)
	end
end

partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBERS_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		if(GetNumRaidMembers() > 5) then
			-- Show party in raid?
			party:Show()
			for i,v in ipairs(raid) do v:Show() end
		else
			party:Show()
			for i,v in ipairs(raid) do v:Hide() end
		end
	end
end)
