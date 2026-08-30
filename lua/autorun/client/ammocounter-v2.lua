-- i forgot to do git push last time lmfao, anyway here we go

local CPPAltfireWeps = {
	["Weapon_smg1"] = true,
	["Weapon_ar2"] = true,
	["Weapon_mp5_hl1"] = true
}  


-- local MWBaseFiremodes = { -- ...is MWB even localized?
--  ["AUTOMATIC"] = "#pkad_firemodes_auto", 
-- 	["FULL AUTO"] = "#pkad_firemodes_auto",
-- 	["SEMI AUTO"] = "#pkad_firemodes_semi",
-- 	["SEMI AUTOMATIC"] = "#pkad_firemodes_semi",
-- 	["3RND BURST"] = language.GetPhrase("pkad_firemodes_burst"):format("3")
-- }

local TFAFiremodes = {
    ["Full-Auto"] = "language.GetPhrase("pkad_firemodes_auto")", 
	["Semi-Auto"] = "language.GetPhrase("pkad_firemodes_semi")",
	["3 Round Burst"] = language.GetPhrase("pkad_firemodes_burst"):format("3")
}

local VanillaAutomatics = {
	["weapon_smg1"] = true,
	["weapon_ar2"] = true,
	["weapon_mp5_hl1"] = true,
	["weapon_gauss"] = true,
	["weapon_egon"] = true
}

