local addonName, ns = ...

local defaults = {
	enabled = true,
	position = "right",
	size = 12,
	color = { r = 1, g = 0.8, b = 0 },
	showOutOfCombat = false,
}

local byPlate = {}
local byUnit = {}
local inCombat = false

local function applyDefaults(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then target[key] = {} end
			applyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

local function validateDB(db)
	if db.position ~= "left" and db.position ~= "above" and db.position ~= "below" then
		db.position = "right"
	end

	db.size = tonumber(db.size) or 12
	if db.size < 8 then
		db.size = 8
	elseif db.size > 32 then
		db.size = 32
	end

	db.enabled = db.enabled ~= false
	db.showOutOfCombat = db.showOutOfCombat == true

	local color = db.color
	if type(color) ~= "table" or type(color.r) ~= "number"
		or type(color.g) ~= "number" or type(color.b) ~= "number" then
		db.color = { r = 1, g = 0.8, b = 0 }
	else
		color.r = math.max(0, math.min(1, color.r))
		color.g = math.max(0, math.min(1, color.g))
		color.b = math.max(0, math.min(1, color.b))
	end
end

function ns.InitDB()
	if type(_G.HunTankDB) ~= "table" then
		_G.HunTankDB = {}
	end
	ns.db = _G.HunTankDB
	applyDefaults(ns.db, defaults)
	validateDB(ns.db)
end

local function config()
	return ns.db or defaults
end

function ns.Print(message)
	print("|cff33d6ffHunTank|r: " .. tostring(message))
end

local function blank(holder)
	if holder and holder.text then
		holder.text:SetText("")
	end
end

local function healthBarFor(plate)
	local unitFrame = plate.UnitFrame
	if not unitFrame then return nil end
	return unitFrame.healthBar
		or (unitFrame.HealthBarsContainer and unitFrame.HealthBarsContainer.healthBar)
end

local function layout(holder)
	local db = config()
	local text = holder.text
	local plate = holder.plate
	local healthBar = healthBarFor(plate)
	local anchor = healthBar or plate
	holder.healthBar = healthBar

	text:ClearAllPoints()
	if db.position == "left" then
		text:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
	elseif db.position == "above" then
		text:SetPoint("BOTTOM", plate, "TOP", 0, 2)
	elseif db.position == "below" then
		text:SetPoint("TOP", plate, "BOTTOM", 0, -2)
	else
		text:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
	end

	local font = STANDARD_TEXT_FONT
	local path = GameFontNormalSmall:GetFont()
	if path then font = path end
	text:SetFont(font, tonumber(db.size) or 12, "OUTLINE")

	local color = db.color or defaults.color
	text:SetTextColor(color.r or 1, color.g or 0.8, color.b or 0)
end

local function holderFor(plate)
	local holder = byPlate[plate]
	if holder then return holder end

	local text = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")

	holder = { plate = plate, text = text }
	byPlate[plate] = holder
	layout(holder)
	return holder
end

local function updatePlate(plate, unit)
	local holder = holderFor(plate)
	holder.unit = unit
	byUnit[unit] = holder

	local healthBar = healthBarFor(plate)
	if holder.healthBar ~= healthBar then
		layout(holder)
	end

	local db = config()
	if not db.enabled then
		blank(holder)
		return
	end
	if not db.showOutOfCombat and not inCombat then
		blank(holder)
		return
	end

	local ok, isTanking, status, scaled = pcall(UnitDetailedThreatSituation, "player", unit)
	if not ok or scaled == nil then
		blank(holder)
		return
	end

	holder.text:SetText("")
	local shown = pcall(holder.text.SetFormattedText, holder.text, "%.0f%%", scaled)
	if not shown then
		shown = pcall(holder.text.SetText, holder.text, scaled)
	end
	if not shown then
		blank(holder)
	end
end

local function clearAll()
	for _, holder in pairs(byPlate) do
		blank(holder)
	end
end

local function refreshAll()
	if not C_NamePlate or not C_NamePlate.GetNamePlates then return end

	local db = config()
	if not db.enabled then
		clearAll()
		return
	end

	local plates = C_NamePlate.GetNamePlates()
	if not plates then return end

	for _, plate in ipairs(plates) do
		local unit = plate.namePlateUnitToken
		if not unit and plate.UnitFrame then
			unit = plate.UnitFrame.unit
		end
		if unit then
			updatePlate(plate, unit)
		end
	end
end

local function layoutAll()
	for _, holder in pairs(byPlate) do
		layout(holder)
	end
end

function ns.ResetDB()
	if type(_G.HunTankDB) ~= "table" then
		_G.HunTankDB = {}
	end
	for key in pairs(_G.HunTankDB) do
		_G.HunTankDB[key] = nil
	end
	applyDefaults(_G.HunTankDB, defaults)
	validateDB(_G.HunTankDB)
	ns.db = _G.HunTankDB
end

ns.RefreshAll = refreshAll
ns.LayoutAll = layoutAll
ns.ClearAll = clearAll

local ticker = CreateFrame("Frame")
local elapsed = 0
ticker:SetScript("OnUpdate", function(_, delta)
	local db = ns.db
	if not db or not db.enabled then return end

	elapsed = elapsed + delta
	if elapsed < 0.2 then return end
	elapsed = 0

	if db.showOutOfCombat or inCombat then
		refreshAll()
	end
end)

local function updateCombatState()
	local ok, value = pcall(InCombatLockdown)
	inCombat = ok and value == true
end

local events = CreateFrame("Frame")
local watched = {
	"ADDON_LOADED",
	"PLAYER_LOGIN",
	"PLAYER_ENTERING_WORLD",
	"NAME_PLATE_UNIT_ADDED",
	"NAME_PLATE_UNIT_REMOVED",
	"UNIT_THREAT_LIST_UPDATE",
	"UNIT_THREAT_SITUATION_UPDATE",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
}
for _, event in ipairs(watched) do
	pcall(events.RegisterEvent, events, event)
end

events:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= addonName then return end
		ns.InitDB()
		return
	end

	if event == "PLAYER_LOGIN" then
		if not ns.db then ns.InitDB() end
		updateCombatState()
		refreshAll()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		clearAll()
		byPlate = {}
		byUnit = {}
		updateCombatState()
		refreshAll()
		return
	end

	if event == "NAME_PLATE_UNIT_ADDED" then
		if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end
		local plate = C_NamePlate.GetNamePlateForUnit(arg1)
		if plate then updatePlate(plate, arg1) end
		return
	end

	if event == "NAME_PLATE_UNIT_REMOVED" then
		local holder = byUnit[arg1]
		if holder then
			blank(holder)
			holder.unit = nil
			byUnit[arg1] = nil
		end
		return
	end

	if event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
		if arg1 and arg1:find("^nameplate") then
			local holder = byUnit[arg1]
			if holder and holder.plate then
				updatePlate(holder.plate, arg1)
			end
		end
		return
	end

	if event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		refreshAll()
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
		refreshAll()
	end
end)
