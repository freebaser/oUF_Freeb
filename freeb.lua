local height, width = 24, 220
local border = "Interface\\AddOns\\oUF_Freeb\\media\\border"
local statusbar = "Interface\\AddOns\\oUF_Freeb\\media\\statusbar"
local font, fontsize, fontsizeBig = "Interface\\AddOns\\oUF_Freeb\\media\\font.ttf", 16, 18

RuneFrame:Hide()
local _, class = UnitClass('player')

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local updateName = function(self, event, unit)
	if(self.unit == unit) then
		local r, g, b, t
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			r, g, b = .6, .6, .6
		elseif(unit == 'pet') then
			t = self.colors.happiness[GetPetHappiness()]
		elseif(UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			t = self.colors.class[class]
		else
			t = self.colors.reaction[UnitReaction(unit, "player")]
			--r, g, b = .8, .8, .8
		end

		if(t) then
			r, g, b = t[1], t[2], t[3]
		end

		if(r) then
			self.Name:SetTextColor(r, g, b)
		end
	end
end

local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

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

local PostCastStart = function(self, event, unit, spell, spellrank, castid)
	self.Name:Hide()
end

local PostCastStop = function(self, event, unit)
	if(unit ~= self.unit) then return end
	self.Name:SetText(UnitName(unit))
	self.Name:Show()
end

local updateHealth = function(self, event, unit, bar, min, max)
	if(max ~= 0) then
		r, g, b = self.ColorGradient(min/max, .69,.31,.31, .65,.63,.35, .33,.59,.33)
	end

	if not(unit == "targettarget" or unit == "pet" or unit == "focus")then
		if(UnitIsDead(unit)) then
			bar:SetValue(0)
			bar.value:SetText"Dead"
		elseif(UnitIsGhost(unit)) then
			bar:SetValue(0)
			bar.value:SetText"Ghost"
		elseif(not UnitIsConnected(unit)) then
			bar.value:SetText"Offline"
		else
			if(min~=max) then
				bar.value:SetFormattedText('|cffAF5050%s|r |cffD7BEA5-|r |cff%02x%02x%02x%d%%|r', ShortValue(min), r*255, g*255, b*255, (min/max)*100)
			else
				bar.value:SetText('|cff559655'..ShortValue(max))
			end
		end
	end

	bar:SetStatusBarColor(.15, .15, .15)
	updateName(self, event, unit)
end

local updatePower = function(self, event, unit, bar, min, max)
  self.Health:SetHeight(24)
  if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
    bar:SetValue(0)
  elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
    bar:SetValue(0)
  else
    self.Health:SetHeight(21)
  end
end

local auraIcon = function(self, button, icons)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint("BOTTOM", button, 7, -3)
	icons.showDebuffType = true
	button.cd:SetReverse()
	button.overlay:SetTexture(border)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.4, 0.4, 0.4) end
end

