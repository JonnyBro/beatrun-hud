local enabled = CreateClientConVar("Beatrun_AmmoHUD", "1", true, false, "Show the ammo counter", 0, 1)
local showHealth = CreateClientConVar("Beatrun_AmmoHUDHealth", "0", true, false, "Show the health and armor panel", 0, 1)
local showKeys = CreateClientConVar("Beatrun_AmmoHUDKeys", "1", true, false, "Show firemode and underbarrel key hints", 0, 1)

local INF = "∞"
local ACCENT_FALLBACK = Color(235, 45, 45)
local OVERFILL_COLOR = Color(255, 215, 0)
local BAR_BG = Color(25, 25, 25)
local KEY_BG = Color(0, 0, 0)
local KEY_OUTLINE = Color(190, 190, 190)

local VANILLA_AUTOMATIC = {
	weapon_smg1 = true,
	weapon_ar2 = true,
	weapon_mp5_hl1 = true,
	weapon_gauss = true,
	weapon_egon = true
}

local TFA_FIREMODES = {
	["Full-Auto"] = { "auto" },
	["Semi-Auto"] = { "semi" },
	["Safety"] = { "safety" },
	["2 Round Burst"] = { "burst", 2 },
	["3 Round Burst"] = { "burst", 3 }
}

local KEY_ALIASES = {
	MOUSE1 = "LMB",
	MOUSE2 = "RMB",
	MOUSE3 = "MMB",
	MOUSE4 = "M4",
	MOUSE5 = "M5"
}

local function Phrase(key, ...)
	local text = language.GetPhrase("beatrunhud." .. key)

	if select("#", ...) > 0 then text = text:format(...) end

	return text
end

local function S(px)
	if BeatrunUI then return BeatrunUI.S(px) end

	return math.max(1, math.Round(px * ScrH() / 1080))
end

-- Weapon bases expose different methods, and a missing one must not break the HUD
local function Call(wep, name, ...)
	local fn = wep[name]

	if isfunction(fn) then return fn(wep, ...) end
end

local function ConVarBool(name)
	local cvar = GetConVar(name)

	return cvar ~= nil and cvar:GetBool()
end

local colorCache = {}

local function ConVarColor(name, fallback)
	local cvar = GetConVar(name)
	local str = cvar and cvar:GetString() or fallback
	local cached = colorCache[name]

	if not cached or cached.str ~= str then
		cached = { str = str, color = string.ToColor(str) }
		colorCache[name] = cached
	end

	return cached.color
end

local function CreateFonts()
	local size = math.Round(36 * ScrH() / 1080)

	for name, blursize in pairs({ BeatrunAmmoHUD_Big = 0, BeatrunAmmoHUD_BigGlow = 6 }) do
		surface.CreateFont(name, {
			font = "x14y24pxHeadUpDaisy",
			shadow = blursize == 0,
			antialias = false,
			extended = true,
			scanlines = 2,
			weight = 500,
			blursize = blursize,
			size = size
		})
	end
end

CreateFonts()

hook.Add("OnScreenSizeChanged", "BeatrunAmmoHUD_Fonts", CreateFonts)

local blur = Material("pp/blurscreen")
local healthpack = Material("pkad/healthpack.png", "alphatest")
local armorplate = Material("pkad/armorplate.png", "alphatest")

local function DrawBlurRect(x, y, w, h, a)
	if render.GetDXLevel() < 90 then return end

	x, y, w, h = math.Round(x), math.Round(y), math.Round(w), math.Round(h)

	surface.SetDrawColor(255, 255, 255, a)
	surface.SetMaterial(blur)

	for i = 1, 2 do
		blur:SetFloat("$blur", i / 3 * 5)
		blur:Recompute()

		render.UpdateScreenEffectTexture()
		render.SetScissorRect(x, y, x + w, y + h, true)

		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

		render.SetScissorRect(0, 0, 0, 0, false)
	end
end

-- Weapon info

local mwBaseCache = {}

local function IsMWBase(wep)
	local class = wep:GetClass()
	local based = mwBaseCache[class]

	if based == nil then
		based = weapons.IsBasedOn(class, "mg_base")
		mwBaseCache[class] = based
	end

	return based
