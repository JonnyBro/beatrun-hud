-- i forgot to do git push last time lmfao, anyway here we go

local TFAModeKeys = {
	[0] = "",
	[1] = "0", 
	[2] = "1",
	[3] = "2",
	[4] = "3", 
	[5] = "4",
	[6] = "5",
	[7] = "6", 
	[8] = "7",
	[9] = "8",
	[10] = "9", 
	[11] = "A",
	[12] = "B",
	[13] = "C", 
	[14] = "D",
	[15] = "E",
	[16] = "F", 
	[17] = "G",
	[18] = "H",
	[19] = "I", 
	[20] = "J",
	[21] = "K",
	[22] = "L", 
	[23] = "M",
	[24] = "N",
	[25] = "O", 
	[26] = "P",
	[27] = "Q",
	[28] = "R", 
	[29] = "S",
	[30] = "T",
	[31] = "U", 
	[32] = "V",
	[33] = "W",
	[34] = "X", 
	[35] = "Y",
	[36] = "Z",
	[37] = "NPAD 0",
	[38] = "NPAD 1", 
	[39] = "NPAD 2",
	[40] = "NPAD 3",
	[41] = "NPAD 4", 
	[42] = "NPAD 5",
	[43] = "NPAD 6",
	[44] = "NPAD 7", 
	[45] = "NPAD 8",
	[46] = "NPAD 9",
	[47] = "NPAD /", 
	[48] = "NPAD *",
	[49] = "NPAD -",
	[50] = "NPAD +", 
	[51] = "NPAD ENTER",
	[52] = "NPAD .",
	[53] = "(", 
	[54] = ")",
	[55] = ";",
	[56] = "'", 
	[57] = "`",
	[58] = ",",
	[59] = ".", 
	[60] = "/",
	[61] = "\\",
	[62] = "-", 
	[63] = "=",
	[64] = "ENTER",
	[65] = "SPACE", 
	[66] = "BKSPC",
	[67] = "TAB",
	[68] = "CAPSLOCK", 
	[69] = "NUMLOCK",
	[70] = "ESCAPE",
	[71] = "SCRLOCK", 
	[72] = "INS",
	[73] = "DEL",
	[74] = "HOME", 
	[75] = "END",
	[76] = "PGUP",
	[77] = "PGDN", 
	[78] = "PAUSE",
	[79] = "LSHFT",
	[80] = "RSHFT", 
	[81] = "LALT",
	[82] = "RALT",
	[83] = "LCTRL", 
	-- 84 and 85 needs special Linux and macOS cases. Mac keyboards have Command and Linux uses "Menu", though I haven't see a dedicated
	-- Linux Menu key on any keyboard in my life yet.
	[84] = "RCTRL",
	[85] = "LWIN",
	[86] = "RWIN", 
	[87] = "APP",
	[88] = "UARRW",
	[89] = "LARRW", 
	[90] = "DARRW",
	[91] = "RARRW",
	[92] = "F1",
	[93] = "F2",
	[94] = "F3",
	[95] = "F4", 
	[96] = "F5",
	[97] = "F6",
	[98] = "F7", 
	[99] = "F8",
	[100] = "F9",
	[101] = "F10", 
	[102] = "F11",
	[103] = "F12",
	[104] = "CLOCKTGGL", 
	[105] = "NLOCKTGGL",
	[106] = "SLOCKTGGL",
	[107] = "M1", 
	[108] = "M2",
	[109] = "M3",
	[110] = "M4", 
	[111] = "M5",
	[112] = "MWUP",
	[113] = "MWDN"
}

local CPPAltfireWeps = {
	["Weapon_smg1"] = true,
	["Weapon_ar2"] = true,
	["Weapon_mp5_hl1"] = true
}  

local MWBaseFiremodes = {
    ["AUTOMATIC"] = "Full-Auto", 
	["FULL AUTO"] = "Full-Auto",
	["SEMI AUTO"] = "Semi-Auto",
	["SEMI AUTOMATIC"] = "Semi-Auto",
	["3RND BURST"] = "3-Burst"
}

