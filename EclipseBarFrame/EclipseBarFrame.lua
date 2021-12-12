local ECLIPSE_BAR_SOLAR_BUFF_ID = 48517
local ECLIPSE_BAR_LUNAR_BUFF_ID = 48518

local ECLIPSE_ICONS = {
	moon = {
		norm = {x = 23, y = 23, left = 0.55859375, right = 0.64843750, top = 0.57031250, bottom = 0.75000000},
		dark = {x = 23, y = 23, left = 0.55859375, right = 0.64843750, top = 0.37500000, bottom = 0.55468750},
		big = {x = 43, y = 45, left = 0.73437500, right = 0.90234375, top = 0.00781250, bottom = 0.35937500}
	},
	sun = {
		norm = {x = 23, y = 23, left = 0.65625000, right = 0.74609375, top = 0.37500000, bottom = 0.55468750},
		dark = {x = 23, y = 23, left = 0.55859375, right = 0.64843750, top = 0.76562500, bottom = 0.94531250},
		big = {x = 43, y = 45, left = 0.55859375, right = 0.72656250, top = 0.00781250, bottom = 0.35937500}
	}
}

local ECLIPSE_MARKER_COORDS = {}
ECLIPSE_MARKER_COORDS["none"] = {0.914, 1.0, 0.82, 1.0}
ECLIPSE_MARKER_COORDS["sun"] = {1.0, 0.914, 0.641, 0.82}
ECLIPSE_MARKER_COORDS["moon"] = {0.914, 1.0, 0.641, 0.82}

local playerName = UnitName("player")
local playerClass = select(2, UnitClass("player"))
local moonkinForm

local function GetSpecialization(isInspect, isPet, specGroup)
	local currentSpecGroup = GetActiveTalentGroup(isInspect, isPet) or (specGroup or 1)
	local maxPoints, currentSpecId = 0, nil

	for i = 1, MAX_TALENT_TABS do
		local name, _, pointsSpent = GetTalentTabInfo(i, isInspect, isPet, currentSpecGroup)
		if maxPoints <= pointsSpent then
			maxPoints = pointsSpent
			currentSpecId = i
		end
	end
	return currentSpecId
end

function EclipseBar_UpdateShown(self)
	if VehicleMenuBar:IsShown() then
		return
	end

	if playerClass == "DRUID" and moonkinForm then
		self:Show()
	else
		self:Hide()
	end
end

function EclipseBar_Update(self, elapsed)
	local xPos = 0
	if self.hasLunarEclipse then
		xPos = -38 * (self.eclipseDuration / 15)
	elseif self.hasSolarEclipse then
		xPos = 38 * (self.eclipseDuration / 15)
	else
		xPos = 0
	end
	self.marker:SetPoint("CENTER", xPos, 0)
end

function EclipseBar_OnLoad(self)
	-- add elements
	local fname = self:GetName()

	self.sun = _G[fname .. "Sun"]
	self.sunBar = _G[fname .. "SunBar"]
	self.darkSun = _G[fname .. "DarkSun"]
	self.sunActivate = _G[fname .. "SunActivate"]
	self.sunDeactivate = _G[fname .. "SunDeactivate"]

	self.moon = _G[fname .. "Moon"]
	self.moonBar = _G[fname .. "MoonBar"]
	self.darkMoon = _G[fname .. "DarkMoon"]
	self.moonActivate = _G[fname .. "MoonActivate"]
	self.moonDeactivate = _G[fname .. "MoonDeactivate"]

	self.glow = _G[fname .. "Glow"]
	self.glow.pulse = _G[fname .. "GlowPulse"]
	self.marker = _G[fname .. "Marker"]

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function EclipseBar_OnShow(self)
	self.marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS["none"]))

	local hasLunarEclipse = false
	local hasSolarEclipse = false
	local duration = 0

	local unit = PlayerFrame.unit
	local j = 1
	local name, _, _, _, _, _, expires, _, _, _, spellID = UnitBuff(unit, j)
	while name do
		if spellID == ECLIPSE_BAR_SOLAR_BUFF_ID then
			hasSolarEclipse = true
			duration = floor(expires - GetTime())
		elseif spellID == ECLIPSE_BAR_LUNAR_BUFF_ID then
			hasLunarEclipse = true
			duration = floor(expires - GetTime())
		end
		j = j + 1
		name, _, _, _, _, _, expires, _, _, _, spellID = UnitBuff(unit, j)
	end

	self.glow:ClearAllPoints()

	if hasLunarEclipse then
		local glowInfo = ECLIPSE_ICONS["moon"].big
		self.glow:SetPoint("CENTER", self.moon, "CENTER", 0, 0)
		self.glow:SetWidth(glowInfo.x)
		self.glow:SetHeight(glowInfo.y)
		self.glow:SetTexCoord(glowInfo.left, glowInfo.right, glowInfo.top, glowInfo.bottom)
		self.sunBar:Hide()
		self.darkMoon:Hide()
		self.moonBar:Show()
		self.darkSun:Show()
		self.glow:Show()
		self.glow.pulse:Play()
		self.eclipseDuration = duration
	elseif hasSolarEclipse then
		local glowInfo = ECLIPSE_ICONS["sun"].big
		self.glow:SetPoint("CENTER", self.sun, "CENTER", 0, 0)
		self.glow:SetWidth(glowInfo.x)
		self.glow:SetHeight(glowInfo.y)
		self.glow:SetTexCoord(glowInfo.left, glowInfo.right, glowInfo.top, glowInfo.bottom)
		self.sunBar:Show()
		self.darkMoon:Show()
		self.moonBar:Hide()
		self.darkSun:Hide()
		self.glow:Show()
		self.glow.pulse:Play()
		self.eclipseDuration = duration
	else
		self.sunBar:Hide()
		self.darkMoon:Hide()
		self.moonBar:Hide()
		self.darkSun:Hide()
		self.glow:SetPoint("CENTER", self, "CENTER", 0, 0)
		self.glow:Hide()
		self.eclipseDuration = 0
	end

	self.hasLunarEclipse = hasLunarEclipse
	self.hasSolarEclipse = hasSolarEclipse

	EclipseBar_Update(self)