end

local function FormatKey(name)
	if not name then return "?" end

	name = string.upper(name)

	return KEY_ALIASES[name] or name
end

local function BindKeys(...)
	local keys = {}

	for i, bind in ipairs({ ... }) do
		keys[i] = FormatKey(input.LookupBinding(bind))
	end

	return keys
end

local function MWKeys(ply, action)
	if not mw_input then return end

	local pack = mw_input.GetUnpackedInputs(ply, action)
	if not pack or not pack[1] then return { "?" } end

	local keys = { FormatKey(input.GetKeyName(pack[1])) }
	if pack[2] then keys[2] = FormatKey(input.GetKeyName(pack[2])) end

	return keys
end

local function Arc9Firemode(wep)
	if Call(wep, "GetJammed") then return Phrase("firemodes.jammed"), true end
	if Call(wep, "GetSafe") then return Phrase("firemodes.safety") end

	local fm = Call(wep, "GetCurrentFiremodeTable")
	if fm and fm.PrintName then return fm.PrintName end

	local mode = fm and fm.Mode or 1

	if mode == 0 then return Phrase("firemodes.safety") end
	if mode == 1 then return Phrase("firemodes.semi") end
	if mode < 0 then return Phrase("firemodes.auto") end

	return Phrase("firemodes.burst", mode)
end

local function ArcCWFiremode(wep)
	if Call(wep, "GetMalfunctionJam") then return Phrase("firemodes.jammed"), true end

	local hooked = Call(wep, "GetBuff_Hook", "Hook_FiremodeName")
	if hooked then return hooked end

	local fm = Call(wep, "GetCurrentFiremode")

	if fm and fm.PrintName and ArcCW then
		local phrase = ArcCW.GetPhraseFromString(fm.PrintName)
		local text = phrase and ArcCW.GetTranslation(phrase) or ArcCW.TryTranslation(fm.PrintName) or fm.PrintName

		return (string.gsub(string.upper(text), "%-ROUND BURST", "-BURST"))
	end

	local mode = fm and fm.Mode or 1

	if mode == 0 then return Phrase("firemodes.safety") end
	if mode == 1 then return Phrase("firemodes.semi") end
	if mode >= 2 then return Phrase("firemodes.auto") end

	return Phrase("firemodes.burst", -mode)
end

local function MWFiremode(wep)
	if Call(wep, "HasFlag", "Lowered") then return Phrase("firemodes.safety") end

	local fm = wep.Firemodes and wep.Firemodes[Call(wep, "GetFiremode") or 1]

	return fm and fm.Name or Phrase("firemodes.auto")
end

local function TFAFiremode(wep)
	if Call(wep, "IsSafety") then return Phrase("firemodes.safety") end

	local name = Call(wep, "GetFireModeName") or ""
	local mapped = TFA_FIREMODES[name]

	if mapped then return Phrase("firemodes." .. mapped[1], mapped[2]) end

	return name
end

local function GenericFiremode(wep)
	if Call(wep, "GetSafe") or Call(wep, "Safe") or Call(wep, "Safety") then return Phrase("firemodes.safety") end

	if wep:IsScripted() then
		if wep.TwoRoundBurst then return Phrase("firemodes.burst", 2) end
		if wep.ThreeRoundBurst then return Phrase("firemodes.burst", 3) end

		return wep.Primary and wep.Primary.Automatic and Phrase("firemodes.auto") or Phrase("firemodes.semi")
	end

	return VANILLA_AUTOMATIC[wep:GetClass()] and Phrase("firemodes.auto") or Phrase("firemodes.semi")
end