local TFAFiremodes = {
    ["Full-Auto"] = "Full-Auto", 
	["Semi-Auto"] = "Semi-Auto",
	["3 Round Burst"] = "3-Burst"
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
local sway = CreateClientConVar("PKAD_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAD_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local UserScale = CreateClientConVar("PKAD_Scale", "1", true, false, "Define your own scaling!")
local playername = ""
local ply = nil
local scale = ScrH() / 1080 * UserScale:GetFloat()
local scrw = ScrW()
local scrh = ScrH()
CreateClientConVar("PKAD_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
CreateClientConVar("PKAD_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
CreateClientConVar("PKAD_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
CreateClientConVar("PKAD_BlurTintColor", "0 0 0 0", true, false, "Blur tint color. Helps with visibility. Only works with blur enabled./n Alpha value is locked, sorry!")

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
local FiremodeText = "Full-Auto"
local AltFiremodeText = "Altfire"
local ActivePrimaryFire = true
local InstantAltfire = false

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

-- Variables: Textures and the like
local blur = Material("pp/blurscreen")

local ARC9Installed = false
local ArcCWInstalled = false
local TFAInstalled = false

local hide = {
    CHudBattery = GetConVar("PKAD_Hidden"):GetBool(),
    CHudAmmo = true,
    CHudWepClip2 = true
}

-- Functions.
local function DrawBlurRect2(x, y, w, h, a, f) -- NEW: i is intensity. Adjust by multiples of 5.
	if render.GetDXLevel() < 90 or GetConVar("PKAmmoDisp_NoBlur"):GetBool() then
		surface.SetDrawColor(80,80,80,50)
		surface.DrawRect(x,y,w,h)
	else
		local X = 0
		local Y = 0
		local intensity = 20
		if f != nil then intensity = f end
		
		surface.SetDrawColor(255, 255, 255, a)
		surface.SetMaterial(blur)
		
		for i = 1, 2 do
			--blur:SetFloat("$blur", i / 3 * 5)
			blur:SetFloat("$blur", i / 12 * intensity)
			blur:Recompute()
			
			render.UpdateScreenEffectTexture()
			render.SetScissorRect(x, y, x + w, y + h, true)
			
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
			
			render.SetScissorRect(0, 0, 0, 0, false)
		end

		BlurTintColor = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_BlurTintColor"))
		BlurTintColor.a = dynamic:GetBool() and math.max(50 - hidealpha, 0) or BlurTintColor.a
		surface.SetDrawColor(BlurTintColor)
		surface.DrawRect(x,y,w,h)
		--print(tostring(BlurTintColor))
	end
end

function PKAD2_InitFonts()
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
end

function GetA9FiremodeName()
	AltFiremodeText = Weapon:GetProcessedValue("UBGLFiremodeName")

	if Weapon:GetUBGL() then
		ActivePrimaryFire = false
	else
	end
	
	local arc9_mode = Weapon:GetCurrentFiremodeTable()
	local FiremodeText = "UNKNOWN"
	
	if arc9_mode.PrintName then
		FiremodeText = arc9_mode.PrintName
	else
		if arc9_mode.Mode == 1 then
			FiremodeText = "Semi-Auto"
		elseif arc9_mode.Mode == 0 then
			FiremodeText = "Safety"
		elseif arc9_mode.Mode < 0 then
			FiremodeText = "Full-Auto"
		elseif arc9_mode.Mode > 1 then
			FiremodeText = tostring(arc9_mode.Mode) .. "-Burst"
		end
	end
	
	if Weapon:GetSafe() then
		FiremodeText = "Safety"
	end
	
	return FiremodeText
end
function GetCWFiremodeName()
	if Weapon:GetBuff_Hook("Hook_FiremodeName") then return Weapon:GetBuff_Hook("Hook_FiremodeName") end
	
	local abbrev = GetConVar("arccw_hud_fcgabbrev"):GetBool() and ".abbrev" or ""

	AltFiremodeText = Weapon:GetBuff_Override("UBGL_PrintName") and Weapon:GetBuff_Override("UBGL_PrintName") or ArcCW.GetTranslation("fcg.ubgl" .. abbrev)

	if Weapon:GetInUBGL() then
		ActivePrimaryFire = false
	end

	local fm = Weapon:GetCurrentFiremode()

	if fm.PrintName then
		local phrase = ArcCW.GetPhraseFromString(fm.PrintName)
		return phrase and ArcCW.GetTranslation(phrase .. abbrev) or ArcCW.TryTranslation(fm.PrintName)
	end

	local mode = fm.Mode
	if mode == 0 then return "Safety" end
	if mode == 1 then return "Semi-Auto" end
	if mode >= 2 then return "Full-Auto" end
	if mode < 0 then return tostring(-mode) .. "-Burst" end
end

function PKAD2_GetWeaponData()
	ply = LocalPlayer()
	Weapon = ply:GetActiveWeapon()

	if IsValid(Weapon) then
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
	end
end

function PKAD2_GetFiremode()
	local ismgbase = false
	local isarc9 = Weapon.ARC9
	local inarc9cust = isarc9 and Weapon:GetCustomize()
	local isweparccw = Weapon.ArcCW
	local istfabase = Weapon.IsTFAWeapon
	ActivePrimaryFire = true

	if Weapon:IsScripted() and WepMag2 == -1 then 
		InstantAltfire = true
	elseif !Weapon:IsScripted() then 
		InstantAltfire = true
	else
		InstantAltfire = false
	end

	if string.match(tostring(WeaponClass), "mg_") and !isarc9 and !isweparccw then -- I have ZERO other fucking clue as to how to detect MW Base as it's barely documented.
		ismgbase = true
	else
		ismgbase = false
	end

	if isarc9 then -- Biggest blunder ever: forgor to change a9 to isarc9. bruh.
		local arc9_mode = Weapon:GetCurrentFiremodeTable()
		
		FiremodeText = GetA9FiremodeName()
		
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
		end
		
		if Weapon:GetProcessedValue("Overheat", true) then
			arc9showheat = true
			heat = Weapon:GetHeatAmount()
			heatcap = Weapon:GetProcessedValue("HeatCapacity")
			heatlocked = Weapon:GetHeatLockout()
		end
	elseif Weapon.ArcCW then
		local arccw_mode = Weapon:GetCurrentFiremode()
		
		FiremodeText = GetCWFiremodeName()
		
		if string.match(FiremodeText, "-round burst") then
			string.Replace(FiremodeText, "-round burst", "-BURST")
		elseif string.match(FiremodeText, "-ROUND BURST") then -- bruh case sensitivity is a thing
			string.Replace(FiremodeText, "-ROUND BURST", "-BURST")
		end

		FiremodeText = string.upper(FiremodeText) 

		if Weapon:GetMalfunctionJam() then
			WeaponJammed = true
		end
	elseif ismgbase then
		-- FIXME: Fix Safety detection for the dev build of MWBase and make it also work for the public build.
		FiremodeText = string.upper(Weapon.Firemodes[Weapon:GetFiremode()].Name) -- Do we need two complicated tables for this?
		for k,v in pairs(MWBaseFiremodes) do
			if k == FiremodeText then
				FiremodeText = v
			end
		end
	elseif istfabase then
		FiremodeText = Weapon:GetFireModeName() -- Do we need two complicated tables for this?
		for k,v in pairs(TFAFiremodes) do
			if k == FiremodeText then
				FiremodeText = v
			end
		end
		-- It's a miracle how all of these bases don't conflict regarding their GetFiremode() or equivalent function.
	elseif Weapon:IsScripted() then
		if !Weapon.Primary.Automatic then
			FiremodeText = "Semi-Auto"
		end
		
		if Weapon.ThreeRoundBurst then
			FiremodeText = "3-Burst"
		end
		
		if Weapon.TwoRoundBurst then
			FiremodeText = "2-Burst"
		end
		
		if Weapon.GetSafe then
			if Weapon:GetSafe() then
				FiremodeText = "Safety"
			end
		end
		
		if isfunction(Weapon.Safe) then
			if Weapon:Safe() then
				FiremodeText = "Safety"
			end
		end
		
		if isfunction(Weapon.Safety) then
			if Weapon:Safety() then
				FiremodeText = "Safety"
			end
		end
	elseif !VanillaAutomatics[Weapon:GetClass()] then
		FiremodeText = "Semi-Auto"
	end

	if !isarc9 and !Weapon.ArcCW then AltFiremodeText = "Altfire" end

	if isarc9 and !IsInputBound("+arc9_ubgl") then
		ubglkey = "[" .. usekey .."]+" .. "[" .. attack2 .. "]"
	elseif isarc9 and IsInputBound("+arc9_ubgl") then
		ubglkey = "[" .. string.upper(input.LookupBinding("+arc9_ubgl", 1)) .. "]"
	elseif isweparccw and IsInputBound("arccw_toggle_ubgl") then
		ubglkey = "[" .. string.upper(input.LookupBinding("arccw_toggle_ubgl", 1)) .. "]"
	elseif isweparccw then
		ubglkey = "[" .. usekey .."]+" .. "[" .. reloadkey .. "]"
	end
end

function PKAD2_ColorManager()
	if dynamic:GetBool() then
		hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
	else
		hidealpha = 0
	end
	corner_color_c = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_CornerColor"))
	text_color = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_TextColor"))
	otherammocolor = string.ToColor("153 153 153 255")
	othertext = string.ToColor("255 255 255 255")
	ammobarcolor = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2)
	armorbackground = string.ToColor("110 110 110 128")
	ammolowcolor = string.ToColor("255 0 0 230")
	ammolowcolor1 = string.ToColor("100 50 50 100")
	corner_color_c.a = math.Clamp(corner_color_c.a + 50, 0, 255)
	corner_color_c.a = dynamic:GetBool() and math.max(150 - hidealpha, 25) or corner_color_c.a
	ammolowcolor1.a = dynamic:GetBool() and math.max(100 - hidealpha, 25) or ammolowcolor.a
	ammolowcolor.a = dynamic:GetBool() and math.max(230 - hidealpha, 25) or ammolowcolor.a
	armorbackground.a = dynamic:GetBool() and math.max(255 - hidealpha, 25) or armorbackground.a
	ammobarcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or ammobarcolor.a
	othertext.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or othertext.a
	otherammocolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or otherammocolor.a
	text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a
	
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

function PKAD2_AmmoPanels()
	local vp = ply:GetViewPunchAngles()
	if !sway:GetBool() then
		vp.x = 0
		vp.z = 0
	end

	local safezonex = scrw * deadzonex:GetFloat()
	local safezoney = scrh * deadzoney:GetFloat()

	surface.SetFont("PKAD_SmallText")
	local FiremodeW, FiremodeH = surface.GetTextSize(FiremodeText)
	local AltFiremodeW, AltFiremodeH = surface.GetTextSize(AltFiremodeText)
	
	if IsValid(Weapon) and ply:IsValid() and ply:Alive() and Weapon:GetPrimaryAmmoType() != -1 and !hidden:GetBool() then
		surface.SetDrawColor(corner_color_c)
		surface.DrawRect(scrw - 18.88 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, 40 * scale, scale * 85)
		DrawBlurRect2(scrw - 218.88 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 200, scale * 85, math.max(255 - hidealpha, 2))
		surface.SetDrawColor(corner_color_c)
		surface.DrawOutlinedRect(scrw - 218.88 * scale + vp.z - safezonex, scrh - 113.4 * scale + vp.x - safezoney, scale * 200, scale * 85, math.Clamp(scale, 1, 32767))

		if !BottomlessMag then
			local OverflowText = ""
			if OverCapacity > 0 then
				OverflowText = "+" .. OverCapacity
			end

			local OverflowSizeW, OverflowSizeY = surface.GetTextSize(OverflowText)
			surface.SetFont("PKAD_BigText")
			local Reserve1W, Reserve1H = surface.GetTextSize("/" .. WepReserve1)
			surface.SetTextColor(ReserveColor)
			surface.SetTextPos(scrw - 26.88 * scale - Reserve1W + vp.z - safezonex, scrh - 97.2 * scale + vp.x - safezoney)
			surface.DrawText("/" .. WepReserve1)

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

			surface.SetTextColor(AlternateAmmoColor)
			if WeaponJammed then
				surface.SetTextColor(255, 0, 0, text_color.a)
			end
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 28 * scale - FiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
			surface.DrawText(string.upper(FiremodeText))

			--surface.SetTextPos(scrw - 214.88 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - --safezoney)
			--surface.SetTextColor(255,255,255,othertext.a)
			--surface.DrawText(firemodekey)

			--if !InstantAltfire then
			--	surface.SetDrawColor(128,68,92,255)
			--	surface.DrawRect(28,28,28,28)
			--end
		elseif BottomlessMag then
			--local Reserve1W, Reserve1H = surface.GetTextSize(WepReserve1)
			--surface.SetTextColor(ReserveColor)
			--surface.SetTextPos((scrw * 0.986) - Reserve1W + vp.z, scrh - 97.2 * scale + vp.x)
			--surface.DrawText(WepReserve1)
			
			surface.SetFont("PKAD_HugeText")
			local MagazineW, MagazineH = surface.GetTextSize(WepReserve1 + math.Clamp(WepClip1, 0, 9999))
			surface.SetTextPos(scrw * 0.986 - MagazineW + vp.z - safezonex, scrh - 108 * scale + vp.x - safezoney)
			surface.SetTextColor(MagazineColor)
			surface.DrawText(WepReserve1 + math.Clamp(WepClip1, 0, 9999))
			
			surface.SetDrawColor(MagBarColor)
			surface.DrawRect(scrw * 0.908 + vp.z - safezonex, scrh - 66.96 * scale + vp.x - safezoney, 150 * scale, scale * 5)
			
			surface.SetTextColor(AlternateAmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 26.88 * scale - FiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
			surface.DrawText(pkad_firemode_text)
			
			--surface.SetTextPos(scrw - 218.88 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - --safezoney)
			--surface.SetTextColor(255,255,255,othertext.a)
			--surface.DrawText(firemodekey)
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
		
			surface.SetTextColor(AmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 268 * scale - AltFiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
			surface.DrawText(string.upper(AltFiremodeText))
		
			surface.SetTextColor(255,255,255,othertext.a)
			surface.SetTextPos(scrw - 414.72 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
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
		
			surface.SetTextColor(AmmoColor)
			surface.SetFont("PKAD_SmallText")
			surface.SetTextPos(scrw - 268 * scale - AltFiremodeW + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
			surface.DrawText(string.upper(AltFiremodeText))
		
			surface.SetTextColor(255,255,255,othertext.a)
			surface.SetTextPos(scrw - 414.72 * scale + vp.z - safezonex, scrh - 54 * scale + vp.x - safezoney)
			surface.DrawText(string.upper(ubglkey))
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

hook.Add("HUDPaint", "PKAD2_Draw", function()
	PKAD2_GetWeaponData()

	if !IsValid(Weapon) then return end
	PKAD2_GetFiremode()
	PKAD2_ColorManager()
	PKAD2_AmmoPanels()
	--print(FiremodeText)
end)

PKAD2_InitFonts()