local ADDON_NAME, ns = ...

if(freebDebug) then
	ns.Debug = function(...)
		freebDebug:Stuff(ADDON_NAME, ...)
	end
else
	ns.Debug = function() end
end

ns.mediapath = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\"
ns.statusbar = ns.mediapath.."statusbar"
ns.font = ns.mediapath.."font.ttf"

ns.FreebFont = CreateFont"FreebFont"
ns.FreebFont:SetFont(ns.font, 12, "THINOUTLINE")
ns.FreebFont:SetShadowOffset(1, -1)
ns.FreebFont:SetTextColor(1, 1, 1)

ns.FreebFontSmall = CreateFont"FreebFontSmall"
ns.FreebFontSmall:SetFont(ns.font, 10, "THINOUTLINE")
ns.FreebFontSmall:SetShadowOffset(1, -1)
ns.FreebFontSmall:SetTextColor(1, 1, 1)

ns.colors = setmetatable({
	power = setmetatable({
		["MANA"] = {.31, .45, .63}
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

function ns.numberize(val)
	if(val >= 1e6) then
		return ("%.1fm"):format(val / 1e6)
	elseif(val >= 1e3) then
		return ("%.0fk"):format(val / 1e3)
	else
		return ("%d"):format(val)
	end
end

function ns.formatTime(val)
	if(val > 3600) then
		return ("%dh"):format((val / 3600) + 0.5)
	elseif(val > 60) then
		return ("%dm"):format((val / 60) + 0.5)
	else
		return ("%.0f"):format(val)
	end
end

function ns.multiCheck(check, ...)
	for i=1, select("#", ...) do
		if(check == select(i, ...)) then return true end
	end
	return false
end

function ns.unitColor(unit)
	local colors

	if(UnitPlayerControlled(unit)) then
		local _, class = UnitClass(unit)
		if(class and UnitIsPlayer(unit)) then
			-- Players have color
			colors = ns.colors.class[class]
		elseif(UnitCanAttack(unit, "player")) then
			-- Hostiles are red
			colors = ns.colors.reaction[2]
		elseif(UnitCanAttack("player", unit)) then
			-- Units we can attack but which are not hostile are yellow
			colors = ns.colors.reaction[4]
		elseif(UnitIsPVP(unit)) then
			-- Units we can assist but are PvP flagged are green
			colors = ns.colors.reaction[6]
		end
	elseif(UnitIsTapDenied(unit, "player")) then
		colors = ns.colors.tapped
	end

	if(not colors) then
		local reaction = UnitReaction(unit, "player")
		colors = reaction and ns.colors.reaction[reaction]
	end

	return colors[1], colors[2], colors[3]
end

do
	local glowBorder = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = ns.mediapath.."glowTex", edgeSize = 3,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	}

	function ns.createBackdrop(parent, anchor)
		local frame = CreateFrame("Frame", nil, parent)
		frame:SetFrameStrata("LOW")
		frame:SetPoint("TOPLEFT", anchor or parent, "TOPLEFT", -3, 3)
		frame:SetPoint("BOTTOMRIGHT", anchor or parent, "BOTTOMRIGHT", 3, -3)
		frame:SetBackdrop(glowBorder)
		frame:SetBackdropColor(.05, .05, .05, 1)
		--frame:SetBackdropColor(.5, .5, .5, 1)
		frame:SetBackdropBorderColor(0, 0, 0, 1)
		return frame
	end
end

do
	local bnot, band = bit.bnot, bit.band
	local flags = {}
	for i=0, 7 do
		flags[i] = bit.lshift(1, i)
	end

	local methods = {
		Hide = function(self)
			if(not self.__visible) then return end

			for i=1,8 do
				self[i]:Hide()
			end

			self.__visible = nil
		end,

		Show = function(self)
			if(self.__visible) then return end

			for i=1,8 do
				self[i]:Show()
			end

			self.__visible = true
		end,

		SetColor = function(self, r, g, b, a)
			if(not a) then a = 1 end
			if(r == self.__r and g == self.__g and b == self.__b and a == self.__a) then
				return
			end

			for i=1,8 do
				self[i]:SetVertexColor(r, g, b, a)
			end

			self.__r, self.__g, self.__b, self.__a = r, g, b, a
		end,

		SetParent = function(self, parent)
			self.__parent = parent
		end,

		SetVisible = function(self, left, right, top, bottom)
			local mask = 0xff
			if(not left) then
				mask = mask - flags[0]
				mask = band(mask, bnot(flags[1]))
				mask = band(mask, bnot(flags[7]))
			end

			if(not right) then
				mask = mask - flags[4]
				mask = band(mask, bnot(flags[3]))
				mask = band(mask, bnot(flags[5]))
			end

			if(not top) then
				mask = mask - flags[2]
				mask = band(mask, bnot(flags[1]))
				mask = band(mask, bnot(flags[3]))
			end

			if(not bottom) then
				mask = mask - flags[6]
				mask = band(mask, bnot(flags[7]))
				mask = band(mask, bnot(flags[5]))
			end

			for i=0, 7 do
				if(band(mask, flags[i]) ~= 0) then
					self[i + 1]:Show()
				else
					self[i + 1]:Hide()
				end
			end
		end,

		SetPoint = function(self, point)
			point = point or self.__parent

			for i=1, 8 do
				self[i]:ClearAllPoints()
			end

			local Left = self[1]
			Left:SetPoint('RIGHT', point, 'LEFT')
			Left:SetPoint('TOP')
			Left:SetPoint('BOTTOM')
			Left:SetWidth(16)

			local TopLeft = self[2]
			TopLeft:SetPoint('BOTTOMRIGHT', point, 'TOPLEFT')
			TopLeft:SetSize(16, 16)

			local Top = self[3]
			Top:SetPoint('BOTTOM', point, 'TOP')
			Top:SetPoint('LEFT')
			Top:SetPoint('RIGHT')
			Top:SetHeight(16)

			local TopRight = self[4]
			TopRight:SetPoint('BOTTOMLEFT', point, 'TOPRIGHT')
			TopRight:SetSize(16, 16)

			local Right = self[5]
			Right:SetPoint('LEFT', point, 'RIGHT')
			Right:SetPoint('TOP')
			Right:SetPoint('BOTTOM')
			Right:SetWidth(16)

			local BottomRight = self[6]
			BottomRight:SetPoint('TOPLEFT', point, 'BOTTOMRIGHT')
			BottomRight:SetSize(16, 16)

			local Bottom = self[7]
			Bottom:SetPoint('TOP', point, 'BOTTOM')
			Bottom:SetPoint('LEFT')
			Bottom:SetPoint('RIGHT')
			Bottom:SetHeight(16)

			local BottomLeft = self[8]
			BottomLeft:SetPoint('TOPRIGHT', point, 'BOTTOMLEFT')
			BottomLeft:SetSize(16, 16)
		end
	}
	methods.__index = methods

	function ns.createBorder(self, texture)
		local Border = setmetatable({
			__visible = true,
		}, methods)

		for i=1,8 do
			local T = self:CreateTexture(nil, 'BORDER')
			T:SetTexture(texture)
			Border[i] = T
		end

		local Left = Border[1]
		Left:SetTexCoord(0/8, 1/8, 0/8, 8/8)

		local TopLeft = Border[2]
		TopLeft:SetTexCoord(6/8, 7/8, 8/8, 0/8)

		local Top = Border[3]
		Top:SetTexCoord(.5, -.75, .375, -.75, .5, -.625, .375, -.625)

		local TopRight = Border[4]
		TopRight:SetTexCoord(7/8, 6/8, 8/8, 0/8)

		local Right = Border[5]
		Right:SetTexCoord(1/8, 0/8, 0/8, 8/8)

		local BottomRight = Border[6]
		BottomRight:SetTexCoord(5/8, 6/8, 8/8, 0/8)

		local Bottom = Border[7]
		Bottom:SetTexCoord(.375, 1, .5, 1, .375, 0, .5, 0)

		local BottomLeft = Border[8]
		BottomLeft:SetTexCoord(6/8, 5/8, 8/8, 0/8)

		Border:SetParent(self)
		Border:SetPoint()
		Border:SetColor(0, 0, 0, 0)

		self.Border = Border
		return Border
	end
end

do
	local function Smooth(self, value)
		if(value == 0) then value = 0.01 end

		if(value == self:GetValue()) then
			self.smoothing = nil
		else
			self.smoothing = value
		end
	end

	local GetFramerate = GetFramerate
	local min, max, abs = math.min, math.max, abs
	local function SmoothUpdate(self)
		local value = self.smoothing
		if(not value) then return end

		local limit = 30/GetFramerate()
		local cur = self:GetValue()
		local new = cur + min((value-cur)/3, max(value-cur, limit))

		if(new ~= new) then
			new = value
		end

		self:SetValue_(new)
		if(cur == value or abs(new - value) < 2) then
			self:SetValue_(value)
			self.smoothing = nil
		end
	end

	local SetValue = CreateFrame("StatusBar").SetValue
	function ns.sbSmooth(statusbar)
		statusbar.SetValue_ = SetValue
		statusbar.SetValue = Smooth
		statusbar:SetScript("OnUpdate", SmoothUpdate)
	end
end