local function GetWeaponInfo(ply, wep)
	local isArc9, isArcCW, isTFA, isMW = wep.ARC9, wep.ArcCW, wep.IsTFAWeapon, IsMWBase(wep)

	local ammoType1, ammoType2 = wep:GetPrimaryAmmoType(), wep:GetSecondaryAmmoType()
	local clip1, maxClip1 = wep:Clip1(), wep:GetMaxClip1()
	local reserve1 = math.max(ply:GetAmmoCount(ammoType1), 0)

	local bottomless = maxClip1 <= 0
		or isArc9 and Call(wep, "GetProcessedValue", "BottomlessClip", true) and true
		or isArcCW and ConVarBool("arccw_mult_bottomlessclip")

	local infinite = isArc9 and (Call(wep, "GetInfiniteAmmo") or ConVarBool("arc9_infinite_ammo"))
		or isArcCW and ConVarBool("arccw_mult_infiniteammo")

	local mode, jammed, altActive, altName, modeKeys, altKeys

	if isArc9 then
		mode, jammed = Arc9Firemode(wep)
		altActive = Call(wep, "GetUBGL")
		altName = Call(wep, "GetProcessedValue", "UBGLFiremodeName")
		modeKeys = BindKeys("+zoom")
		altKeys = input.LookupBinding("+arc9_ubgl") and BindKeys("+arc9_ubgl") or BindKeys("+use", "+attack2")
	elseif isArcCW then
		mode, jammed = ArcCWFiremode(wep)
		altActive = Call(wep, "GetInUBGL")
		altName = Call(wep, "GetBuff_Override", "UBGL_PrintName") or ArcCW and ArcCW.GetTranslation("fcg.ubgl")
		modeKeys = BindKeys(input.LookupBinding("arccw_firemode") and "arccw_firemode" or "+zoom")
		altKeys = input.LookupBinding("arccw_toggle_ubgl") and BindKeys("arccw_toggle_ubgl") or BindKeys("+use", "+reload")
	elseif isMW then
		mode = MWFiremode(wep)
		altActive = Call(wep, "HasFlag", "UsingUnderbarrel")

		local underbarrel = Call(wep, "GetUnderbarrel")
		altName = underbarrel and underbarrel.Name

		modeKeys = MWKeys(ply, "firemode")
		altKeys = MWKeys(ply, "underbarrel")
	elseif isTFA then
		mode = TFAFiremode(wep)
	else
		mode = GenericFiremode(wep)
	end

	local primary = {
		mode = string.upper(mode or ""),
		jammed = jammed,
		keys = modeKeys
	}

	if bottomless then
		local total = reserve1 + math.max(clip1, 0)

		primary.main = infinite and INF or tostring(total)
		primary.ratio = (infinite or total > 0) and 1 or 0
		primary.low = not infinite and total == 0
	else
		local shown = math.Clamp(clip1, 0, maxClip1)

		primary.main = tostring(shown)
		primary.over = clip1 > maxClip1 and "+" .. (clip1 - maxClip1) or nil
		primary.reserve = "/" .. (infinite and INF or reserve1)
		primary.reserveLow = not infinite and reserve1 == 0
		primary.ratio = shown / maxClip1
		primary.overRatio = math.min((clip1 - shown) / maxClip1, 1)
		primary.low = shown < maxClip1 / 3
	end

	local alt

	if ammoType2 ~= -1 then
		local clip2, maxClip2 = wep:Clip2(), wep:GetMaxClip2()
		local reserve2 = math.max(ply:GetAmmoCount(ammoType2), 0)
		-- ArcCW infinite ammo cvar doesn't apply to the underbarrel
		local altInfinite = infinite and not isArcCW

		alt = {
			mode = string.upper(altName or Phrase("altfire")),
			keys = altKeys
		}

		if maxClip2 <= 0 or isArc9 and bottomless then
			local total = reserve2 + math.max(clip2, 0)

			alt.main = altInfinite and INF or tostring(total)
			alt.ratio = (altInfinite or total > 0) and 1 or 0
			alt.low = not altInfinite and total == 0
		else
			local shown = math.Clamp(clip2, 0, maxClip2)

			alt.main = tostring(shown)
			alt.over = clip2 > maxClip2 and "+" .. (clip2 - maxClip2) or nil
			alt.reserve = "/" .. (altInfinite and INF or reserve2)
			alt.reserveLow = not altInfinite and reserve2 == 0
			alt.ratio = shown / maxClip2
			alt.overRatio = math.min((clip2 - shown) / maxClip2, 1)
			alt.low = shown < maxClip2 / 3
		end
	end

	return primary, alt, altActive and alt ~= nil
end

-- Drawing