end

function EclipseBar_CheckBuffs(self)
	if not self:IsShown() then
		return
	end

	local hasLunarEclipse = false
	local hasSolarEclipse = false
	local duration = 0

	local unit = PlayerFrame.unit
	local j = 1
	local name, _, _, _, _, _, expires, _, _, _, spellID = UnitBuff(unit, j)
	while name do
		if spellID == ECLIPSE_BAR_SOLAR_BUFF_ID then
			hasSolarEclipse = true
			duration = floor(expires - GetTime())
		elseif spellID == ECLIPSE_BAR_LUNAR_BUFF_ID then
			hasLunarEclipse = true
			duration = floor(expires - GetTime())
		end
		j = j + 1
		name, _, _, _, _, _, expires, _, _, _, spellID = UnitBuff(unit, j)
	end

	self.eclipseDuration = 0

	if hasLunarEclipse then
		self.glow:ClearAllPoints()
		local glowInfo = ECLIPSE_ICONS["moon"].big
		self.glow:SetPoint("CENTER", self.moon, "CENTER", 0, 0)
		self.glow:SetWidth(glowInfo.x)
		self.glow:SetHeight(glowInfo.y)
		self.glow:SetTexCoord(glowInfo.left, glowInfo.right, glowInfo.top, glowInfo.bottom)

		if self.moonDeactivate:IsPlaying() then
			self.moonDeactivate:Stop()
		end

		if not self.moonActivate:IsPlaying() and hasLunarEclipse ~= self.hasLunarEclipse then
			self.moonActivate:Play()
		end

		self.eclipseDuration = duration
	else
		if self.moonActivate:IsPlaying() then
			self.moonActivate:Stop()
		end

		if not self.moonDeactivate:IsPlaying() and hasLunarEclipse ~= self.hasLunarEclipse then
			self.moonDeactivate:Play()
		end
	end

	if hasSolarEclipse then
		self.glow:ClearAllPoints()
		local glowInfo = ECLIPSE_ICONS["sun"].big
		self.glow:SetPoint("CENTER", self.sun, "CENTER", 0, 0)
		self.glow:SetWidth(glowInfo.x)
		self.glow:SetHeight(glowInfo.y)
		self.glow:SetTexCoord(glowInfo.left, glowInfo.right, glowInfo.top, glowInfo.bottom)

		if self.sunDeactivate:IsPlaying() then
			self.sunDeactivate:Stop()
		end

		if not self.sunActivate:IsPlaying() and hasSolarEclipse ~= self.hasSolarEclipse then
			self.sunActivate:Play()
		end

		self.eclipseDuration = duration
	else
		if self.sunActivate:IsPlaying() then
			self.sunActivate:Stop()
		end

		if not self.sunDeactivate:IsPlaying() and hasSolarEclipse ~= self.hasSolarEclipse then
			self.sunDeactivate:Play()
		end
	end

	self.hasLunarEclipse = hasLunarEclipse
	self.hasSolarEclipse = hasSolarEclipse
end

local firstLoad = nil
function EclipseBar_OnEvent(self, event, ...)
	if event == "UNIT_AURA" then
		-- upon login...
		if not firstLoad then
			moonkinForm = (UnitBuff("player", GetSpellInfo(24858)) ~= nil)
			EclipseBar_UpdateShown(self)
			firstLoad = true
		end

		local arg1 = ...
		if arg1 == PlayerFrame.unit then
			EclipseBar_CheckBuffs(self)
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, eventtype, _, _, _, _, target, _, spellID = ...
		if
			eventtype == "SPELL_AURA_APPLIED" and
			target == playerName and
			(spellID == ECLIPSE_BAR_SOLAR_BUFF_ID or spellID == ECLIPSE_BAR_LUNAR_BUFF_ID)
		then
			local status = (spellID == ECLIPSE_BAR_SOLAR_BUFF_ID) and "sun" or "moon"
			self.marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[status]))
		elseif
			eventtype == "SPELL_AURA_REMOVED" and
			target == playerName and
			(spellID == ECLIPSE_BAR_SOLAR_BUFF_ID or spellID == ECLIPSE_BAR_LUNAR_BUFF_ID)
		then
			self.marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS["none"]))
		end
	else
		moonkinForm = (UnitBuff("player", GetSpellInfo(24858)) ~= nil)
		EclipseBar_UpdateShown(self)
	end
end