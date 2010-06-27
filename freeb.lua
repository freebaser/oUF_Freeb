local mediaPath = "Interface\\AddOns\\oUF_Freeb\\media\\"
local texture = mediaPath.."Cabaret"
local font, fontsize = mediaPath.."myriad.ttf", 12
local glowTex = mediaPath.."glowTex"
local buttonTex = mediaPath.."buttontex"
local height, width = 22, 220
local scale = 1.0

local overrideBlizzbuffs = false
local castbars = true	-- disable castbars
local auras = true	-- disable all auras
local healtext = false -- Healcomm support
local healbar = false	-- Healcomm support
local bossframes = true
local auraborders = false
local classColorbars = false
local portraits = true

if overrideBlizzbuffs then
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()
end

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local frameBD = {
	edgeFile = glowTex, edgeSize = 5,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
}

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("^%l", string.upper)

	if(cunit == 'Vehicle') then
		cunit = 'Pet'
	end

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 0.5)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		return format("%dm", floor(s/minute + 0.5)), s % minute
	end
	return floor(s + 0.5), (s * 100 - floor(s * 100))/100
end

local CreateAuraTimer = function(self,elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				local atime = FormatTime(self.timeLeft)
				self.remaining:SetText(atime)
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local debuffFilter = {
	[GetSpellInfo(770)] = false, -- Faerie Fire
	[GetSpellInfo(16857)] = false, -- Faerie Fire (Feral)
	[GetSpellInfo(48564)] = false, -- Mangle (Bear)
	[GetSpellInfo(48566)] = false, -- Mangle (Cat)
	[GetSpellInfo(46857)] = false, -- Trauma
	[GetSpellInfo(7386)] = true, -- Sunder
}

local auraIcon = function(auras, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", 3, -3)
	
	auras.disableCooldown = true

	button.icon:SetTexCoord(.1, .9, .1, .9)
	button.bg = CreateFrame("Frame", nil, button)
	button.bg:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
	button.bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
	button.bg:SetFrameStrata("LOW")
	button.bg:SetBackdrop(frameBD)
	button.bg:SetBackdropColor(0, 0, 0, 0)
	button.bg:SetBackdropBorderColor(0, 0, 0)

	if auraborders then
		auras.showDebuffType = true
		button.overlay:SetTexture(buttonTex)
		button.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
		button.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		button.overlay:SetTexCoord(0, 1, 0.02, 1)
		button.overlay.Hide = function(self) self:SetVertexColor(0.33, 0.59, 0.33) end
	else
		button.overlay:Hide()
	end
	
	local remaining = button:CreateFontString(nil, "OVERLAY")
	remaining:SetPoint("TOPLEFT", -3, 2)
	remaining:SetFont(font, 12, "OUTLINE")
	remaining:SetTextColor(.8, .8, .8)
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
		if playerUnits[icon.owner] or debuffFilter[name] or not UnitIsFriend('player', unit) and not icon.debuff or UnitIsFriend('player', unit) and icon.debuff then
			texture:SetDesaturated(false)
		else
			texture:SetDesaturated(true)
		end
		
		if duration and duration > 0 then
			icon.remaining:Show()
		else
			icon.remaining:Hide()
		end
		
		icon.duration = duration
		icon.timeLeft = expirationTime
		icon.first = true
		icon:SetScript("OnUpdate", CreateAuraTimer)
	end
end

local updateHealth = function(health, unit)
	local r, g, b, t
	local reaction = UnitReaction(unit, "player")
	if(UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = oUF.colors.class[class]
	elseif reaction then
		t = oUF.colors.reaction[reaction]
	else
		r, g, b = .1, .8, .3
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	health:SetStatusBarColor(r, g, b)
end

local fixStatusbar = function(bar)
	bar:GetStatusBarTexture():SetHorizTile(false)
	bar:GetStatusBarTexture():SetVertTile(false)
end

local PostCastStart = function(castbar)
	if castbar.interrupt then
		castbar:SetStatusBarColor(.1, .9, .3, .5)
	else
		castbar:SetStatusBarColor(1, .25, .35, .5)
	end
end

local CustomTimeText = function(castbar, duration)
	if castbar.casting then
		castbar.Time:SetFormattedText("%.1f", castbar.max - duration)
	elseif castbar.channeling then
		castbar.Time:SetFormattedText("%.1f", duration)
	end
end

local castbar = function(self, unit)
	if (unit == "target" or unit == "player" or unit == "focus") then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(texture, "OVERLAY")
		fixStatusbar(cb)
		cb:SetStatusBarColor(1, .25, .35, .5)
		cb:SetParent(self)
		cb:SetHeight(16)
		cb:SetWidth(150)
		cb:SetToplevel(true)
		
		cb.Spark = cb:CreateTexture(nil, "OVERLAY")
		cb.Spark:SetBlendMode("ADD")
		cb.Spark:SetAlpha(0.5)
		cb.Spark:SetHeight(48)
		
		local cbbg = cb:CreateTexture(nil, "BACKGROUND")
		cbbg:SetAllPoints(cb)
		cbbg:SetTexture(texture)
		cbbg:SetVertexColor(.1,.1,.1)
		
		cb.Time = cb:CreateFontString(nil, 'OVERLAY')
		cb.Time:SetFont(font, fontsize)
		cb.Time:SetShadowOffset(1, -1)
		cb.Time:SetPoint("RIGHT", cb, -2, 0)
		cb.CustomTimeText = CustomTimeText

		cb.Text = cb:CreateFontString(nil, "OVERLAY")
		cb.Text:SetFont(font, fontsize)
		cb.Text:SetShadowOffset(1, -1)
		cb.Text:SetPoint("LEFT", cb, 2, 0)
		cb.Text:SetPoint("RIGHT", cb.Time, "LEFT")
		cb.Text:SetJustifyH"LEFT"
		
		cb.Icon = cb:CreateTexture(nil, 'ARTWORK')
		cb.Icon:SetHeight(28)
		cb.Icon:SetWidth(28)
		cb.Icon:SetTexCoord(.1, .9, .1, .9)
		
		if (unit == "player") then
			cb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
			cb.Icon:SetPoint("TOPLEFT", cb, "TOPRIGHT", 7, 0)
			
			cb.SafeZone = cb:CreateTexture(nil,'ARTWORK')
			cb.SafeZone:SetPoint('TOPRIGHT')
			cb.SafeZone:SetPoint('BOTTOMRIGHT')
			cb.SafeZone:SetTexture(texture)
			cb.SafeZone:SetVertexColor(.9,.7,0, 1)
		else
			cb:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -10)
			cb.Icon:SetPoint("TOPRIGHT", cb, "TOPLEFT", -7, 0)
		end
		
		if (unit == 'target') then
			cb.PostCastStart = PostCastStart
			cb.PostChannelStart = PostCastStart
		end
		
		cb.Backdrop = CreateFrame("Frame", nil, cb)
		cb.Backdrop:SetPoint("TOPLEFT", cb, "TOPLEFT", -4, 4)
		cb.Backdrop:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 4, -4)
		cb.Backdrop:SetFrameStrata("LOW")
		cb.Backdrop:SetBackdrop(frameBD)
		cb.Backdrop:SetBackdropColor(0, 0, 0, 0)
		cb.Backdrop:SetBackdropBorderColor(0, 0, 0)
		
		cb.IBackdrop = CreateFrame("Frame", nil, cb)
		cb.IBackdrop:SetPoint("TOPLEFT", cb.Icon, "TOPLEFT", -4, 4)
		cb.IBackdrop:SetPoint("BOTTOMRIGHT", cb.Icon, "BOTTOMRIGHT", 4, -4)
		cb.IBackdrop:SetFrameStrata("LOW")
		cb.IBackdrop:SetBackdrop(frameBD)
		cb.IBackdrop:SetBackdropColor(0, 0, 0, 0)
		cb.IBackdrop:SetBackdropBorderColor(0, 0, 0)
		
		cb.bg = cbbg
		self.Castbar = cb
	end
end

local UnitSpecific = {
	player = function(self)
		if portraits then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetWidth(60)
			self.Portrait:SetHeight(40)
			self.Portrait:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -10)
			self.PorBackdrop = CreateFrame("Frame", nil, self)
			self.PorBackdrop:SetPoint("TOPLEFT", self.Portrait, "TOPLEFT", -4, 4)
			self.PorBackdrop:SetPoint("BOTTOMRIGHT", self.Portrait, "BOTTOMRIGHT", 4, -4)
			self.PorBackdrop:SetFrameStrata("LOW")
			self.PorBackdrop:SetBackdrop(frameBD)
			self.PorBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.PorBackdrop:SetBackdropBorderColor(0, 0, 0)
		end

		local ppp = self.Health:CreateFontString(nil, "OVERLAY")
		ppp:SetPoint("LEFT", 2, 0)
		ppp:SetFont(font, fontsize)
		ppp:SetShadowOffset(1, -1)
		ppp:SetTextColor(1, 1, 1)
		self:Tag(ppp, '[freeb:pp]')
			
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
			fixStatusbar(bar)
			bar:SetBackdrop(backdrop)
			bar:SetBackdropColor(.05, .05, .05, 1)
			bar:SetFrameLevel(2)
			bar.bd = CreateFrame("Frame", nil, bar)
			bar.bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -4, 4)
			bar.bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -4)
			bar.bd:SetFrameStrata("LOW")
			bar.bd:SetBackdrop(frameBD)
			bar.bd:SetBackdropColor(0, 0, 0, 0)
			bar.bd:SetBackdropBorderColor(0, 0, 0)
			runes[i] = bar
		end
		self.Runes = runes
		
		local _, class = UnitClass("player")
		if IsAddOnLoaded("oUF_TotemBar") and class == "SHAMAN" then
			self.TotemBar = {}
			self.TotemBar.Destroy = true
			for i = 1, 4 do
				self.TotemBar[i] = CreateFrame("StatusBar", nil, self)
				self.TotemBar[i]:SetHeight(16)
				self.TotemBar[i]:SetWidth(150/4 - 5)
				if (i == 1) then
					self.TotemBar[i]:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -33)
				else
					self.TotemBar[i]:SetPoint("RIGHT", self.TotemBar[i-1], "LEFT", -5, 0)
				end
				self.TotemBar[i]:SetStatusBarTexture(texture)
				fixStatusbar(self.TotemBar[i])
				self.TotemBar[i]:SetBackdrop(backdrop)
				self.TotemBar[i]:SetBackdropColor(0.5, 0.5, 0.5)
				self.TotemBar[i]:SetMinMaxValues(0, 1)
				
				self.TotemBar[i].bg = self.TotemBar[i]:CreateTexture(nil, "BORDER")
				self.TotemBar[i].bg:SetAllPoints(self.TotemBar[i])
				self.TotemBar[i].bg:SetTexture(texture)
				self.TotemBar[i].bg.multiplier = 0.3
				
				self.TotemBar[i].bd = CreateFrame("Frame", nil, self)
				self.TotemBar[i].bd:SetPoint("TOPLEFT", self.TotemBar[i], "TOPLEFT", -4, 4)
				self.TotemBar[i].bd:SetPoint("BOTTOMRIGHT", self.TotemBar[i], "BOTTOMRIGHT", 4, -4)
				self.TotemBar[i].bd:SetFrameStrata("LOW")
				self.TotemBar[i].bd:SetBackdrop(frameBD)
				self.TotemBar[i].bd:SetBackdropColor(0, 0, 0, 0)
				self.TotemBar[i].bd:SetBackdropBorderColor(0, 0, 0)
			end
		end
		
		if(IsAddOnLoaded('oUF_Experience')) then
			self.Experience = CreateFrame('StatusBar', nil, self)
			self.Experience:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -2)
			self.Experience:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -2)
			self.Experience:SetHeight(4)
			self.Experience:SetStatusBarTexture(texture)
			fixStatusbar(self.Experience)
			self.Experience:SetStatusBarColor(0, 0.7, 1)
			self.Experience.Tooltip = true

			self.Experience.Rested = CreateFrame('StatusBar', nil, self)
			self.Experience.Rested:SetAllPoints(self.Experience)
			self.Experience.Rested:SetStatusBarTexture(texture)
			fixStatusbar(self.Experience.Rested)
			self.Experience.Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
			self.Experience.Rested:SetBackdrop(backdrop)
			self.Experience.Rested:SetBackdropColor(0, 0, 0)

			self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BORDER')
			self.Experience.bg:SetAllPoints(self.Experience)
			self.Experience.bg:SetTexture(texture)
			self.Experience.bg:SetVertexColor(.1, .1, .1)
			
			self.Experience.bd = CreateFrame("Frame", nil, self.Experience)
			self.Experience.bd:SetPoint("TOPLEFT", self.Experience, "TOPLEFT", -4, 4)
			self.Experience.bd:SetPoint("BOTTOMRIGHT", self.Experience, "BOTTOMRIGHT", 4, -4)
			self.Experience.bd:SetFrameStrata("LOW")
			self.Experience.bd:SetBackdrop(frameBD)
			self.Experience.bd:SetBackdropColor(0, 0, 0, 0)
			self.Experience.bd:SetBackdropBorderColor(0, 0, 0)
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

			self.Debuffs = debuffs
			self.Debuffs.num = 5 
		end
	end,
		
	target = function(self)
		if portraits then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetWidth(60)
			self.Portrait:SetHeight(40)
			self.Portrait:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
			self.PorBackdrop = CreateFrame("Frame", nil, self)
			self.PorBackdrop:SetPoint("TOPLEFT", self.Portrait, "TOPLEFT", -4, 4)
			self.PorBackdrop:SetPoint("BOTTOMRIGHT", self.Portrait, "BOTTOMRIGHT", 4, -4)
			self.PorBackdrop:SetFrameStrata("LOW")
			self.PorBackdrop:SetBackdrop(frameBD)
			self.PorBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.PorBackdrop:SetBackdropBorderColor(0, 0, 0)
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
			
			debuffs.PostCreateIcon = auraIcon
			debuffs.PostUpdateIcon = PostUpdateIcon
		
			self.Debuffs = debuffs
			self.Debuffs.num = 32
		end
		
		local cpoints = self:CreateFontString(nil, 'OVERLAY')
		cpoints:SetPoint('RIGHT', self, 'LEFT', -4, 0)
		cpoints:SetFont(font, 24, "THINOUTLINE")
		cpoints:SetShadowOffset(1, -1)
		cpoints:SetTextColor(1, 0, 0)
		self:Tag(cpoints, '[cpoints]')

		--[[local CPoints = {}
		for index = 1, MAX_COMBO_POINTS do
			local CPoint = self:CreateTexture(nil, 'BACKGROUND')
			CPoint:SetSize(12, 16)
			CPoint:SetVertexColor(1,1,0)

			CPoint:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', -(index) * CPoint:GetWidth(), 0)
			
			if(index == 4) then CPoint:SetVertexColor(1,.6,0) end
			if(index == 5) then CPoint:SetVertexColor(1,0,0) end
			
			CPoints[index] = CPoint
		end
		self.CPoints = CPoints]]
	end,

	focus = function(self)
		if portraits then
			self.Portrait = CreateFrame("PlayerModel", nil, self)
			self.Portrait:SetWidth(60)
			self.Portrait:SetHeight(40)
			self.Portrait:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -10)
			self.PorBackdrop = CreateFrame("Frame", nil, self)
			self.PorBackdrop:SetPoint("TOPLEFT", self.Portrait, "TOPLEFT", -4, 4)
			self.PorBackdrop:SetPoint("BOTTOMRIGHT", self.Portrait, "BOTTOMRIGHT", 4, -4)
			self.PorBackdrop:SetFrameStrata("LOW")
			self.PorBackdrop:SetBackdrop(frameBD)
			self.PorBackdrop:SetBackdropColor(0, 0, 0, 0)
			self.PorBackdrop:SetBackdropBorderColor(0, 0, 0)
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
		end
	end,

	pet = function(self)
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

	targettarget = function(self)
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
			self.Debuffs.num = 5 
		end
	end,
}