local hidealpha = 0
local textColor, cornerColor, accent
local textAlpha, cornerAlpha, outlineAlpha, blurAlpha

local pulseStart = {}

local function Pulse(key, active)
	if not active then
		pulseStart[key] = nil

		return 0
	end

	local start = pulseStart[key]

	if not start then
		start = CurTime()
		pulseStart[key] = start
	end

	return math.abs(math.sin((CurTime() - start) * 2))
end

local function DrawCorner(x, y, h)
	surface.SetDrawColor(cornerColor.r, cornerColor.g, cornerColor.b, cornerAlpha)
	surface.DrawRect(x, y, 40, h)
end

local function DrawPanelBox(x, y, w, h)
	DrawBlurRect(x, y, w, h, blurAlpha)

	surface.SetDrawColor(cornerColor.r, cornerColor.g, cornerColor.b, outlineAlpha)
	surface.DrawOutlinedRect(x, y, w, h)
end

local function KeysWidth(keys)
	if not keys or #keys == 0 or not showKeys:GetBool() then return 0 end

	surface.SetFont("BeatrunHUDSmall")

	local plusW = surface.GetTextSize("+")
	local w = 0

	for i, key in ipairs(keys) do
		w = w + surface.GetTextSize(key) + S(5) * 2

		if i > 1 then w = w + plusW + S(4) end
	end

	return w
end

