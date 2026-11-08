local addonName, ns = ...

local function ensureDB()
	if not ns.db then ns.InitDB() end
end

local function parseColor(value)
	value = tostring(value or ""):gsub("^#", "")
	if not value:match("^%x%x%x%x%x%x$") then return nil end
	return {
		r = tonumber(value:sub(1, 2), 16) / 255,
		g = tonumber(value:sub(3, 4), 16) / 255,
		b = tonumber(value:sub(5, 6), 16) / 255,
	}
end

local function colorHex(color)
	local r = math.floor((color.r or 1) * 255 + 0.5)
	local g = math.floor((color.g or 0.8) * 255 + 0.5)
	local b = math.floor((color.b or 0) * 255 + 0.5)
	return string.format("%02x%02x%02x", r, g, b)
end

local function printHelp()
	ns.Print("/ht on|off")
	ns.Print("/ht pos right|left|above|below")
	ns.Print("/ht size <8-32>")
	ns.Print("/ht color <rrggbb>")
	ns.Print("/ht outofcombat")
	ns.Print("/ht status")
	ns.Print("/ht reset")
end

local function printStatus()
	local db = ns.db
	ns.Print(string.format(
		"%s, %s, size %d, color #%s, out of combat %s",
		db.enabled and "on" or "off",
		db.position,
		tonumber(db.size) or 12,
		colorHex(db.color or {}),
		db.showOutOfCombat and "on" or "off"
	))
end

local function handleCommand(message)
	ensureDB()

	message = tostring(message or "")
	message = message:match("^%s*(.-)%s*$") or ""
	local command, rest = message:match("^(%S*)%s*(.-)$")
	command = (command or ""):lower()
	rest = rest or ""

	if command == "" or command == "help" then
		printHelp()

	elseif command == "on" then
		ns.db.enabled = true
		ns.RefreshAll()
		ns.Print("on")

	elseif command == "off" then
		ns.db.enabled = false
		ns.ClearAll()
		ns.Print("off")

	elseif command == "pos" then
		local position = rest:lower()
		if position == "right" or position == "left" or position == "above" or position == "below" then
			ns.db.position = position
			ns.LayoutAll()
			ns.RefreshAll()
			ns.Print("position: " .. position)
		else
			ns.Print("usage: /ht pos right|left|above|below")
		end

	elseif command == "size" then
		local size = tonumber(rest)
		if size and size >= 8 and size <= 32 then
			ns.db.size = size
			ns.LayoutAll()
			ns.Print("size: " .. size)
		else
			ns.Print("usage: /ht size 8-32")
		end

	elseif command == "color" then
		local color = parseColor(rest)
		if color then
			ns.db.color = color
			ns.LayoutAll()
			ns.Print("color: #" .. colorHex(color))
		else
			ns.Print("usage: /ht color rrggbb")
		end

	elseif command == "outofcombat" then
		ns.db.showOutOfCombat = not ns.db.showOutOfCombat
		ns.RefreshAll()
		ns.Print("out of combat: " .. (ns.db.showOutOfCombat and "on" or "off"))

	elseif command == "status" then
		printStatus()

	elseif command == "reset" then
		ns.ResetDB()
		ns.LayoutAll()
		ns.RefreshAll()
		ns.Print("reset")

	else
		ns.Print("unknown command: " .. command)
		printHelp()
	end
end

SLASH_HUNTANK1, SLASH_HUNTANK2 = "/huntank", "/ht"
SlashCmdList.HUNTANK = function(message)
	local ok, err = pcall(handleCommand, message)
	if not ok then
		ns.Print("error: " .. tostring(err))
	end
end