local func = function(self, unit)
	self.menu = menu
	
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

	local hp = CreateFrame"StatusBar"
	if(unit and (unit == "targettarget")) then
		hp:SetHeight(height)
	else
		hp:SetHeight(height*.89)
	end
	hp:SetStatusBarTexture(texture)
	fixStatusbar(hp)
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

	if classColorbars then
		hp.PostUpdate = updateHealth
		hpbg:SetVertexColor(.15,.15,.15)
	else
		hpbg:SetVertexColor(.3,.3,.3)
	end

	if not (unit == "targettarget") then
		local hpp = hp:CreateFontString(nil, "OVERLAY")
		hpp:SetPoint("RIGHT", hp, -2, 0)
		hpp:SetFont(font, fontsize)
		hpp:SetShadowOffset(1, -1)
		hpp:SetTextColor(1, 1, 1)
		self:Tag(hpp, '[freeb:hp]')
	end

	hp.bg = hpbg
	self.Health = hp

	if not (unit == "targettarget") then
		local pp = CreateFrame"StatusBar"
		pp:SetHeight(height*.06)
		pp:SetStatusBarTexture(texture)
		fixStatusbar(pp)
		pp:SetStatusBarColor(1, 1, 1)

		pp.frequentUpdates = true
		pp.Smooth = true

		pp:SetParent(self)
		pp:SetPoint"LEFT"
		pp:SetPoint"RIGHT"
		pp:SetPoint"BOTTOM"	
		
		local ppbg = pp:CreateTexture(nil, "BORDER")
		ppbg:SetAllPoints(pp)
		ppbg:SetTexture(texture)
		ppbg:SetVertexColor(.3,.3,.3)

		pp.bg = ppbg
		self.Power = pp
	end

	if healtext then
		local heal = hp:CreateFontString(nil, "OVERLAY")
		heal:SetPoint("CENTER")
		heal:SetJustifyH("CENTER")
		heal:SetFont(font, fontsize)
		heal:SetShadowOffset(1.25, -1.25)
		heal:SetTextColor(0,1,0,1)

		self.HealCommText = heal
	end

	if healbar then
		self.HealCommBar = CreateFrame('StatusBar', nil, hp)
		self.HealCommBar:SetHeight(0)
		self.HealCommBar:SetWidth(0)	
		self.HealCommBar:SetStatusBarTexture(texture)
		fixStatusbar(self.HealCommBar)
		self.HealCommBar:SetStatusBarColor(0, 1, 0, 0.4)
		self.HealCommBar:SetPoint('LEFT', hp, 'LEFT')
		self.allowHealCommOverflow = true
	end

	local leader = hp:CreateTexture(nil, "OVERLAY")
	leader:SetSize(16, 16)
	leader:SetPoint("BOTTOMRIGHT", hp, "TOPLEFT", 10, -6)
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
	Resting:SetPoint('TOP', Combat, 'BOTTOM', 8, 0)
	self.Resting = Resting

	if not (unit == "player") then
		local name = hp:CreateFontString(nil, "OVERLAY")
		if(unit == "targettarget") then
			name:SetPoint("LEFT", hp)
			name:SetPoint("RIGHT", hp)
		else
			name:SetPoint("LEFT", hp, 2, 0)
			name:SetPoint("RIGHT", hp, -55, 0)
			name:SetJustifyH"LEFT"
		end
		name:SetFont(font, fontsize)
		name:SetShadowOffset(1, -1)
		name:SetTextColor(1, 1, 1)
		
		if classColorbars then
			if(unit == "targettarget") then
				self:Tag(name, '[freeb:name]')
			else
				self:Tag(name, '[freeb:name] [freeb:info]')
			end
		else
			if(unit == "targettarget") then
				self:Tag(name, '[freeb:color][freeb:name]')
			else
				self:Tag(name, '[freeb:color][freeb:name] [freeb:info]')
			end
		end
	end
	
	local ricon = hp:CreateTexture(nil, 'OVERLAY')
	ricon:SetPoint("BOTTOM", hp, "TOP", 0, -7)
	ricon:SetSize(14, 14)
	self.RaidIcon = ricon

	if castbars then
		castbar(self, unit)
	end

	self:SetAttribute('initial-height', height)
	if(unit and (unit == "targettarget")) then
		self:SetAttribute('initial-width', 150)
	else
		self:SetAttribute('initial-width', width)
	end

	self.disallowVehicleSwap = true
	
	self:SetAttribute('initial-scale', scale)

	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

oUF:RegisterStyle("Freeb", func)

oUF:Factory(function(self)
	self:SetActiveStyle"Freeb"

	self:Spawn"player":SetPoint("CENTER", -234, -192)
	self:Spawn"target":SetPoint("CENTER", 234, -192)
	self:Spawn"targettarget":SetPoint("CENTER", 0, -192)
	self:Spawn"focus":SetPoint("CENTER", 500, 0)
	self:Spawn"focustarget":SetPoint("RIGHT", self.units.focus, "LEFT", -10, 0)
	self:Spawn"pet":SetPoint("RIGHT", self.units.player, "LEFT", -10, 0)

	if bossframes then
		local boss = {}
		for i = 1, MAX_BOSS_FRAMES do
			local unit = self:Spawn("boss"..i, "oUF_FreebBoss"..i)

			if i==1 then
				unit:SetPoint("CENTER", 500, 200)
			else
				unit:SetPoint("TOPLEFT", boss[i-1], "BOTTOMLEFT", 0, -10)
			end
			boss[i] = unit
		end
	end
end)