local function DrawKeys(keys, x, cy, alpha)
	surface.SetFont("BeatrunHUDSmall")

	local _, th = surface.GetTextSize("W")
	local h = th + S(2)
	local y = math.Round(cy - h / 2)

	for i, key in ipairs(keys) do
		if i > 1 then
			local plusW = draw.SimpleText("+", "BeatrunHUDSmall", x + S(2), cy, ColorAlpha(KEY_OUTLINE, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			x = x + plusW + S(4)
		end

		local w = surface.GetTextSize(key) + S(5) * 2

		surface.SetDrawColor(KEY_BG.r, KEY_BG.g, KEY_BG.b, alpha * 90 / 255)
		surface.DrawRect(x, y, w, h)
		surface.SetDrawColor(KEY_OUTLINE.r, KEY_OUTLINE.g, KEY_OUTLINE.b, alpha)
		surface.DrawOutlinedRect(x, y, w, h, 1)

		draw.SimpleText(key, "BeatrunHUDSmall", x + w / 2, cy, ColorAlpha(textColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		x = x + w
	end
end

local function AmmoContentWidth(info)
	surface.SetFont("BeatrunAmmoHUD_Big")
	local mainW = surface.GetTextSize(info.main)

	surface.SetFont("BeatrunHUD")
	local reserveW = info.reserve and surface.GetTextSize(info.reserve) or 0

	surface.SetFont("BeatrunHUDSmall")
	local overW = info.over and surface.GetTextSize(info.over) + S(2) or 0
	local modeW = surface.GetTextSize(info.mode)

	local keysW = KeysWidth(info.keys)

	return math.max(S(150), mainW + overW + reserveW, modeW + (keysW > 0 and keysW + S(10) or 0))
end

-- Beatrun fonts scale with screen width and S() with height, so rows are stacked from measured font heights
local function AmmoLayout()
	surface.SetFont("BeatrunAmmoHUD_Big")
	local _, bigH = surface.GetTextSize("0")

	surface.SetFont("BeatrunHUDSmall")
	local _, smallH = surface.GetTextSize("W")

	local pad = S(6)
	local barY = pad + bigH + S(4)
	local rowY = barY + S(9)
	local rowH = smallH + S(2)

	return {
		textTop = pad,
		baseline = pad + bigH - S(3),
		barY = barY,
		rowCY = rowY + rowH / 2,
		h = math.max(S(85), rowY + rowH + pad)
	}
end

local function DrawAmmoInfo(info, x, y, w, active, pulseKey, layout)
	local inset = S(10)
	local left, right = x + inset, x + w - inset
	local alpha = active and textAlpha or textAlpha * 0.45
	local baseColor = ColorAlpha(textColor, alpha)
	local lowColor = ColorAlpha(accent, alpha)

	local textTop = y + layout.textTop
	local cursor = right

	if info.reserve then
		local color = baseColor

		if info.reserveLow then
			color = ColorAlpha(accent, alpha * (0.4 + 0.6 * Pulse(pulseKey .. "_reserve", true)))
		else
			Pulse(pulseKey .. "_reserve", false)
		end

		cursor = cursor - draw.SimpleText(info.reserve, "BeatrunHUD", cursor, y + layout.baseline, color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
	end

	if info.over then
		cursor = cursor - draw.SimpleText(info.over, "BeatrunHUDSmall", cursor, textTop + S(2), ColorAlpha(OVERFILL_COLOR, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP) - S(2)
	end

	local pulse = Pulse(pulseKey, info.low)

	if info.low then draw.SimpleText(info.main, "BeatrunAmmoHUD_BigGlow", cursor, textTop, ColorAlpha(accent, alpha * pulse), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP) end

	draw.SimpleText(info.main, "BeatrunAmmoHUD_Big", cursor, textTop, info.low and lowColor or baseColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local barW = math.min(S(150), w - inset * 2)
	local barX = right - barW
	local barY = y + layout.barY

	surface.SetDrawColor(BAR_BG.r, BAR_BG.g, BAR_BG.b, alpha)
	surface.DrawRect(barX, barY + 1, barW, S(4))

	surface.SetDrawColor(info.low and lowColor or baseColor)
	surface.DrawRect(barX, barY, barW * info.ratio, S(5))

	if info.overRatio and info.overRatio > 0 then
		surface.SetDrawColor(OVERFILL_COLOR.r, OVERFILL_COLOR.g, OVERFILL_COLOR.b, alpha)
		surface.DrawRect(barX, barY + S(5), barW * info.overRatio, S(2))
	end

	local rowCY = y + layout.rowCY

	draw.SimpleText(info.mode, "BeatrunHUDSmall", right, rowCY, info.jammed and lowColor or baseColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	if info.keys and #info.keys > 0 and showKeys:GetBool() then DrawKeys(info.keys, left, rowCY, alpha) end
end

local function DrawAmmo(ply, wep, vp)
	if wep:GetPrimaryAmmoType() == -1 then return end

	local primary, alt, altActive = GetWeaponInfo(ply, wep)

	local layout = AmmoLayout()
	local h = layout.h
	-- Bottom stays where the Beatrun level panel ends, extra height grows upwards
	local y = ScrH() * 0.895 + S(85) - h + vp.x
	local right = ScrW() - 20 + vp.z

	local w = AmmoContentWidth(primary) + S(10) * 2
	local x = right - w

	DrawCorner(right, y, h)
	DrawPanelBox(x, y, w, h)
	DrawAmmoInfo(primary, x, y, w, not altActive, "primary", layout)

	if not alt then return end

	local altW = math.max(S(160), AmmoContentWidth(alt) + S(10) * 2)
	local altX = x - S(8) - altW

	DrawPanelBox(altX, y, altW, h)
	DrawAmmoInfo(alt, altX, y, altW, altActive, "alt", layout)
end

local function DrawHealth(ply, vp)
	local hp, ap = ply:Health(), ply:Armor()
	local hpRatio = hp / math.max(ply:GetMaxHealth(), 1)
	local apRatio = ap / math.max(ply:GetMaxArmor(), 1)

	local extras = {}

	if ply.GetStims then extras[#extras + 1] = { mat = healthpack, count = ply:GetStims() } end

	if ply.GetArmorPlates then
		extras[#extras + 1] = { mat = armorplate, count = ply:GetArmorPlates() }
	elseif GetConVar("wz_armorsys_armorplates_maxcarry") then
		extras[#extras + 1] = { mat = armorplate, count = ply:GetAmmoCount("WZ_ARMORPLATE") }
	end

	local hpText = Phrase("health") .. " " .. hp
	local apText = Phrase("armor") .. " " .. ap

	surface.SetFont("BeatrunHUD")
	local hpW, textH = surface.GetTextSize(hpText)
	local apW = surface.GetTextSize(apText)

	surface.SetFont("BeatrunHUDSmall")
	local _, smallH = surface.GetTextSize("W")

	local icon = math.max(S(16), smallH)
	local gap = S(16)
	local rowW = hpW + gap + apW
	local shown = {}

	for _, extra in ipairs(extras) do
		-- Icons come from resource.AddFile and may be missing if the server has downloads disabled
		if extra.mat:IsError() then continue end

		extra.text = tostring(extra.count)
		extra.w = icon + S(4) + surface.GetTextSize(extra.text)
		rowW = rowW + extra.w + gap
		shown[#shown + 1] = extra
	end

	local inset = S(10)
	local pad = S(6)
	local w = math.max(S(220), rowW + inset * 2)
	local barY = pad + textH + S(4)
	local h = barY + S(9) + S(5) + pad

	local x = 20 + vp.z
	local y = ScrH() * 0.895 + vp.x - S(8) - h
	local left, right = x + inset, x + w - inset
	local rowCY = y + pad + textH / 2

	DrawCorner(-20 + vp.z, y, h)
	DrawPanelBox(x, y, w, h)

	local baseColor = ColorAlpha(textColor, textAlpha)
	local hpLow = hpRatio <= 1 / 3
	local hpColor = hpLow and ColorAlpha(accent, textAlpha) or baseColor

	draw.SimpleText(hpText, "BeatrunHUD", left, rowCY, hpColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(apText, "BeatrunHUD", right, rowCY, ColorAlpha(textColor, ap > 0 and textAlpha or textAlpha * 0.45), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	local cursor = left + hpW + gap

	for _, extra in ipairs(shown) do
		surface.SetMaterial(extra.mat)
		surface.SetDrawColor(255, 255, 255, textAlpha)
		surface.DrawTexturedRect(cursor, math.Round(rowCY - icon / 2), icon, icon)

		draw.SimpleText(extra.text, "BeatrunHUDSmall", cursor + icon + S(4), rowCY, baseColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		cursor = cursor + extra.w + gap
	end

	local barW = right - left

	barY = y + barY

	surface.SetDrawColor(BAR_BG.r, BAR_BG.g, BAR_BG.b, textAlpha)
	surface.DrawRect(left, barY + 1, barW, S(4))
	surface.SetDrawColor(hpColor)
	surface.DrawRect(left, barY, barW * math.Clamp(hpRatio, 0, 1), S(5))

	if hpRatio > 1 then
		surface.SetDrawColor(OVERFILL_COLOR.r, OVERFILL_COLOR.g, OVERFILL_COLOR.b, textAlpha)
		surface.DrawRect(left, barY + S(5), barW * math.min(hpRatio - 1, 1), S(2))
	end

	barY = barY + S(9)

	surface.SetDrawColor(BAR_BG.r, BAR_BG.g, BAR_BG.b, textAlpha)
	surface.DrawRect(left, barY, barW, S(3))
	surface.SetDrawColor(KEY_OUTLINE.r, KEY_OUTLINE.g, KEY_OUTLINE.b, textAlpha)
	surface.DrawRect(left, barY, barW * math.Clamp(apRatio, 0, 1), S(3))

	if apRatio > 1 then
		surface.SetDrawColor(OVERFILL_COLOR.r, OVERFILL_COLOR.g, OVERFILL_COLOR.b, textAlpha)
		surface.DrawRect(left, barY + S(3), barW * math.min(apRatio - 1, 1), S(2))
	end
end

local function ShouldDraw(ply)
	if not BeatrunUI or BuildMode then return false end
	if not IsValid(ply) or not ply:Alive() then return false end
	if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return false end

	local hidden = GetConVar("Beatrun_HUDHidden")
	if hidden and hidden:GetInt() > 0 then return false end

	if BeatrunUI.IsLargeWindowOpen() then return false end

	return hook.Run("BeatrunDrawHUD") ~= false
end

hook.Add("HUDPaint", "BeatrunAmmoHUD", function()
	local drawAmmo, drawHealth = enabled:GetBool(), showHealth:GetBool()
	if not drawAmmo and not drawHealth then return end

	local ply = LocalPlayer()
	if not ShouldDraw(ply) then return end

	local dynamic = ConVarBool("Beatrun_HUDDynamic")

	if dynamic then
		hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
	else
		hidealpha = 0
	end

	textColor = ConVarColor("Beatrun_HUDTextColor", "255 255 255 255")
	cornerColor = ConVarColor("Beatrun_HUDCornerColor", "20 20 20 100")
	accent = BEATRUN_ACCENT or ACCENT_FALLBACK

	textAlpha = dynamic and math.max(255 - hidealpha, 2) or textColor.a
	cornerAlpha = dynamic and math.max(150 - hidealpha, 50) or math.Clamp(cornerColor.a + 50, 0, 255)
	outlineAlpha = dynamic and math.max(100 - hidealpha, 50) or cornerColor.a
	blurAlpha = math.max(255 - hidealpha, 2)

	local vp = ply.GetSmoothViewPunchAngles and ply:GetSmoothViewPunchAngles() or ply:GetViewPunchAngles()

	if not ConVarBool("Beatrun_HUDSway") then
		vp.x = 0
		vp.z = 0
	end

	local wep = ply:GetActiveWeapon()

	if drawAmmo and IsValid(wep) then DrawAmmo(ply, wep, vp) end
	if drawHealth then DrawHealth(ply, vp) end
end)

local hideHL2 = {
	CHudAmmo = true,
	CHudSecondaryAmmo = true
}

hook.Add("HUDShouldDraw", "BeatrunAmmoHUD_HideHL2", function(name)
	if hideHL2[name] and BeatrunUI and enabled:GetBool() then return false end
end)

-- Settings

local SETTINGS = {
	{ convar = "Beatrun_AmmoHUD", label = "#beatrunhud.settings.ammo", desc = "#beatrunhud.settings.ammodesc" },
	{ convar = "Beatrun_AmmoHUDKeys", label = "#beatrunhud.settings.keys", desc = "#beatrunhud.settings.keysdesc" },
	{ convar = "Beatrun_AmmoHUDHealth", label = "#beatrunhud.settings.health", desc = "#beatrunhud.settings.healthdesc" }
}

local settingsFrame

local function Description(UI, body, text, indent)
	local hint = UI.MakeLabel(body, text, "AEUIDefault", CurrentTheme().text.muted)
	hint:Dock(TOP)
	hint:DockMargin(indent or 0, S(2), 0, S(14))
	hint:SetWrap(true)
	hint:SetAutoStretchVertical(true)
end

local function OpenSettings()
	if IsValid(settingsFrame) then
		settingsFrame:Remove()

		return
	end

	local UI = BeatrunUI

	if not UI then
		print(Phrase("notbeatrun"))

		return
	end

	settingsFrame = UI.MakeWindow("#beatrunhud.settings.title", S(560), S(520))

	local body = UI.MakeScroll(settingsFrame):GetCanvas()
	body:DockPadding(S(4), S(4), S(12), S(4))

	UI.MakeTitle(body, "#beatrunhud.settings.display")

	for _, item in ipairs(SETTINGS) do
		local check = vgui.Create("DCheckBoxLabel", body)
		check:SetText(item.label)
		check:SetFont("BeatrunUI")
		check:SetTextColor(CurrentTheme().text.primary)
		check:SetConVar(item.convar)
		check:Dock(TOP)
		check.Button:SetSize(S(20), S(20))

		UI.StyleCheckBox(check.Button)

		Description(UI, body, item.desc, S(28))
	end

	UI.MakeTitle(body, "#beatrunhud.settings.beatrun")
	Description(UI, body, "#beatrunhud.settings.beatrundesc")

	local open = UI.MakeButton(body, "#beatrunhud.settings.openbeatrun", "secondary", "BeatrunUI")
	open:Dock(TOP)
	open.DoClick = function()
		settingsFrame:Close()
		RunConsoleCommand("beatrun_settings")
	end
end

concommand.Add("beatrun_hud_settings", OpenSettings)

list.Set("DesktopWindows", "BeatrunAmmoHUDSettings", {
	title = "#beatrunhud.settings.desktop",
	icon = "vgui/melogo.png",
	width = 1,
	height = 1,
	onewindow = false,
	init = function(_, window)
		window:Remove()

		if IsValid(settingsFrame) then settingsFrame:Remove() end

		OpenSettings()
	end
})
