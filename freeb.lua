local mediaPath = "Interface\\AddOns\\oUF_Freeb\\media\\"
local texture = mediaPath.."Cabaret"
local font, fontsize = mediaPath.."myriad.ttf", 12
local glowTex = mediaPath.."glowTex"
local height, width = 22, 220

local overrideBlizzbuffs = true

if overrideBlizzbuffs then
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()
end

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = -1, left = -1, bottom = -1, right = -1},
}

local frameBD = {
	edgeFile = glowTex, edgeSize = 5,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
}

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
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

local function updateCombo(self, event, unit)
	if(unit == PlayerFrame.unit and unit ~= self.CPoints.unit) then
		self.CPoints.unit = unit
	end
end

local CancelAura = function(self, button)
	if button == "RightButton" and not self.debuff then
		CancelUnitBuff("player", self:GetID())
	end
end

local auraIcon = function(self, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOMRIGHT"

	button.icon:SetTexCoord(.1, .9, .1, .9)
	button.bg = CreateFrame("Frame", nil, button)
	button.bg:SetPoint("TOPLEFT", button, "TOPLEFT", -4.5, 4.5)
	button.bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4.5, -4.5)
	button.bg:SetFrameStrata("LOW")
	button.bg:SetBackdrop(frameBD)
	button.bg:SetBackdropColor(0, 0, 0, 0)
	button.bg:SetBackdropBorderColor(0, 0, 0)
	
	if self.unit == "player" then
		button:SetScript("OnMouseUp", CancelAura)
	end
end