-- All SORTS of ClientCVars
local hidden = CreateClientConVar("PKAD_Hidden", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local enablehealth = CreateClientConVar("PKAD_EnableHealth", "0", true, false, "UNFINISHED: Enable health and armor panel", 0, 1)
local sway = CreateClientConVar("PKAD_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAD_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local UserScale = CreateClientConVar("PKAD_Scale", "1", true, false, "Define your own scaling!")
local blur = CreateClientConVar("PKAD_NoBlur", "1", true, false, "Define your own scaling!")
local beatruncolors = CreateClientConVar("PKAD_UseBeatrunColors", 1, true, false, "Use Beatrun colors. Only works while in Beatrun gamemode, and only if your Beatrun version includes this functionality.\nDOES NOT AFFECT: Health and armor panel, ammo text when low", 0, 1)
local barsusecornercolor = CreateClientConVar("PKAD_BarUsesCornerColor", 0, true, false, "Use corner color instead of text color for bars.\nDOES NOT AFFECT: Health and armor panel", 0, 1)
local playername = ""
local ply = nil
local scale = ScrH() / 1080 * UserScale:GetFloat()
local scrw = ScrW()
local scrh = ScrH()
CreateClientConVar("PKAD_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
CreateClientConVar("PKAD_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
CreateClientConVar("PKAD_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
CreateClientConVar("PKAD_TextLowColor", "255 0 0 230", true, false, "Ammo counter text color when low.")
CreateClientConVar("PKAD_TextLowInactiveColor", "100 50 50 100", true, false, "Ammo counter text color when low and inactive. Used on altfire when not in altfire mode and vice versa.")
CreateClientConVar("PKAD_BlurTintColor", "0 0 0 0", true, false, "Blur tint color. Helps with visibility. Only works with blur enabled./n Alpha value is locked, sorry!")
CreateClientConVar("PKAD_HealthColor", "255 255 255 255", true, false, "Health text and bar color. Ignored when low.")
CreateClientConVar("PKAD_ArmorColor", "65 124 174 124", true, false, "Armor text and bar color.")

local deadzonex = CreateClientConVar("PKAD_DeadzoneX", "0", true, false, "Use this HUD while playing on your HDTV!", 0, 0.5)
local deadzoney = CreateClientConVar("PKAD_DeadzoneY", "0", true, false, "Use this HUD while playing on your HDTV!", 0, 0.5)

local Weapon = nil
local WeaponClass = ""
local WepClip1 = -1 
local WepClip2 = -1 
local WepMag1 = -1 
local WepMag2 = -1
local WepReserve1 = -1
local WepReserve2 = -1
local HasAltFire = false
local FiremodeText = language.GetPhrase("pkad_firemodes_auto")
local AltFiremodeText = language.GetPhrase("pkad_altfire_placehold")
local ActivePrimaryFire = true
local InstantAltfire = false
local BottomlessMag = false

local ismgbase = false
local isarc9 = false
local isweparccw = false
local istfabase = false

local LastLowAmmoFrame = 0
local LastLowReserveFrame = 0
local CurrentlyLowAmmo = false 
local CurrentlyLowReserve = false
local AltLastLowAmmoFrame = 0
local AltLastLowReserveFrame = 0
local AltCurrentlyLowAmmo = false 
local AltCurrentlyLowReserve = false

local ubglkey = ""
local firemodekey = ""

local AmmoColor = nil
local AlternateAmmoColor = nil 
local LowAmmoColor = nil
local AlternateLowAmmoColor = nil 
local ReserveColor = nil
local MagazineColor = nil
local AltReserveColor = nil
local AltfireColor = nil
local AltMagBarColor = nil
local MagBarColor = nil

local corner_color_c = nil
local text_color = nil
local otherammocolor = nil
local othertext = nil
local ammobarcolor = nil
local armorbackground = nil
local ammolowcolor = nil
local ammolowcolor1 = nil
local healthcolor = nil
local armorcolor = nil

local ammolowpulsecolor = Color(255,0,0,230)
local reservelowpulsecolor = Color(255,0,0,230)
local altammolowpulsecolor = Color(255,0,0,230)
local altreservelowpulsecolor = Color(255,0,0,230)

-- Variables: Textures and the like
local blurtex = Material("pp/blurscreen")
local healthpack = Material("pkad/healthpack.png", " alphatest ")
local armorplate = Material("pkad/armorplate.png", " alphatest ")

local ARC9Installed = false
local ArcCWInstalled = false
local TFAInstalled = false

local gamemodename = engine.ActiveGamemode()
local usebeatruncolors = false

local hide = {
    CHudBattery = GetConVar("PKAD_Hidden"):GetBool(),
    CHudAmmo = true,
    CHudSecondaryAmmo = true
}

-- Functions.
local function DrawBlurRect2(x, y, w, h, a, f) -- NEW: f is intensity. Adjust by multiples of 5.
	if render.GetDXLevel() < 90 or !blur:GetBool() then
		surface.SetDrawColor(80,80,80,50)
		surface.DrawRect(x,y,w,h)
	else
		local X = 0
		local Y = 0
		local intensity = 20
		if f != nil then intensity = f end
		
		surface.SetDrawColor(255, 255, 255, a)
		surface.SetMaterial(blurtex)
		
		for i = 1, 2 do
			--blur:SetFloat("$blur", i / 3 * 5)
			blurtex:SetFloat("$blur", i / 12 * intensity)
			blurtex:Recompute()
			
			render.UpdateScreenEffectTexture()
			render.SetScissorRect(x, y, x + w, y + h, true)
			
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
			
			render.SetScissorRect(0, 0, 0, 0, false)
		end

		BlurTintColor = string.ToColor(LocalPlayer():GetInfo("PKAD_BlurTintColor"))
		BlurTintColor.a = dynamic:GetBool() and math.max(50 - hidealpha, 0) or BlurTintColor.a
		surface.SetDrawColor(BlurTintColor)
		surface.DrawRect(x,y,w,h)
		--print(tostring(BlurTintColor))
	end
end

local function PKAD2_InitFonts()
	surface.CreateFont("PKAD_BigText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 500,
		size = 21 * scale
	})
	
	surface.CreateFont("PKAD_BlurredBigText", {
		shadow = true,
		blursize = 4,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 500,
		size = 21 * scale
	})

	surface.CreateFont("PKAD_BiggerText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 500,
		size = 29 * scale
	})
	
	surface.CreateFont("PKAD_SmallText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 500,
		size = 18 * scale
	})

	surface.CreateFont("PKAD_HugeText", {
		shadow = true,
		blursize = 0,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 250,
		size = 36 * scale
	})
	
	surface.CreateFont("PKAD_BlurredHugeText", {
		shadow = true,
		blursize = 10,
		underline = false,
		rotary = false,
		strikeout = false,
		additive = false,
		antialias = false,
		extended = false,
		scanlines = 2,
		font = "x14y24pxHeadUpDaisy",
		italic = false,
		outline = false,
		symbol = false,
		weight = 250,
		size = 36 * scale
	})
end

local function FindA9Firemode()
	AltFiremodeText = Weapon:GetProcessedValue("UBGLFiremodeName")

	if Weapon:GetUBGL() then
		ActivePrimaryFire = false
	end
	
	local arc9_mode = Weapon:GetCurrentFiremodeTable()
	local FiremodeText = "UNKNOWN"
	
	if arc9_mode.PrintName then
		FiremodeText = arc9_mode.PrintName
	else
		if arc9_mode.Mode == 1 then
			FiremodeText = language.GetPhrase("pkad_firemodes_semi")
		elseif arc9_mode.Mode == 0 then
			FiremodeText = language.GetPhrase("pkad_firemodes_safety")
		elseif arc9_mode.Mode < 0 then
			FiremodeText = language.GetPhrase("pkad_firemodes_auto")
		elseif arc9_mode.Mode > 1 then
			FiremodeText = language.GetPhrase("pkad_firemodes_burst"):format(tostring(arc9_mode.Mode))
		end
	end
	
	if Weapon:GetSafe() then
		FiremodeText = language.GetPhrase("pkad_firemodes_safety")
	end
	
	return FiremodeText
end

local function FindArcCWFiremode()
	if Weapon:GetInUBGL() then return end
	--AltFiremodeText = Weapon:GetBuff_Override("UBGL_PrintName") and Weapon:GetBuff_Override("UBGL_PrintName") or ArcCW.GetTranslation("fcg.ubgl" .. abbrev)

	if Weapon:GetBuff_Hook("Hook_FiremodeName") then return Weapon:GetBuff_Hook("Hook_FiremodeName") end
	
	--local abbrev = GetConVar("arccw_hud_fcgabbrev"):GetBool() and ".abbrev" or ""

	--if Weapon:GetInUBGL() then
	--	ActivePrimaryFire = false
	--end

	local fm = Weapon:GetCurrentFiremode()

	if fm.PrintName then
		local phrase = ArcCW.GetPhraseFromString(fm.PrintName)
		return phrase and ArcCW.GetTranslation(phrase) or ArcCW.TryTranslation(fm.PrintName)
	end

	local mode = fm.Mode
	if mode == 0 then return language.GetPhrase("pkad_firemodes_safety") end
	if mode == 1 then return language.GetPhrase("pkad_firemodes_semi") end
	if mode >= 2 then return language.GetPhrase("pkad_firemodes_auto") end
	if mode < 0 then return language.GetPhrase("pkad_firemodes_burst"):format(tostring(-mode)) end
end

local function PKAD2_GetWeaponData()
	ply = LocalPlayer()
	Weapon = ply:GetActiveWeapon()

	if !IsValid(Weapon) then return end

	WeaponClass = Weapon:GetClass()
	WepClip1 = math.Clamp(Weapon:Clip1(), 0, Weapon:GetMaxClip1())
	WepClip2 = math.Clamp(Weapon:Clip2(), 0, Weapon:GetMaxClip2())
	WepMag1 = Weapon:GetMaxClip1()
	WepMag2 = Weapon:GetMaxClip2()
	WepReserve1 = math.Clamp(ply:GetAmmoCount(Weapon:GetPrimaryAmmoType()), 0, 2147483647)
	WepReserve2 = math.Clamp(ply:GetAmmoCount(Weapon:GetSecondaryAmmoType()), 0, 2147483647)
	OverCapacity = math.Clamp(Weapon:Clip1() - WepMag1, 0, 2147483647)
	OverAltCapacity = math.Clamp(Weapon:Clip2() - WepMag2, 0, 2147483647)
	if Weapon:GetSecondaryAmmoType() != -1 then
		HasAltFire = true
	else
		HasAltFire = false
	end
	MagFillRatio = WepClip1 / WepMag1
	AltFillRatio = WepClip2 / WepMag2
	OverfillRatio = math.Clamp(Weapon:Clip1() - WepClip1, 0, 2147483647) / WepClip1
	AltOverfillRatio = math.Clamp(Weapon:Clip2() - WepClip2, 0, 2147483647) / WepClip2

	BottomlessMag = false
	InstantAltfire = false

	ismgbase = weapons.IsBasedOn(Weapon:GetClass(), "mg_base")
	isarc9 = Weapon.ARC9
	isweparccw = Weapon.ArcCW
	istfabase = Weapon.IsTFAWeapon

	-- Bottomless clip detection. Same as infinite ammo detection.
	if isarc9 then
		if !Weapon:GetProcessedValue("BottomlessClip", true) then return end
		BottomlessMag = true
		InstantAltfire = true
	elseif isweparccw and GetConVar("arccw_mult_bottomlessclip"):GetBool() then
		BottomlessMag = true
		InstantAltfire = false
		-- For some inexplicable reason altfire for ArcCW is NOT affected by its bottomless clip CVar.
	elseif !isarc9 and !isweparccw and Weapon:GetMaxClip1() == -1 then
		BottomlessMag = true
	end
end

local function PKAD2_GetFiremode()
	ActivePrimaryFire = true
	WeaponJammed = false

	usekey = string.Replace(input.LookupBinding("+use"), "MOUSE", "M")
	attack2 = string.Replace(input.LookupBinding("+attack2"), "MOUSE", "M")
	reloadkey = string.Replace(input.LookupBinding("+reload"), "MOUSE", "M")

	if Weapon:IsScripted() and WepMag2 == -1 then 
		InstantAltfire = true
	elseif !Weapon:IsScripted() then 
		InstantAltfire = true
	else
		InstantAltfire = false
	end

	if isarc9 then -- Biggest blunder ever: forgor to change a9 to isarc9. bruh.
		local arc9_mode = Weapon:GetCurrentFiremodeTable()
		
		FiremodeText = FindA9Firemode()
		
		if Weapon:GetUBGL() then
			--arc9_mode = {
			--	Mode = Weapon:GetCurrentFiremode(),
			--	PrintName = Weapon:GetProcessedValue("UBGLFiremodeName")
			--}
			--FiremodeText = arc9_mode.PrintName
			wepmultifire = false
			ActivePrimaryFire = false
		end
		
		if Weapon:GetJammed() then
			WeaponJammed = true
			FiremodeText = "MALFUNCTIONING"
		end
		
		-- if Weapon:GetProcessedValue("Overheat", true) then
		-- 	arc9showheat = true
		-- 	heat = Weapon:GetHeatAmount()
		-- 	heatcap = Weapon:GetProcessedValue("HeatCapacity")
		-- 	heatlocked = Weapon:GetHeatLockout()
		-- end
	elseif Weapon.ArcCW then
		local arccw_mode = Weapon:GetCurrentFiremode()

		AltFiremodeText = Weapon:GetBuff_Override("UBGL_PrintName") and Weapon:GetBuff_Override("UBGL_PrintName") or ArcCW.GetTranslation("fcg.ubgl")
		
		if Weapon:GetInUBGL() then
			ActivePrimaryFire = false
		else
			FiremodeText = FindArcCWFiremode()
		end
		
		FiremodeText = string.upper(FiremodeText) 
		if string.match(FiremodeText, "-ROUND BURST") then
			string.Replace(FiremodeText, "-ROUND BURST", "-BURST")
		end
		
		if Weapon:GetMalfunctionJam() then
			WeaponJammed = true
			FiremodeText = "MALFUNCTIONING"
		end
	elseif ismgbase then
		-- FIXME: Fix Safety detection for the dev build of MWBase and make it also work for the public build.
		FiremodeText = Weapon:HasFlag("Lowered") and "Safety" or string.upper(Weapon.Firemodes[Weapon:GetFiremode()].Name)
		--[[for k,v in pairs(MWBaseFiremodes) do -- I am not localizing this shit
			if k == FiremodeText then
				FiremodeText = v
			end
		end]]

		ActivePrimaryFire = !Weapon:HasFlag("UsingUnderbarrel")
		AltFiremodeText = Weapon:GetUnderbarrel() != nil and Weapon:GetUnderbarrel().Name or ""
	elseif istfabase then
		FiremodeText = Weapon:GetFireModeName() -- Do we need two complicated tables for this?
		for k,v in pairs(TFAFiremodes) do
			if k == FiremodeText then
				FiremodeText = v
			end
		end
	elseif Weapon:IsScripted() then
		if !Weapon.Primary.Automatic then
			FiremodeText = language.GetPhrase("pkad_firemodes_semi")
		end
		
		if Weapon.ThreeRoundBurst then
			FiremodeText = language.GetPhrase("pkad_firemodes_burst"):format("3")
		end
		
		if Weapon.TwoRoundBurst then
			FiremodeText = language.GetPhrase("pkad_firemodes_burst"):format("2")
		end
		
		if Weapon.GetSafe then
			if Weapon:GetSafe() then
				FiremodeText = language.GetPhrase("pkad_firemodes_safety")
			end
		end
		
		if isfunction(Weapon.Safe) then
			if Weapon:Safe() then
				FiremodeText = language.GetPhrase("pkad_firemodes_safety")
			end
		end
		
		if isfunction(Weapon.Safety) then
			if Weapon:Safety() then
				FiremodeText = language.GetPhrase("pkad_firemodes_safety")
			end
		end

		AltFiremodeText = language.GetPhrase("pkad_altfire_placehold")
	elseif !VanillaAutomatics[Weapon:GetClass()] then
		FiremodeText = "Semi-Auto"
		AltFiremodeText = language.GetPhrase("pkad_altfire_placehold")
	end

	if isarc9 and input.LookupBinding("+arc9_ubgl") then
		ubglkey = "[" .. string.upper(input.LookupBinding("+arc9_ubgl", 1)) .. "]"
	elseif isarc9 then
		ubglkey = "[" .. usekey .."]+[" .. attack2 .. "]"
	elseif isweparccw and input.LookupBinding("arccw_toggle_ubgl") then
		ubglkey = "[" .. string.upper(input.LookupBinding("arccw_toggle_ubgl", 1)) .. "]"
	elseif isweparccw then
		ubglkey = "[" .. usekey .."]+[" .. reloadkey .. "]"
	elseif ismgbase then -- can you tell mwb is weird
		local inputpack = mw_input.GetUnpackedInputs(ply, "underbarrel")
		if !inputpack[1] then
			ubglkey = "[???]"
		else
			ubglkey = "[" .. language.GetPhrase(input.GetKeyName(inputpack[1])) .. "]" .. (inputpack[2] and ("+[" .. language.GetPhrase(input.GetKeyName(inputpack[2])) .. "]") or "")
		end
	else
		ubglkey = ""
	end

	if isarc9 then
		firemodekey = "[" .. string.upper(string.Replace(input.LookupBinding("+zoom", 1) or "", "MOUSE", "M"))  .. "]"
	elseif isweparccw then
		firemodekey = "[" .. string.upper(string.Replace(input.LookupBinding("arccw_firemode", 1) or input.LookupBinding("+zoom", 1) or "", "MOUSE", "M"))  .. "]"
	elseif ismgbase then
		local inputpack = mw_input.GetUnpackedInputs(ply, "firemode")
		if !inputpack[1] then
			firemodekey = "[???]"
		else
			firemodekey = "[" .. language.GetPhrase(input.GetKeyName(inputpack[1])) .. "]" .. (inputpack[2] and ("+[" .. language.GetPhrase(input.GetKeyName(inputpack[2])) .. "]") or "")
		end
	else
		firemodekey = ""
	end
end

local function PKAD2_ColorManager()
	usebeatruncolors = gamemodename == "beatrun" and beatruncolors:GetBool()

	if dynamic:GetBool() then
		hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
	else
		hidealpha = 0
	end
	corner_color_c = usebeatruncolors and string.ToColor(ply:GetInfo("Beatrun_HUDCornerColor")) or string.ToColor(ply:GetInfo("PKAD_CornerColor"))
	text_color = usebeatruncolors and string.ToColor(ply:GetInfo("Beatrun_HUDTextColor")) or string.ToColor(ply:GetInfo("PKAD_TextColor"))
	otherammocolor = string.ToColor("153 153 153 255")
	othertext = string.ToColor("255 255 255 255")
	ammobarcolor = usebeatruncolors and string.ToColor(ply:GetInfo(barsusecornercolor:GetBool() and "Beatrun_HUDCornerColor" or "Beatrun_HUDTextColor"))
		or (string.ToColor(ply:GetInfo("PKAD_AmmobarColor")))
	armorbackground = string.ToColor("110 110 110 128")
	ammolowcolor = string.ToColor(ply:GetInfo("PKAD_TextLowColor"))
	ammolowcolor1 = string.ToColor(ply:GetInfo("PKAD_TextLowInactiveColor"))
	healthcolor = string.ToColor(ply:GetInfo("PKAD_HealthColor"))
	armorcolor = string.ToColor(ply:GetInfo("PKAD_ArmorColor"))
	corner_color_c.a = math.Clamp(corner_color_c.a + 50, 0, 255)
	corner_color_c.a = dynamic:GetBool() and math.max(150 - hidealpha, 25) or corner_color_c.a
	ammolowcolor1.a = dynamic:GetBool() and math.max(100 - hidealpha, 25) or ammolowcolor.a
	ammolowcolor.a = dynamic:GetBool() and math.max(230 - hidealpha, 25) or ammolowcolor.a
	armorbackground.a = dynamic:GetBool() and math.max(255 - hidealpha, 25) or armorbackground.a
	ammobarcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or ammobarcolor.a
	othertext.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or othertext.a
	otherammocolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or otherammocolor.a
	text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a
	healthcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or healthcolor.a
	armorcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or armorcolor.a

	--math.sin(CurTime() * 2) * 255

	if WepClip1 < WepMag1 / 3 and !BottomlessMag then
		if !CurrentlyLowAmmo then
			CurrentlyLowAmmo = true
			LastLowAmmoFrame = CurTime()
		end
		ammolowpulsecolor.a = math.abs(math.sin((CurTime() - LastLowAmmoFrame) * 2) * 255)
	else
		CurrentlyLowAmmo = false
	end

	if WepReserve1 == 0 or WepReserve1 + math.Clamp(WepClip1, 0, 9999) == 0 then
		if !CurrentlyLowReserve then
			CurrentlyLowReserve = true
			LastLowReserveFrame = CurTime()
		end
		reservelowpulsecolor.a = math.abs(math.sin((CurTime() - LastLowReserveFrame) * 2) * 190)
	end

	if (WepClip2 < WepMag2 / 3 and !BottomlessMag and !InstantAltfire) or ((WepReserve2 + math.Clamp(WepClip2, 0, 9999)) == 0) then
		if !AltCurrentlyLowAmmo then
			AltCurrentlyLowAmmo = true
			AltLastLowAmmoFrame = CurTime()
		end
		altammolowpulsecolor.a = math.abs(math.sin((CurTime() - AltLastLowAmmoFrame) * 2) * 255)
	end

	if WepReserve2 == 0 then
		if !AltCurrentlyLowReserve then
			AltCurrentlyLowReserve = true
			AltLastLowReserveFrame = CurTime()
		end
		reservelowpulsecolor.a = math.abs(math.sin((CurTime() - AltLastLowReserveFrame) * 2) * 190)
	end
	
	if !ActivePrimaryFire then
		AmmoColor = otherammocolor
		AlternateAmmoColor = text_color
		LowAmmoColor = ammolowcolor1
		AlternateLowAmmoColor = ammolowcolor
	else
		AmmoColor = text_color
		AlternateAmmoColor = otherammocolor
		LowAmmoColor = ammolowcolor
		AlternateLowAmmoColor = ammolowcolor1
	end

	if WepClip1 < WepMag1 / 3 and !BottomlessMag then
		MagazineColor = LowAmmoColor
		MagBarColor = ammolowcolor
	else
		MagazineColor = AmmoColor
		MagBarColor = ammobarcolor
	end
	if WepReserve1 != 0 then
		ReserveColor = AmmoColor
	elseif InfiniteReserve then
		ReserveColor = AmmoColor
	else
		ReserveColor = LowAmmoColor
	end
		
	if (WepClip2 < WepMag2 / 3 and !BottomlessMag and !InstantAltfire) or ((WepReserve2 + math.Clamp(WepClip2, 0, 9999)) == 0) then
		AltfireColor = AlternateLowAmmoColor
		AltMagBarColor = ammolowcolor
	elseif InstantAltfire then
		AltfireColor = AlternateAmmoColor
		AltMagBarColor = ammobarcolor
	else
		AltfireColor = AlternateAmmoColor
		AltMagBarColor = ammobarcolor
	end
	if WepReserve2 != 0 and !InstantAltfire then
		AltReserveColor = AlternateAmmoColor
	elseif InfiniteReserve and !InstantAltfire then
		AltReserveColor = AlternateAmmoColor
	elseif InstantAltfire then
		AltReserveColor = AmmoColor
	else
		AltReserveColor = AlternateLowAmmoColor
	end
end

local function PKAD2_DrawPanels()
	local vp = ply:GetViewPunchAngles()
	if !sway:GetBool() then
		vp.x = 0
		vp.z = 0
	end

	local safezonex = scrw * deadzonex:GetFloat()
	local safezoney = scrh * deadzoney:GetFloat()

	local InfiniteReserve = false

	-- Infinite ammo detection. Works for ARC9 and ArcCW.
	if isarc9 and (Weapon:GetInfiniteAmmo() or GetConVar("arc9_infinite_ammo"):GetBool()) then
		InfiniteReserve = true
	elseif isweparccw and GetConVar("arccw_mult_infiniteammo"):GetBool() then
		InfiniteReserve = true
	end

	if InfiniteReserve and BottomlessMag then
		WepReserve1 = "∞"
		WepReserve2 = !isweparccw and "∞" or WepReserve2
	elseif InfiniteReserve then
		WepReserve1 = "inf"
		WepReserve2 = !isweparccw and "inf" or WepReserve2
	end

	surface.SetFont("PKAD_SmallText")
	local FiremodeW, FiremodeH = surface.GetTextSize(FiremodeText)
	local AltFiremodeW, AltFiremodeH = surface.GetTextSize(AltFiremodeText)
	
	if ply:IsValid() and ply:Alive() and !hidden:GetBool() then
		if IsValid(Weapon) and Weapon:GetPrimaryAmmoType() != -1 then
			surface.SetDrawColor(corner_color_c)
			surface.DrawRect(scrw - 18.88 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, 40 * scale, scale * 85)

			if WepClip1 < WepMag1 / 3 then
				surface.SetDrawColor(ammolowpulsecolor)
				surface.DrawRect(scrw - 176.64 * scale + vp.z - safezonex, scrh - 66.96 * scale + vp.x - safezoney, 150 * scale * MagFillRatio, scale * 5)
			end
			DrawBlurRect2(scrw - 218.88 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 200, scale * 85, math.max(255 - hidealpha, 2))
			surface.SetDrawColor(corner_color_c)
			surface.DrawOutlinedRect(scrw - 218.88 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 200, scale * 85, math.Clamp(scale, 1, 32767))
			local OverflowText = ""

			if !BottomlessMag then
				if OverCapacity > 0 then
					OverflowText = "+" .. OverCapacity
				end

				if WepReserve1 == 0 then
					local OverflowSizeW, OverflowSizeY = surface.GetTextSize(OverflowText)
					surface.SetFont("PKAD_BlurredBigText")
					local Reserve1W, Reserve1H = surface.GetTextSize("/" .. WepReserve1)
					surface.SetTextColor(reservelowpulsecolor)
					surface.SetTextPos(scrw - 26.88 * scale - Reserve1W + vp.z - safezonex, scrh - 97.2 * scale + vp.x - safezoney)
					surface.DrawText("/" .. WepReserve1)
				end

				local OverflowSizeW, OverflowSizeY = surface.GetTextSize(OverflowText)
				surface.SetFont("PKAD_BigText")
				local Reserve1W, Reserve1H = surface.GetTextSize("/" .. WepReserve1)
				surface.SetTextColor(ReserveColor)
				surface.SetTextPos(scrw - 26.88 * scale - Reserve1W + vp.z - safezonex, scrh - 97.2 * scale + vp.x - safezoney)
				surface.DrawText("/" .. WepReserve1)

				if WepClip1 < WepMag1 / 3 then
					surface.SetFont("PKAD_BlurredHugeText")
					local MagazineW, MagazineH = surface.GetTextSize(WepClip1)
					surface.SetTextPos(scrw - 26.88 * scale - Reserve1W - OverflowSizeW - MagazineW + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
					surface.SetTextColor(ammolowpulsecolor)
					surface.DrawText(WepClip1)
				end

				surface.SetFont("PKAD_HugeText")
				local MagazineW, MagazineH = surface.GetTextSize(WepClip1)
				surface.SetTextPos(scrw - 26.88 * scale - Reserve1W - OverflowSizeW - MagazineW + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
				surface.SetTextColor(MagazineColor)
				surface.DrawText(WepClip1)

				surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)
				surface.DrawRect(scrw - 176.64 * scale + vp.z - safezonex, scrh - 66.96 * scale + vp.x - safezoney, 150 * scale, scale * 2.55)	

				surface.SetDrawColor(MagBarColor)
				surface.DrawRect(scrw - 176.64 * scale + vp.z - safezonex, scrh - 66.96 * scale + vp.x - safezoney, 150 * scale * MagFillRatio, scale * 5)
				surface.SetDrawColor(255, 225, 0, ammobarcolor.a)
				surface.DrawRect(scrw - 176.64 * scale + vp.z - safezonex, scrh - 61.96 * scale + vp.x - safezoney, 150 * scale * OverfillRatio, scale * 2)

				surface.SetFont("PKAD_SmallText")
				surface.SetTextPos(scrw - 26.88 * scale - Reserve1W - OverflowSizeW + vp.z - safezonex, scrh - 97.2 * scale + vp.x - safezoney)
				surface.DrawText(OverflowText)

				surface.SetTextColor(AmmoColor)
				if WeaponJammed then
					surface.SetTextColor(255, 0, 0, text_color.a)
				end
				surface.SetFont("PKAD_SmallText")
				surface.SetTextPos(scrw - 28 * scale - FiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(FiremodeText))

				surface.SetTextColor(color_white)
				surface.SetTextPos(scrw - 217 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(firemodekey))
			elseif BottomlessMag then
				surface.SetFont("PKAD_HugeText")
				local MagazineW, MagazineH = surface.GetTextSize(!InfiniteReserve and (WepReserve1 + math.Clamp(WepClip1, 0, 9999)) or WepReserve1)

				if !InfiniteReserve and (WepReserve1 + math.Clamp(WepClip1, 0, 9999) == 0) then
					local OverflowSizeW, OverflowSizeY = surface.GetTextSize(OverflowText)
					local Reserve1W, Reserve1H = surface.GetTextSize(WepReserve1 + math.Clamp(WepClip1, 0, 9999))
					surface.SetTextColor(reservelowpulsecolor)
					surface.SetTextPos(scrw * 0.986 - MagazineW + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
					surface.DrawText(WepReserve1 + math.Clamp(WepClip1, 0, 9999))
				end

				surface.SetFont("PKAD_HugeText")
				surface.SetTextPos(scrw * 0.986 - MagazineW + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
				surface.SetTextColor(MagazineColor)
				surface.DrawText(!InfiniteReserve and (WepReserve1 + math.Clamp(WepClip1, 0, 9999)) or WepReserve1)
				
				surface.SetDrawColor(MagBarColor)
				surface.DrawRect(scrw * 0.908 + vp.z - safezonex, scrh - 66.96 * scale + vp.x - safezoney, 150 * scale, scale * 5)
				
				surface.SetTextColor(AmmoColor)
				surface.SetFont("PKAD_SmallText")
				surface.SetTextPos(scrw - 26.88 * scale - FiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(FiremodeText))

				surface.SetTextColor(color_white)
				surface.SetTextPos(scrw - 217 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(firemodekey))
			end

			if HasAltFire and InstantAltfire then
				surface.SetDrawColor(corner_color_c)
				surface.DrawRect(scrw - 260.512 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, 25 * scale, scale * 85)
				DrawBlurRect2(scrw - 419.174 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 161, scale * 85, math.max(255 - 	hidealpha, 2))
				surface.SetDrawColor(corner_color_c)
				surface.DrawOutlinedRect(scrw - 419.174 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 161, scale * 85, math.Clamp(scale, 1, 32767))
			
				surface.SetFont("PKAD_HugeText")
				local Reserve2H, Reserve2W = surface.GetTextSize((WepReserve2 + math.Clamp(WepClip2, 0, 9999)))
				surface.SetTextPos(scrw - 268 * scale - Reserve2H + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
				surface.SetTextColor(AltfireColor)
				surface.DrawText((WepReserve2 + math.Clamp(WepClip2, 0, 9999)))
			
				surface.SetDrawColor(AltMagBarColor)					
				surface.DrawRect(scrw - 368 * scale + vp.z - safezonex, scrh - 66.96 * scale + 1 + vp.x - safezoney, 100 * scale, scale * 5)
			
				surface.SetTextColor(AlternateAmmoColor)
				surface.SetFont("PKAD_SmallText")
				surface.SetTextPos(scrw - 268 * scale - AltFiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(AltFiremodeText))
			
				surface.SetTextColor(255,255,255,othertext.a)
				surface.SetTextPos(scrw - 418 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(ubglkey))
			elseif HasAltFire and !InstantAltfire then
				surface.SetDrawColor(corner_color_c)
				surface.DrawRect(scrw - 260.512 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, 25 * scale, scale * 85)
				DrawBlurRect2(scrw - 419.174 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
				surface.SetDrawColor(corner_color_c)
				surface.DrawOutlinedRect(scrw - 419.174 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 161, scale * 85, math.Clamp(scale, 1, 32767))
				
				surface.SetFont("PKAD_BigText")
				local Reserve2W, Reserve2H = surface.GetTextSize("/" .. WepReserve2)
				surface.SetTextPos(scrw - 268 * scale - Reserve2W + vp.z - safezonex, scrh - 97.2 * scale + vp.x - safezoney)
				surface.SetTextColor(AltReserveColor)
				surface.DrawText("/" .. WepReserve2)

				local OverflowAltText = ""
				if OverAltCapacity > 0 then
					OverflowAltText = "+" .. OverAltCapacity
				end
				local OverflowAltSizeW, OverflowAltSizeY = surface.GetTextSize(OverflowAltText)
				surface.SetFont("PKAD_SmallText")
				surface.SetTextPos(scrw - 268 * scale - Reserve2W - OverflowAltSizeW + vp.z - safezonex, scrh - 97.2 * scale + vp.x - safezoney)
				surface.DrawText(OverflowAltText)
				
				surface.SetFont("PKAD_HugeText")
				local AltfireW, AltfireH = surface.GetTextSize(WepClip2)
				surface.SetTextPos(scrw - 268 * scale - Reserve2W - AltfireW - OverflowAltSizeW + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
				surface.SetTextColor(AltfireColor)
				surface.DrawText(WepClip2)
				
				surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)					
				surface.DrawRect(scrw - 368 * scale + vp.z - safezonex, scrh - 66.96 * scale + 1 + vp.x - safezoney, 100 * scale, scale * 2.55)
				surface.SetDrawColor(AltMagBarColor)
				surface.DrawRect(scrw - 368 * scale + vp.z - safezonex, scrh - 66.96 * scale + 1 + vp.x - safezoney, 100 * scale * AltFillRatio, scale * 5)
				surface.SetDrawColor(255, 225, 0, ammobarcolor.a)
				surface.DrawRect(scrw - 176.64 * scale + vp.z - safezonex, scrh - 61.96 * scale + vp.x - safezoney, 150 * scale * AltOverfillRatio, scale * 2)
			
				surface.SetTextColor(AlternateAmmoColor)
				surface.SetFont("PKAD_SmallText")
				surface.SetTextPos(scrw - 268 * scale - AltFiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(AltFiremodeText))
			
				surface.SetTextColor(255,255,255,othertext.a)
				surface.SetTextPos(scrw - 418 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(string.upper(ubglkey))
			end
		end

		if enablehealth:GetBool() then
			local healthratio = math.min(ply:Health() / ply:GetMaxHealth(), 1)
			local overhealth = math.max((ply:Health() / ply:GetMaxHealth()) - 1, 0)
			local ArmorRatio = math.min(ply:Armor() / ply:GetMaxArmor(), 1)
			local OverArmor = math.max((ply:Armor() / ply:GetMaxArmor()) - 1, 0)

			DrawBlurRect2(21.12 * scale + vp.z + safezonex, scrh - 91.4 * scale + vp.x - safezoney, scale * 227, scale * 63, math.max(255 - hidealpha, 2))
			surface.SetDrawColor(corner_color_c)
			surface.DrawRect(-18.88 * scale + vp.z + safezonex, scrh - 91.4 * scale + vp.x - safezoney, 40 * scale, scale * 63)
			surface.DrawOutlinedRect(21.12 * scale + vp.z + safezonex, scrh - 91.4 * scale + vp.x - safezoney, scale * 227, scale * 63, math.Clamp(scale, 1, 32767))

			surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)					
			surface.DrawRect(30 * scale + vp.z + safezonex, scrh - 68.96 * scale + vp.x - safezoney, 210 * scale, scale * 2.55)
			surface.SetDrawColor(healthratio > 1 / 3 and healthcolor or ammolowcolor)
			surface.DrawRect(30 * scale + vp.z + safezonex, scrh - 68.96 * scale + vp.x - safezoney, 210 * scale * healthratio, scale * 7)
			surface.SetDrawColor(255, 225, 0, healthcolor.a)
			surface.DrawRect(30 * scale + vp.z + safezonex, scrh - 62.96 * scale + vp.x - safezoney, 210 * scale * overhealth, scale * 2)
			
			surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)					
			surface.DrawRect(30 * scale + vp.z + safezonex, scrh - 76.96 * scale + vp.x - safezoney, 210 * scale, scale * 2.55)
			surface.SetDrawColor(armorcolor)
			surface.DrawRect(30 * scale + vp.z + safezonex, scrh - 76.96 * scale + vp.x - safezoney, 210 * scale * ArmorRatio, scale * 5)
			surface.SetDrawColor(255, 225, 0, armorcolor.a)
			surface.DrawRect(30 * scale + vp.z + safezonex, scrh - 77.96 * scale + vp.x - safezoney, 210 * scale * OverArmor, scale * 4)
			
			if ply.GetStims then
				surface.SetMaterial(healthpack)
				surface.SetDrawColor(255,255,255,othertext.a)
				surface.DrawTexturedRect(30 * scale + vp.z + safezonex, scrh - 54.96 * scale + vp.x - safezoney, 20 * scale, 20 * scale)
				surface.SetTextColor(255,255,255,othertext.a)
				surface.SetTextPos(55 * scale + vp.z + safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(ply:GetStims())
			end

			if ply.GetArmorPlates or GetConVar("wz_armorsys_armorplates_maxcarry") then
				surface.SetMaterial(armorplate)
				surface.SetDrawColor(255,255,255,othertext.a)
				surface.DrawTexturedRect((30 + (ply.GetStims and 65 or 0)) * scale + vp.z + safezonex, scrh - 54.96 * scale + vp.x - safezoney, 20 * scale, 20 * scale)
				surface.SetTextColor(255,255,255,othertext.a)
				surface.SetTextPos((55 + (ply.GetStims and 65 or 0)) * scale + vp.z + safezonex, scrh - 54 * scale + vp.x - safezoney)
				surface.DrawText(ply.GetArmorPlates and ply:GetArmorPlates() or GetConVar("wz_armorsys_armorplates_maxcarry") and ply:GetAmmoCount("WZ_ARMORPLATE"))
			end

			local w = select(1, surface.GetTextSize(ply:Health() .. "+" .. ply:Armor()))
			surface.SetTextColor(255,255,255,othertext.a)
			surface.SetTextPos(240 * scale - w + vp.z + safezonex, scrh - 54 * scale + vp.x - safezoney)
			surface.DrawText(ply:Health() .. "+" .. ply:Armor())
		end
	end
end

-- Hooks
hook.Add("HUDShouldDraw", "PKAD2_HideHL2HUD", function(name)
    if hidden:GetBool() then return end 
    if hide[name] then return false end
end)

hook.Add("OnScreenSizeChanged", "PKAD2_RecreateFonts", function()
	scale = ScrH() / 1080 * UserScale:GetFloat()
	PKAD2_InitFonts()

	scrw = ScrW()
	scrh = ScrH()
end)

PKAD2_InitFonts() -- Prevents Lua errors (maybe)
hook.Add("HUDPaint", "PKAD2_Draw", function()
	PKAD2_GetWeaponData()

	if IsValid(Weapon) then
		PKAD2_GetFiremode()
		PKAD2_ColorManager()
		PKAD2_DrawPanels()
	end
end)

concommand.Add("PKAD_ReloadFonts", PKAD2_InitFonts)