local func = function(self, unit)
	self.menu = menu

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame"StatusBar"
	hp:SetHeight(21)
	hp:SetStatusBarTexture(statusbar)

	hp.frequentUpdates = true

	hp:SetParent(self)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(.4, .2, 0)

	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetPoint("RIGHT", hp, -2, 0)
	hpp:SetFont(font, fontsize)
	hpp:SetShadowOffset(1.25, -1.25)
	hpp:SetTextColor(1, 1, 1)

	hp.bg = hpbg
	hp.value = hpp
	self.Health = hp
	self.OverrideUpdateHealth = updateHealth

	local pp = CreateFrame"StatusBar"
	pp:SetHeight(2)
	pp:SetStatusBarTexture(statusbar)

	pp.frequentUpdates = true
	pp.colorTapping = true
	pp.colorHappiness = true
	pp.colorClass = true
	pp.colorReaction = true

	pp:SetParent(self)
	pp:SetPoint"LEFT"
	pp:SetPoint"RIGHT"
	pp:SetPoint"BOTTOM"
	
	local ppbg = pp:CreateTexture(nil, "BORDER")
	ppbg:SetAllPoints(pp)
	ppbg:SetTexture(statusbar)
	ppbg.multiplier = .3

	pp.bg = ppbg
	self.Power = pp
	self.PostUpdatePower = updatePower

	if not (unit == "targettarget")then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(statusbar)
		cb:SetStatusBarColor(.8, .8, 0, .6)
		cb:SetParent(self)
		cb:SetAllPoints(hp)
		cb:SetToplevel(true)
		cb.Text = cb:CreateFontString(nil, "OVERLAY")
		cb.Text:SetFont(font, fontsizeBig)
		cb.Text:SetShadowOffset(1.25, -1.25)
		cb.Text:SetPoint("LEFT", cb, "LEFT", 2, 0)
		cb.Text:SetJustifyH"LEFT"
		cb.Text:SetTextColor(1,1,1)
		cb.Text:SetHeight(fontsizeBig)
		cb.Text:SetWidth(120)
		cb.Icon = cb:CreateTexture(nil, 'ARTWORK')
		if unit == "target" or unit == "focus" then
			cb.Icon:SetPoint("RIGHT", self, "LEFT", -4, 0)
		else
			cb.Icon:SetPoint("LEFT", self, "RIGHT", 4, 0)
		end
		cb.Icon:SetHeight(24)
		cb.Icon:SetWidth(24)
		self.Castbar = cb
	end

	local leader = self:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOMLEFT", hp, "TOPLEFT")
	leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
	self.Leader = leader

	local masterlooter = self:CreateTexture(nil, 'OVERLAY')
	masterlooter:SetHeight(16)
	masterlooter:SetWidth(16)
	masterlooter:SetPoint('LEFT', leader, 'RIGHT')
	self.MasterLooter = masterlooter

	local ricon = hp:CreateFontString(nil, "OVERLAY")
	ricon:SetPoint("BOTTOM", hp, "TOP")
	ricon:SetFontObject(GameFontNormalSmall)
	ricon:SetTextColor(1, 1, 1)
	self.RIcon = ricon
	self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
	table.insert(self.__elements, updateRIcon)

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", hp, 2, 0)
	name:SetJustifyH"LEFT"
	name:SetFont(font, fontsize)
	name:SetShadowOffset(1.25, -1.25)
	name:SetTextColor(1, 1, 1)
	name:SetHeight(fontsize)
	name:SetWidth(120)

	self.Name = name
	
	if(unit == 'target' or unit == 'player') then
		self.Portrait = CreateFrame('PlayerModel', nil, self)
		self.Portrait:SetPoint('TOPLEFT', self.Health)
		self.Portrait:SetPoint('BOTTOMLEFT', self.Health)
		self.Portrait:SetAlpha(0.1)
		self.Portrait:SetWidth(width)
	end

	if(unit == "target") then
		local auras = CreateFrame("Frame", nil, self)
		auras:SetHeight(height)
		auras:SetWidth(width)
		auras.initialAnchor = "TOPLEFT"
		auras.num = 40
		auras.gap = true
		auras.spacing = 1
		auras["growth-x"] = "RIGHT"
		auras["growth-y"] = "DOWN"
		auras:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
		auras.size = height
		self.Auras = auras
	end

	if not (unit == "target") then
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(height)
		debuffs:SetWidth(10*height)
		if unit == "pet" then
			debuffs:SetPoint("LEFT", self, "RIGHT", 2, 0)
			debuffs.initialAnchor = "BOTTOMLEFT"
		else
			debuffs:SetPoint("RIGHT", self, "LEFT", -2, 0)
			debuffs.initialAnchor = "BOTTOMRIGHT"
			debuffs["growth-x"] = "LEFT"
		end
		debuffs.spacing = 1
		debuffs.size = height
		debuffs.num = 3
		self.Debuffs = debuffs
	end
	
	if(unit == 'player') then

		if(IsAddOnLoaded('oUF_RuneBar') and class == 'DEATHKNIGHT') then
			self.RuneBar = {}
			for i = 1, 6 do
				self.RuneBar[i] = CreateFrame('StatusBar', nil, self)
				if(i == 1) then
					self.RuneBar[i]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
				else
					self.RuneBar[i]:SetPoint('TOPLEFT', self.RuneBar[i-1], 'TOPRIGHT', 1, 0)
				end
				self.RuneBar[i]:SetStatusBarTexture(statusbar)
				self.RuneBar[i]:SetHeight(5)
				self.RuneBar[i]:SetWidth(width/6 - 0.85)
				self.RuneBar[i]:SetBackdrop(backdrop)
				self.RuneBar[i]:SetBackdropColor(0, 0, 0)
				self.RuneBar[i]:SetMinMaxValues(0, 1)

				self.RuneBar[i].bg = self.RuneBar[i]:CreateTexture(nil, 'BORDER')
				self.RuneBar[i].bg:SetAllPoints(self.RuneBar[i])
				self.RuneBar[i].bg:SetTexture(0.1, 0.1, 0.1)			
			end
		end

		-- Experience
		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -8)
			self.Experience:SetStatusBarTexture(statusbar)
			self.Experience:SetStatusBarColor(0,.7,1)
			self.Experience:SetHeight(11)
			self.Experience:SetWidth((unit == 'pet') and 150 or width)
			self.Experience:SetBackdrop(backdrop)
			self.Experience:SetBackdropColor(0, 0, 0)

			self.Experience.Tooltip = true

			self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY')
			self.Experience.Text:SetFont(font, fontsize)
			self.Experience.Text:SetShadowOffset(1, -1)
			self.Experience.Text:SetPoint('CENTER', self.Experience)
			self.Experience.bg = self.Experience:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(0.25, 0.25, 0.25)
		end

	end

	if(unit == 'player' or unit == 'pet' or unit == 'focus') then
	  -- BarFader
	  self.BarFade = true
	  self.BarFadeMinAlpha = .1
	end

	if(unit == 'pet') then
		self:RegisterEvent("UNIT_HAPPINESS", updateName)
	end

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	if (unit == "pet") or (unit == "focus") or (unit == "targettarget") then
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width*.6)
	else
		self:SetAttribute('initial-height', height)
		self:SetAttribute('initial-width', width)
	end
	
	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStop)
	table.insert(self.__elements, 2, PostCastStop)

	self.PostChannelStart = PostCastStart
	self.PostCastStart = PostCastStart

	self.PostCastStop = PostCastStop
	self.PostChannelStop = PostCastStop

	self.PostCreateAuraIcon = auraIcon
end

oUF:RegisterStyle("Freeb", func)

oUF:SetActiveStyle"Freeb"

local player = oUF:Spawn"player"
player:SetPoint("CENTER", -250, -100)
local target = oUF:Spawn"target"
target:SetPoint("CENTER", 250, -100)
local tot = oUF:Spawn"targettarget"
tot:SetPoint("BOTTOMRIGHT", oUF.units.target, "TOPRIGHT", 0, 4)
local pet = oUF:Spawn'pet'
pet:SetPoint("BOTTOMLEFT", oUF.units.player, "TOPLEFT", 0, 4)
local focus = oUF:Spawn"focus"
focus:SetPoint("RIGHT", oUF.units.pet, "LEFT", -4, 0)