local func = function(self, unit)
	self.menu = menu
	self.MoveableFrames = true
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0)
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")
	
	self.FrameBackdrop = CreateFrame("Frame", nil, self)
	self.FrameBackdrop:SetPoint("TOPLEFT", self, "TOPLEFT", -4.5, 4.5)
	self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 4.5, -4.5)
	self.FrameBackdrop:SetFrameStrata("LOW")
	self.FrameBackdrop:SetBackdrop(frameBD)
	self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)

	local hp = CreateFrame"StatusBar"
	hp:SetHeight(height*.90)
	hp:SetStatusBarTexture(texture)
	hp:SetStatusBarColor(.1, .1, .1)

	hp.frequentUpdates = true
	hp.Smooth = true

	hp:SetParent(self)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hpbg:SetVertexColor(.25,.25,.25)

	if(unit and not (unit == "targettarget")) then
		local hpp = hp:CreateFontString(nil, "OVERLAY")
		hpp:SetPoint("RIGHT", -2, 0)
		hpp:SetFont(font, fontsize)
		hpp:SetShadowOffset(1, -1)
		hpp:SetTextColor(1, 1, 1)
		self:Tag(hpp, '[freebHp]')
	end

	hp.bg = hpbg
	self.Health = hp

	local pp = CreateFrame"StatusBar"
	pp:SetHeight(height*.05)
	pp:SetStatusBarTexture(texture)
	pp:SetStatusBarColor(1, 1, 1)

	pp.frequentUpdates = true
	pp.Smooth = true

	pp:SetParent(self)
	pp:SetPoint"LEFT"
	pp:SetPoint"RIGHT"
	pp:SetPoint"BOTTOM"
	
	if(unit and (unit == "player")) then
		local ppp = hp:CreateFontString(nil, "OVERLAY")
		ppp:SetPoint("LEFT", 4, 0)
		ppp:SetFont(font, fontsize)
		ppp:SetShadowOffset(1, -1)
		ppp:SetTextColor(1, 1, 1)
		self:Tag(ppp, '[freebPp]')
		
		local runes = CreateFrame("Frame", nil, self)
		runes:SetHeight(16)
		runes:SetWidth(150)
		runes.spacing = 5
		runes.anchor = "TOPLEFT"
		runes.growth = "RIGHT"
		runes.height = 16
		runes.width = 150 / 6 - 5
		runes.order = { 1, 2, 3, 4, 5, 6 }
		runes:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -33)

		for i = 1, 6 do
			local bar = CreateFrame("Statusbar", nil, runes)
			bar:SetStatusBarTexture(texture)
			bar:SetBackdrop(backdrop)
			bar:SetBackdropColor(.05, .05, .05, 1)
			bar:SetFrameLevel(2)
			bar.bd = CreateFrame("Frame", nil, bar)
			bar.bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -4.5, 4.5)
			bar.bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4.5, -4.5)
			bar.bd:SetFrameStrata("LOW")
			bar.bd:SetBackdrop(frameBD)
			bar.bd:SetBackdropColor(0, 0, 0, 0)
			bar.bd:SetBackdropBorderColor(0, 0, 0)
			runes[i] = bar
		end
		self.Runes = runes
		
		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
			self.Experience:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -2)
			self.Experience:SetHeight(4)
			self.Experience:SetStatusBarTexture(texture)
			self.Experience:SetStatusBarColor(0, 0.7, 1)
			self.Experience.Tooltip = true

			self.Experience.Rested = CreateFrame('StatusBar', nil, self)
			self.Experience.Rested:SetAllPoints(self.Experience)
			self.Experience.Rested:SetStatusBarTexture(texture)
			self.Experience.Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
			self.Experience.Rested:SetBackdrop(backdrop)
			self.Experience.Rested:SetBackdropColor(0, 0, 0)

			self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(texture)
			self.Experience.bg:SetVertexColor(.1, .1, .1)
			
			self.Experience.bd = CreateFrame("Frame", nil, self.Experience)
			self.Experience.bd:SetPoint("TOPLEFT", self.Experience, "TOPLEFT", -4.5, 4.5)
			self.Experience.bd:SetPoint("BOTTOMRIGHT", self.Experience, "BOTTOMRIGHT", 4.5, -4.5)
			self.Experience.bd:SetFrameStrata("LOW")
			self.Experience.bd:SetBackdrop(frameBD)
			self.Experience.bd:SetBackdropColor(0, 0, 0, 0)
			self.Experience.bd:SetBackdropBorderColor(0, 0, 0)
		end
		
		if overrideBlizzbuffs then
			local buffs = CreateFrame("Frame", nil, self)
			buffs:SetHeight(32)
			buffs:SetWidth(400)
			buffs.initialAnchor = "TOPRIGHT"
			buffs.spacing = 5
			buffs.num = 30
			buffs["growth-x"] = "LEFT"
			buffs["growth-y"] = "DOWN"
			buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -200, -10)
			buffs.size = 32
			self.Buffs = buffs
		end
	end
	
	local ppbg = pp:CreateTexture(nil, "BORDER")
	ppbg:SetAllPoints(pp)
	ppbg:SetTexture(texture)
	ppbg:SetVertexColor(.3,.3,.3)

	pp.bg = ppbg
	self.Power = pp

	if(unit and (unit == "target" or unit == "player" or unit == "focus")) then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(texture, "OVERLAY")
		cb:SetStatusBarColor(1, .25, .35, .5)
		cb:SetParent(self)
		cb:SetHeight(16)
		cb:SetWidth(150)
		cb:SetToplevel(true)
		
		local cbbg = cb:CreateTexture(nil, "BACKGROUND")
		cbbg:SetAllPoints(cb)
		cbbg:SetTexture(texture)
		cbbg:SetVertexColor(.1,.1,.1)
		
		cb.Text = cb:CreateFontString(nil, "OVERLAY")
		cb.Text:SetFont(font, fontsize)
		cb.Text:SetShadowOffset(1, -1)
		cb.Text:SetPoint("LEFT", cb, 2, 0)
		
		cb.Time = cb:CreateFontString(nil, 'OVERLAY')
		cb.Time:SetFont(font, fontsize)
		cb.Time:SetShadowOffset(1, -1)
		cb.Time:SetPoint("RIGHT", cb,  -2, 0)
		cb.CustomTimeText = function(self, duration)
                  if self.casting then
                    self.Time:SetFormattedText("%.1f", self.max - duration)
                  elseif self.channeling then
                    self.Time:SetFormattedText("%.1f", duration)
                  end
	  	end
		
		cb.Icon = cb:CreateTexture(nil, 'ARTWORK')
		cb.Icon:SetHeight(28)
		cb.Icon:SetWidth(28)
		cb.Icon:SetTexCoord(.1, .9, .1, .9)
		
		if (unit == "player") then
			cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
			cb.Icon:SetPoint("TOPLEFT", cb, "TOPRIGHT", 7, 0)
		else
			cb:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -10)
			cb.Icon:SetPoint("TOPRIGHT", cb, "TOPLEFT", -7, 0)
		end
		
		if(unit == "player") then
			cb.SafeZone = cb:CreateTexture(nil,'ARTWORK')
			cb.SafeZone:SetPoint('TOPRIGHT')
			cb.SafeZone:SetPoint('BOTTOMRIGHT')
			cb.SafeZone:SetTexture(texture)
			cb.SafeZone:SetVertexColor(.9,.7,0, 1)
		end
		
		cb.Backdrop = CreateFrame("Frame", nil, cb)
		cb.Backdrop:SetPoint("TOPLEFT", cb, "TOPLEFT", -4.5, 4.5)
		cb.Backdrop:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 4.5, -4.5)
		cb.Backdrop:SetFrameStrata("LOW")
		cb.Backdrop:SetBackdrop(frameBD)
		cb.Backdrop:SetBackdropColor(0, 0, 0, 0)
		cb.Backdrop:SetBackdropBorderColor(0, 0, 0)
		
		cb.IBackdrop = CreateFrame("Frame", nil, cb)
		cb.IBackdrop:SetPoint("TOPLEFT", cb.Icon, "TOPLEFT", -4.5, 4.5)
		cb.IBackdrop:SetPoint("BOTTOMRIGHT", cb.Icon, "BOTTOMRIGHT", 4.5, -4.5)
		cb.IBackdrop:SetFrameStrata("LOW")
		cb.IBackdrop:SetBackdrop(frameBD)
		cb.IBackdrop:SetBackdropColor(0, 0, 0, 0)
		cb.IBackdrop:SetBackdropBorderColor(0, 0, 0)
		
		cb.bg = cbbg
		self.Castbar = cb
		
	end

	local leader = hp:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOM", hp, "TOP", 0, -5)
	self.Leader = leader

	local masterlooter = hp:CreateTexture(nil, 'OVERLAY')
	masterlooter:SetHeight(16)
	masterlooter:SetWidth(16)
	masterlooter:SetPoint('LEFT', leader, 'RIGHT')
	self.MasterLooter = masterlooter

	local ricon = hp:CreateFontString(nil, "OVERLAY")
	ricon:SetPoint("LEFT", 2, 4)
	ricon:SetJustifyH"LEFT"
	ricon:SetFont(font, 12)
	ricon:SetTextColor(1, 1, 1)
	self.RIcon = ricon
	self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
	table.insert(self.__elements, updateRIcon)

	if(unit and not (unit == "player")) then
		local name = hp:CreateFontString(nil, "OVERLAY")
		if(unit == "targettarget") then
			name:SetPoint("CENTER")
		else
			name:SetPoint("LEFT", 4, 0)
		end
		name:SetFont(font, fontsize)
		name:SetShadowOffset(1, -1)
		name:SetTextColor(1, 1, 1)
		self:Tag(name, '[freebName]')
	end
	
	if(unit and (unit == "target" or unit == "player" or unit == "focus")) then
		self.Portrait = CreateFrame("PlayerModel", nil, self)
		self.Portrait:SetWidth(60)
		self.Portrait:SetHeight(40)
		if(unit and (unit == "player")) then
			self.Portrait:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -10)
		else
			self.Portrait:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
		end
		self.PorBackdrop = CreateFrame("Frame", nil, self)
		self.PorBackdrop:SetPoint("TOPLEFT", self.Portrait, "TOPLEFT", -4.5, 4.5)
		self.PorBackdrop:SetPoint("BOTTOMRIGHT", self.Portrait, "BOTTOMRIGHT", 4.5, -4.5)
		self.PorBackdrop:SetFrameStrata("LOW")
		self.PorBackdrop:SetBackdrop {
		  edgeFile = glowTex, edgeSize = 5,
		  insets = {left = 3, right = 3, top = 3, bottom = 3}
		}
		self.PorBackdrop:SetBackdropColor(0, 0, 0, 0)
		self.PorBackdrop:SetBackdropBorderColor(0, 0, 0)
	end

	if(unit == "target") then
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
		self.Buffs = buffs
		
		self.CPoints = self.Portrait:CreateFontString(nil, 'OVERLAY')
		self.CPoints:SetFont(font, 32, "THINOUTLINE")
		self.CPoints:SetShadowOffset(1, -1)
		self.CPoints:SetPoint('CENTER', self.Portrait)
		self.CPoints:SetTextColor(1, 0, 0)
		self.CPoints.unit = PlayerFrame.unit
		self:RegisterEvent('UNIT_COMBO_POINTS', updateCombo)
	end

	if(unit) then
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(height)
		debuffs:SetWidth(width)
		debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
		debuffs.spacing = 4
		debuffs.size = height
		debuffs.initialAnchor = "BOTTOMLEFT"
		if(unit == "target") then
			debuffs.num = 30
		else
			debuffs.num = 5
		end
		self.Debuffs = debuffs
	end

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	self:SetAttribute('initial-height', height)
	if(unit and (unit == "targettarget")) then
		self:SetAttribute('initial-width', 150)
	else
		self:SetAttribute('initial-width', width)
	end

	self.PostCreateAuraIcon = auraIcon
end

oUF:RegisterStyle("Freeb", func)

oUF:SetActiveStyle"Freeb"

local player = oUF:Spawn"player"
player:SetPoint("CENTER", -200, -150)
local target = oUF:Spawn"target"
target:SetPoint("CENTER", 200, -150)
local tot = oUF:Spawn"targettarget"
tot:SetPoint("CENTER", 0, -150)
local focus = oUF:Spawn"focus"
focus:SetPoint("CENTER", 400, 0)
local pet = oUF:Spawn'pet'
pet:SetPoint("RIGHT", oUF.units.player, "LEFT", -10, 0)
