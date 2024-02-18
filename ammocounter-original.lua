-- Outdated implementation. Don't use unless you KNOW what the hell you're doing.
local hidden = CreateClientConVar("PKAmmoDisp_Hide", "0", true, false, "Blocks the ammo counter from rendering", 0, 2)
local sway = CreateClientConVar("PKAmmoDisp_Sway", "1", true, false, "Display HUD swaying", 0, 1)
local dynamic = CreateClientConVar("PKAmmoDisp_Dynamic", "0", true, false, "Hide HUD when moving (why the frick would you enable this?)", 0, 1)
local showspeed = CreateClientConVar("PKAmmoDisp_Speedometer", "0", true, false, "Show a speedometer at the bottom of the display", 0, 1)
local ProcessFiremode = CreateClientConVar("PKAmmoDisp_ProcessFiremode", "0", true, false, "Process the firemode before displaying. I do not recommend using this./n FUN FACT: It appears you can't directly get what firemode you're using for ArcCW weapons, so this WAS used for consistency.", 0, 1)
local PerfDisplay = CreateClientConVar("PKAmmoDisp_PerfDisplay", "1", true, false, "Displays some miscellaneous stuff on your monitor/game window's top right.")
local NoBlur = CreateClientConVar("PKAmmoDisp_NoBlur", "0", true, false, "Disables blur effects. Only works on DX9+ (Windows) and Linux, as blur doesn't work with DX8 and below. Gives like 2fps or something. Does not affect Beatrun.")
--CreateClientConVar("PKAmmoDisp_DeadzoneX", "0", true, false, "Use this HUD while playing on your HDTV!", 0, 0.5)
--CreateClientConVar("PKAmmoDisp_DeadzoneY", "0", true, false, "Use this HUD while playing on your HDTV!", 0, 0.5)

local scale = ScrH() / 1080
local framerate = 0

function IsInputBound(bind) -- Renamed ARC9 function. Don't wanna cause conflicts.
    local key = input.LookupBinding(bind)

    if !key then
        return falsedddddddddd
    else
        return true
    end
end

function DoesConVarExist(luavar)
    local var = GetConVar(luavar)

    if !var then
        return false
    else
        return true
    end
end

local IsPlayingBeatrun = false
if DoesConVarExist("Beatrun_FOV") then -- This is my best fricking idea on how to detect non-vanilla Beatrun.
    IsPlayingBeatrun = true
end

local ARC9Installed = false
local ArcCWInstalled = false
local TFAInstalled = false

-- Does the user have the supported weapon bases installed?
if DoesConVarExist("arc9_precache_sounds_onfirsttake") then
    print("ARC9 is installed!")             -- ARC9
    ARC9Installed = true
end
if DoesConVarExist("arccw_automaticreload") then
    print("ArcCW is installed!")            -- ArcCW (aka Arctic's Customizable Weaponry)
    ArcCWInstalled = true
end
if DoesConVarExist("cl_tfa_hud_enabled") then
    print("TFA Base is installed!")         -- TFA Base
    TFAInstalled = true
end

local hide = {
    CHudAmmo = true,
    CHudSecondaryAmmo = true
}

local SpecialWeaponFiremode = {
    "mg_357"
}

local SpecialCorrespondingFiremode = {
    "DOUBLE-ACTION"
}

local ArcPossibleFiremodes = {
	"AUTO",
	"SEMI",
	"SAFE",
    "UB",
    "FRCD",
    "SINGLE",
    "2-BST",
    "3-BST",
    "2-BURST",
    "3-BURST",
    "DACT",
    "SACT",
    "LOW"
}

local ArcFiremodeDisplay = {
	"FULL AUTO",
	"SEMI AUTO",
	"SAFETY",
    "UNDERBARREL",
    "FORCED AUTO",
    "SEMI AUTO",
    "2-BURST",
    "3-BURST",
    "2-BURST",
    "3-BURST",
    "DOUBLE-ACTION",
    "SINGLE-ACTION",
    "LOWERED"
}

hook.Add("HUDShouldDraw", "hidefunnyshit", function(name)
    if hidden:GetBool() then return end
	if hide[name] then return false end
end)

function PKAmmoDisp_InitFonts()
    surface.CreateFont("funnitextbeeg", {
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

    surface.CreateFont("funnitexttiny", {
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

    surface.CreateFont("funnitexthuge", {
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

    surface.CreateFont("DebugTextScale", {
        shadow = false,
    	blursize = 0,
    	underline = false,
    	rotary = false,
    	strikeout = false,
    	additive = false,
    	antialias = true,
    	extended = false,
    	scanlines = 0,
    	font = "x14y24pxHeadUpDaisy", -- WE ARE NOT DEALING WITH LICENSING COURIER NEW
    	italic = false,
    	outline = false,
    	symbol = false,
    	weight = 250,
    	size = 15 * scale
    })
end

PKAmmoDisp_InitFonts()

hook.Add( "OnScreenSizeChanged", "UpdateFonts", function()
    PKAmmoDisp_InitFonts()
end )

print(ScreenScale(7) .. " | " .. ScreenScale(6) .. " | "  .. ScreenScale(12))

function GetCurrentFiremodeTable()
    local fm = self:GetFiremode()

    if fm > #self:GetValue("Firemodes") then
        fm = 1
        self:SetFiremode(fm)
    end

    return self:GetValue("Firemodes")[fm]
end

local blur = Material("pp/blurscreen")

local function DrawBlurRect2(x, y, w, h, a)
    if render.GetDXLevel() < 90 or GetConVar("PKAmmoDisp_NoBlur"):GetBool() then
        surface.SetDrawColor(80,80,80,50)
        surface.DrawRect(x,y,w,h)
    else
        local X = 0
	    local Y = 0

	    surface.SetDrawColor(255, 255, 255, a)
	    surface.SetMaterial(blur)

	    for i = 1, 2 do
	    	blur:SetFloat("$blur", i / 3 * 5)
	    	blur:Recompute()

	    	render.UpdateScreenEffectTexture()
	    	render.SetScissorRect(x, y, x + w, y + h, true)

	    	surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())

	    	render.SetScissorRect(0, 0, 0, 0, false)
	    end
    end
end

local hidealpha = 0

local function funnihud()
    local ply = LocalPlayer()
	local scrw = ScrW()
	local scrh = ScrH()

    local lastframetime = (math.floor(math.Round(FrameTime(), 4) * 1000))
    framerate = math.Round(math.Approach(framerate, math.ceil(1 / FrameTime()), FrameTime() * 10000))

    scale = ScrH() / 1080

    local ActivePrimaryFire = nil -- Self-explanatory.

    if ARC9Installed then function GetFiremodeName()
        if self:GetUBGL() then
            ARC9UsingAltfire = true
            return self:GetProcessedValue("UBGLFiremodeName")
        else
        end
    
        local arc9_mode = self:GetCurrentFiremodeTable()
    
        local pkad_firemode_text = "UNKNOWN"
    
        if arc9_mode.PrintName then
            pkad_firemode_text = arc9_mode.PrintName
        else
            if arc9_mode.Mode == 1 then
                pkad_firemode_text = "SEMI"
            elseif arc9_mode.Mode == 0 then
                pkad_firemode_text = "SAFETY"
            elseif arc9_mode.Mode < 0 then
                pkad_firemode_text = "AUTO"
            elseif arc9_mode.Mode > 1 then
                pkad_firemode_text = tostring(arc9_mode.Mode) .. "-BURST"
            end
        end
    
        if self:GetSafe() then
            pkad_firemode_text = "SAFETY"
        end
    
        return pkad_firemode_text
    end
    end
    
    CreateClientConVar("PKAmmoDisp_CornerColor", "65 124 174 124", true, false, "Ammo counter corner color.")
    CreateClientConVar("PKAmmoDisp_AmmobarColor", "85 144 194 200", true, false, "Ammo bar color.")
    CreateClientConVar("PKAmmoDisp_TextColor", "255 255 255 255", true, false, "Ammo counter text color.")
    --local ammobarcolor = nil

    local corner_color_c = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_CornerColor"))
    corner_color_c.a = math.Clamp(corner_color_c.a + 50, 0, 255)
    corner_color_c.a = dynamic:GetBool() and math.max(150 - hidealpha, 50) or corner_color_c.a

    local text_color = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_TextColor"))
    text_color.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or text_color.a
    local othertext = string.ToColor("255 255 255 255")
    othertext.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or othertext.a
    local ammobarcolor = string.ToColor(LocalPlayer():GetInfo("PKAmmoDisp_AmmobarColor")), math.max(255 - hidealpha, 2)
    ammobarcolor.a = dynamic:GetBool() and math.max(255 - hidealpha, 2) or ammobarcolor.a

    local armorbackground = string.ToColor("110 110 110 128")
    armorbackground.a = dynamic:GetBool() and math.max(255 - hidealpha, 50) or armorbackground.a
    local ammolowcolor = string.ToColor("0 0 0 230")
    ammolowcolor.a = dynamic:GetBool() and math.max(230 - hidealpha, 50) or ammolowcolor.a
    local ammolowcolor1 = string.ToColor("0 0 0 100")
    ammolowcolor1.a = dynamic:GetBool() and math.max(100 - hidealpha, 50) or ammolowcolor.a

    armorsegment = math.Clamp(ply:Armor(), 0, 25)
    armorsegment1 = math.Clamp(ply:Armor() - 25, 0, 25)
    armorsegment2 = math.Clamp(ply:Armor() - 50, 0, 25)
    armorsegment3 = math.Clamp(ply:Armor() - 75, 0, 25)

	if hidden:GetInt() > 1 then return end
    
	local vp = ply:GetViewPunchAngles()

	if not sway:GetBool() then
		vp.x = 0
		vp.z = 0
	end

    nicktext = ply:Nick()

    surface.SetFont("funnitexttiny")

    local nickw, nickh = surface.GetTextSize(nicktext)

    surface.SetFont("funnitextbeeg")

	--local coursew, _ = surface.GetTextSize(coursename)
	local bgpadw = nickw
    local bgpadding = bgpadw > 200 and bgpadw + 40 or 200 -- Technically not needed but I'm too lazy to remove it
	-- local bgpadh = nickh

	--[[if bgpadw < coursew then
		bgpadw = coursew
	end
    ]]
    

    local playervel = ply:GetVelocity():Length2D()
    local roundvel = math.Round(ply:GetVelocity():Length2D())
    local speedtext = math.Round(ply:GetVelocity():Length2D() * 0.06858125) .. " km/h"
    --local spedtext = roundvel .. " u/s (" .. speedtext .. ")"
    local spedw = nil

    -- Legacy speedometer (works with any gamemode btw)
    --[[if showspeed:GetBool() then
        surface.SetDrawColor(128, 128, 128, 96)
        surface.DrawRect(scrw * 0.5 + vp.z - 450 * scale, scrh * 0.965 + vp.x, 900 * scale, 1 * scale)
        local drawcolor = nil
        if playervel <= 300 then -- "Wonderful" bar-style speedometer, as shown in some early Beatrun videos.
            surface.SetDrawColor(128, 128, 128, 146)
            surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.965 + vp.x, playervel * scale, 4 * scale)
            surface.SetTextColor(128, 128, 128, 146)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.z, scrh * 0.947 + vp.x)
            surface.DrawText(spedtext)
        elseif playervel > 300 and playervel <= 700 then
            surface.SetDrawColor(220, 154, 13, 147)
            surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.964 + vp.x, playervel * scale, 6 * scale)
            surface.SetTextColor(220, 154, 13, 147)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.z, scrh * 0.947 + vp.x)
            surface.DrawText(spedtext)
        elseif playervel > 700 and playervel < 900 then
            surface.SetDrawColor(210, 155, 36, 192)
            surface.DrawRect(scrw * 0.5 + vp.z - (playervel / 2 * scale), scrh * 0.963 + vp.x, playervel * scale, 8 * scale)
            surface.SetTextColor(210, 155, 36, 192)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.z, scrh * 0.947 + vp.x)
            surface.DrawText(spedtext)
        elseif playervel >= 900 then
            surface.SetDrawColor(252, 202, 95)
            surface.DrawRect(scrw * 0.5 + vp.z - 900 / 2, scrh * 0.963 + vp.x, 900 * scale, 8 * scale)
            surface.SetTextColor(252, 202, 95)
            surface.SetFont("funnitextbeeg")
            local spedw = surface.GetTextSize(spedtext)
            surface.SetTextPos(scrw * 0.5 - (spedw / 2) + vp.z, scrh * 0.947 + vp.x)
            surface.DrawText(spedtext)
        end
    end]]

    local weapon = ply:GetActiveWeapon()
    local ammo1, ammo1mag, ammo2, ammo2mag, hasSecondaryAmmoType = -1, -1, -1, -1, false;

    if (IsValid(weapon)) then
        infmag2 = (math.Clamp(ply:GetAmmoCount(weapon:GetPrimaryAmmoType()), 0, 9999))
        infmag3 = (math.Clamp(ply:GetAmmoCount(weapon:GetSecondaryAmmoType()), 0, 9999))
        mag1 = math.Clamp(weapon:Clip1(), -1, 9999)
        ammo1mag = ("/" .. math.Clamp(infmag2, 0, 9999))
        mag2 = math.Clamp(weapon:Clip2(), -1, 9999)
        ammo2mag = ("/" .. math.Clamp(infmag3, 0, 9999))
        hasSecondaryAmmoType = false
        ammo1type = weapon:GetPrimaryAmmoType()
        ammo2type = weapon:GetSecondaryAmmoType()
        max1mag = weapon:GetMaxClip1()
        maxmag2 = weapon:GetMaxClip2()
    end

    local a9 = false
    local inarc9cust = false
    local isweparccw = false

    if ARC9Installed then
        a9 = weapon.ARC9
        inarc9cust = a9 and weapon:GetCustomize()
    end

    if ArcCWInstalled then
        isweparccw = weapon.ArcCW
    end

    local melee = false
    local infmag = false
    local HasAltFire = false
    local UsesAltMag = 0

    if ammo1type == -1 and max1mag <= 0 then -- Taken and modified from ARC9 base, see: https://github.com/HaodongMo/ARC-9/blob/main/lua/arc9/client/cl_hud.lua#L692C1-L695C8
        melee = true
    elseif ammo1type ~= -1 and max1mag <= 0 then
        infmag = true
    end    

    if ammo2type == -1 then
        HasAltFire = false
    elseif ammo2type ~= -1 and maxmag2 <= 0 then
        HasAltFire = true
    elseif ammo2type ~= -1 and maxmag2 > 0 then
        HasAltFire = true
        UsesAltMag = 1
    end

    if mag1 > max1mag then
        ammo1mag = ("+" .. mag1 - max1mag .. "/" .. math.Clamp(infmag2, 0, 9999))
        ammo1 = mag1 - (mag1 - max1mag) -- Goddamnyou ARC9 for making ammo1 act weird
    else
        ammo1 = mag1
    end
    if HasAltFire and UsesAltMag == 1 and ply:IsValid() and ply:Alive() then
        if weapon:Clip2() > weapon:GetMaxClip2() then -- No 1-in-chamber conditions exist for altfire AFAIK but just for consistency
            ammo2mag = ("+" .. mag2 - max2mag .. "/" .. math.Clamp(infmag3, 0, 9999))
            ammo2 = mag2 - (mag2 - max2mag)
        else
            ammo2 = mag2
        end
    end


    ARC9InfClip = false
    ARC9InfAmmo = false
    
    if ARC9Installed and a9 and (weapon:GetInfiniteAmmo() or GetConVar("arc9_infinite_ammo"):GetBool()) then
        inf_reserve = true
        ammo1mag = "/inf"
        ammo2mag = "/inf"
        infmag3 = "∞"
    end
    if ARC9Installed and a9 and weapon:GetProcessedValue("BottomlessClip", true) then
        ARC9InfClip = true

        --ammo2disp = ∞
        --ammo1disp = ∞
        infmag = true

        if inf_reserve == true then
            infmag2 = "∞"
            infmag3 = "∞"
        else
            infmag2 = infmag2 + ammo1
            infmag3 = infmag3 + ammo2
        end
        UsesAltMag = 0
    end
    
    local pkad_firemode_text = "FULL AUTO"

    local automatics = {
        ["weapon_smg1"] = true,
        ["weapon_ar2"] = true,
        ["weapon_mp5_hl1"] = true,
        ["weapon_gauss"] = true,
        ["weapon_egon"] = true
    }    
    
    if (not hidden:GetBool() and ply:IsValid() and ply:Alive() and not melee) then
        --surface.SetDrawColor(corner_color_c)
        --surface.DrawRect(scrw * 0.886 + scale * bgpadding + vp.z, scrh * 0.865 + vp.x, 40 * scale, scale * 25)
        --DrawBlurRect2(scrw * 0.886 + vp.z, scrh * 0.865 + vp.x, scale * bgpadding, scale * 25, math.max(255 - --hidealpha, 2))

        --surface.SetDrawColor(corner_color_c)
        --surface.DrawOutlinedRect(scrw * 0.886 + vp.z, scrh * 0.865 + vp.x, scale * bgpadding, scale * 25)

        if SpecialWeaponFiremode[ply:GetActiveWeapon()] then
            pkad_firemode_text = SpecialCorrespondingFiremode[ply:GetActiveWeapon()]
        elseif ARC9Installed and a9 then -- This acquires firemode. Yes, it takes this much code to simply acquire your bloody firemode.
            local arc9_mode = weapon:GetCurrentFiremodeTable()
        
            pkad_firemode_text = weapon:GetFiremodeName()
        
            -- Funny note: Some ARC9 functions are global so we can just use them directly if ARC9 is installed! Hooray!
            if #weapon:GetValue("Firemodes") > 1 then
                wepmultifire = true
            end
        
            if weapon:GetProcessedValue("NoFiremodeWhenEmpty", true) and weapon:Clip1() <= 0 then
                wepmultifire = false
            end
        
            if weapon:GetUBGL() then
                arc9_mode = {
                    Mode = weapon:GetCurrentFiremode(),
                    PrintName = weapon:GetProcessedValue("UBGLFiremodeName")
                }
                pkad_firemode_text = arc9_mode.PrintName
                wepmultifire = false
            end
        
            if weapon:GetSafe() then
                arc9safety = true
            end
        
            if weapon:GetInfiniteAmmo() then
                arc9inf_reserve = true
            end
        
            if weapon:GetJammed() then
                arc9jammed = true
            end
        
            if weapon:GetProcessedValue("Overheat", true) then
                arc9showheat = true
                heat = weapon:GetHeatAmount()
                heatcap = weapon:GetProcessedValue("HeatCapacity")
                heatlocked = weapon:GetHeatLockout()
            end
        elseif weapon.ArcCW then
            local arccw_mode = weapon:GetCurrentFiremode()
    
            pkad_firemode_text = weapon:GetFiremodeName()
    
            pkad_firemode_text = string.upper(pkad_firemode_text)  
        elseif weapon:IsScripted() then
            if !weapon.Primary.Automatic then
                pkad_firemode_text = "SEMI AUTO"
            end
    
            if weapon.ThreeRoundBurst then
                pkad_firemode_text = "3-BURST"
            end
    
            if weapon.TwoRoundBurst then
                pkad_firemode_text = "2-BURST"
            end
    
            if weapon.GetSafe then
                if weapon:GetSafe() then
                    pkad_firemode_text = "SAFETY"
                end
            end
    
            if isfunction(weapon.Safe) then
                if weapon:Safe() then
                    pkad_firemode_text = "SAFETY"
                end
            end
    
            if isfunction(weapon.Safety) then
                if weapon:Safety() then
                    pkad_firemode_text = "SAFETY"
                end
            end
        else
            if !automatics[weapon:GetClass()] then
                pkad_firemode_text = "SEMI AUTO"
            end
        end
        -- END OF FIREMODE BS
        --print(pkad_firemode_text)

        -- Are we using altfire?
        if ArcCWInstalled and isweparccw and string.match(pkad_firemode_text, "UB") and not pkad_firemode_text == "DOUBLE-ACTION" then -- Extra precautions
            pkad_firemode_text = "SWITCH"
            ActivePrimaryFire = false
        end
        if ARC9Installed and a9 and weapon:GetUBGL() then
            ActivePrimaryFire = false
        elseif not isweparccw then
            ActivePrimaryFire = true
        end

        --if ActivePrimaryFire then
        --    print("1")
        --else
        --    print("0")
        --end

		if dynamic:GetBool() then
			hidealpha = math.Approach(hidealpha, 150 * ply:GetVelocity():Length() / 250, 100 * RealFrameTime())
		else
			hidealpha = 0
		end

        local magrate = math.Clamp(ammo1 / weapon:GetMaxClip1(), 0, 1)
        local magflowrate = math.Clamp((mag1 - max1mag) / weapon:GetMaxClip1(), 0, 1)
        local magrate2 = math.Clamp(ammo2 / weapon:GetMaxClip2(), 0, 1)
        local lowamount = weapon:GetMaxClip1() / 3

        surface.SetDrawColor(corner_color_c)
        surface.DrawRect(scrw * 0.886 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 40 * scale, scale * 85)
        DrawBlurRect2(scrw * 0.886 + vp.z, scrh * 0.895 + vp.x, scale * bgpadding, scale * 85, math.max(255 - hidealpha, 2))

        surface.SetDrawColor(corner_color_c)
        surface.DrawOutlinedRect(scrw * 0.886 + vp.z, scrh * 0.895 + vp.x, scale * bgpadding, scale * 85)

        local speedtext = math.Round(ply:GetVelocity():Length2D() * 0.06858125) .. " km/h"
        local speedlengthw, speedlengthh = surface.GetTextSize(speedtext)
        --print(speedlengthw .. "   " .. speedlengthh)
        local rscrbor = scrw * 0.986

        surface.SetTextColor(text_color)
        surface.SetTextPos(rscrbor - speedlengthw + vp.z, scrh * 0.95 + vp.x)
        --surface.DrawText(speedtext)

        if not infmag then
            surface.SetFont("funnitextbeeg")
            local resrvw, resrvh = surface.GetTextSize(ammo1mag)
            surface.SetTextPos(rscrbor - resrvw + vp.z, scrh * 0.91 + vp.x)
            if (ARC9Installed and a9 and inf_reserve) or infmag2 > 0 then
                if ActivePrimaryFire == false then
                    surface.SetTextColor(153,153,153,text_color.a)
                else
                    surface.SetTextColor(text_color)
                end
                surface.DrawText(ammo1mag)
            elseif infmag2 == 0 then
                if ActivePrimaryFire == true then
                    surface.SetTextColor(200,0,0,text_color.a)
                else
                    surface.SetTextColor(153,0,0,text_color.a)
                end
                surface.DrawText(ammo1mag)
                surface.SetTextColor(text_color)
            end

            surface.SetFont("funnitexthuge")
            local magw, magh = surface.GetTextSize(ammo1)
            surface.SetTextPos(rscrbor - resrvw - magw + vp.z, scrh * 0.9 + vp.x)
            if ammo1 < weapon:GetMaxClip1() / 3 then
                if ActivePrimaryFire == true then
                    surface.SetTextColor(255,0,0,text_color.a)
                else
                    surface.SetTextColor(153,0,0,text_color.a)
                end
                surface.DrawText(ammo1)
                surface.SetTextColor(text_color)
                --ammobarcolor = "220 0 0 255"
            else
                if ActivePrimaryFire == true then
                    surface.SetTextColor(text_color)
                else
                    surface.SetTextColor(153,153,153,text_color.a)
                end
                surface.DrawText(ammo1)
                surface.SetTextColor(text_color)
            end

            if ammo1 ~= -1 and ammo1 < (weapon:GetMaxClip1() / 3) then
                surface.SetDrawColor(100, 50, 50, ammolowcolor1.a)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 5)
                surface.SetDrawColor(255, 0, 0, ammolowcolor.a)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            elseif ammo1 ~= -1 then
                surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + vp.x, 150 * scale, scale * 5)
                surface.SetDrawColor(ammobarcolor)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.938 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
                if mag1 > max1mag then
                    surface.SetDrawColor(255,255,255,ammobarcolor.a)
                    surface.DrawRect(scrw * 0.907 + vp.z, scrh * 0.938 + 1 + vp.x, 150 * scale * magflowrate, scale * 7)
                end
            end

            if HasAltFire and UsesAltMag == 0 then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)

                surface.SetFont("funnitexthuge")
                local mag2w, mag2h = surface.GetTextSize(infmag3)
                surface.SetTextPos(scrw * 0.86 - mag2w + vp.z, scrh * 0.9 + vp.x)
                if infmag3 == 0 then
                    if ActivePrimaryFire == true then
                        surface.SetTextColor(153,0,0,text_color.a)
                    else
                        surface.SetTextColor(255,0,0,text_color.a)
                    end
                    surface.DrawText(infmag3)
                    --surface.SetTextColor(text_color)
                    --ammobarcolor = "220 0 0 255"
                elseif (ARC9Installed and a9 and inf_reserve) or infmag3 > 0 then
                    if ActivePrimaryFire == true then
                        surface.SetTextColor(153,153,153,text_color.a)
                    else
                        surface.SetTextColor(text_color)
                    end
                    surface.DrawText(infmag3)
                end

                if infmag3 == 0 then
                    surface.SetDrawColor(255, 0, 0, ammolowcolor.a)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                elseif (ARC9Installed and a9 and inf_reserve) or infmag3 > 0 then
                    surface.SetDrawColor(ammobarcolor)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                end
            elseif HasAltFire and UsesAltMag == 1 then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)

                surface.SetFont("funnitextbeeg")
                local resrv2w, resrv2h = surface.GetTextSize(ammo2mag)
                surface.SetTextPos(scrw * 0.86 - resrv2w + vp.z, scrh * 0.91 + vp.x)
                if infmag3 == 0 then
                    if ActivePrimaryFire == true then
                        surface.SetTextColor(153,0,0,text_color.a)
                    else
                        surface.SetTextColor(255,0,0,text_color.a)
                    end
                    surface.DrawText(ammo2mag)
                else
                    if ActivePrimaryFire == true then
                        surface.SetTextColor(153,153,153,text_color.a)
                    else
                        surface.SetTextColor(text_color)
                    end
                    surface.DrawText(ammo2mag)
                end
    
                surface.SetFont("funnitexthuge")
                local mag2w, mag2h = surface.GetTextSize(ammo2)
                surface.SetTextPos(scrw * 0.86 - resrv2w - mag2w + vp.z, scrh * 0.9 + vp.x)
                if ammo2 < weapon:GetMaxClip2() / 3 then
                    if ActivePrimaryFire == true then
                        surface.SetTextColor(153,0,0,text_color.a)
                    else
                        surface.SetTextColor(255,0,0,text_color.a)
                    end
                    surface.DrawText(ammo2)
                    --ammobarcolor = "220 0 0 255"
                elseif (ARC9Installed and a9 and inf_reserve) or infmag2 > 0 then
                    if ActivePrimaryFire == true then
                        surface.SetTextColor(153,153,153,text_color.a)
                    else
                        surface.SetTextColor(text_color)
                    end
                    surface.DrawText(ammo2)
                end

                if ammo2 ~= -1 and ammo2 < (weapon:GetMaxClip2() / 3) then
                    surface.SetDrawColor(100, 50, 50, ammolowcolor1.a)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(255, 0, 0, ammolowcolor.a)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                elseif ammo2 ~= -1 or (ARC9Installed and a9 and inf_reserve) or infmag2 > 0 then
                    surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)                    
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(ammobarcolor)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                end
            end
            --print(bgpadding)
        elseif infmag then
            --[[surface.SetFont("funnitextbeeg")
            local resrvw, resrvh = surface.GetTextSize(ammo1mag)
            surface.SetTextPos(rscrbor - resrvw + vp.z, scrh * 0.91 + vp.x)
            if ammo1mag == 0 then
                surface.SetTextColor(255,0,0,255)
                surface.DrawText(ammo1mag)
                surface.SetTextColor(text_color)
            else
                surface.DrawText(ammo1mag)
            end
            ]]

            surface.SetFont("funnitexthuge")
            local magw, magh = surface.GetTextSize(infmag2)
            surface.SetTextPos(rscrbor - magw + vp.z, scrh * 0.9 + vp.x)
            if infmag2 == 0 then
                if ActivePrimaryFire == true then
                    surface.SetTextColor(153,0,0,text_color.a)
                else
                    surface.SetTextColor(255,0,0,text_color.a)
                    --ammobarcolor = "220 0 0 255"
                end
                surface.DrawText(infmag2)
                surface.SetTextColor(text_color)
            else
                surface.DrawText(infmag2)
            end

            if infmag2 == 0 then
                surface.SetDrawColor(255, 0, 0, ammolowcolor.a)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            else
                surface.SetDrawColor(ammobarcolor)
                surface.DrawRect(scrw * 0.908 + vp.z, scrh * 0.94 + 1 + vp.x, 150 * scale * magrate, scale * 5)
                surface.SetDrawColor(corner_color_c)
            end

            if HasAltFire and UsesAltMag == 0 then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)

                surface.SetFont("funnitexthuge")
                local mag2w, mag2h = surface.GetTextSize(infmag3)
                surface.SetTextPos(scrw * 0.86 - mag2w + vp.z, scrh * 0.9 + vp.x)
                if infmag3 == 0 then
                    surface.SetTextColor(255,0,0,text_color.a)
                    surface.DrawText(infmag3)
                    surface.SetTextColor(text_color)
                    --ammobarcolor = "220 0 0 255"
                elseif (ARC9Installed and a9 and inf_reserve) or infmag3 > 0 then
                    surface.SetTextColor(text_color)
                    surface.DrawText(infmag3)
                end

                if infmag2 == 0 then
                    surface.SetDrawColor(255, 0, 0, ammolowcolor.a)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                elseif (ARC9Installed and a9 and inf_reserve) or infmag3 > 0 then
                    surface.SetDrawColor(ammobarcolor)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                end
            elseif HasAltFire and UsesAltMag == 1 then
                surface.SetDrawColor(corner_color_c)
                surface.DrawRect(scrw * 0.76025 + scale * bgpadding + vp.z, scrh * 0.895 + vp.x, 25 * scale, scale * 85)
                DrawBlurRect2(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85, math.max(255 - hidealpha, 2))
                surface.SetDrawColor(corner_color_c)
                surface.DrawOutlinedRect(scrw * 0.78168 + vp.z, scrh * 0.895 + vp.x, scale * 161, scale * 85)

                surface.SetFont("funnitextbeeg")
                local resrv2w, resrv2h = surface.GetTextSize(ammo2mag)
                surface.SetTextPos(scrw * 0.86 - resrv2w + vp.z, scrh * 0.91 + vp.x)
                if infmag3 == 0 then
                    surface.SetTextColor(255,0,0,text_color.a)
                    surface.DrawText(ammo2mag)
                    surface.SetTextColor(text_color)
                else
                    surface.DrawText(ammo2mag)
                end
    
                surface.SetFont("funnitexthuge")
                local mag2w, mag2h = surface.GetTextSize(ammo2)
                surface.SetTextPos(scrw * 0.86 - resrv2w - mag2w + vp.z, scrh * 0.9 + vp.x)
                if ammo2 < weapon:GetMaxClip2() / 3 then
                    surface.SetTextColor(255,0,0,text_color.a)
                    surface.DrawText(ammo2)
                    surface.SetTextColor(text_color)
                    --ammobarcolor = "220 0 0 255"
                elseif (ARC9Installed and a9 and inf_reserve) or infmag2 > 0 then
                    surface.SetTextColor(text_color)
                    surface.DrawText(ammo2)
                end

                if ammo2 ~= -1 and ammo2 < (weapon:GetMaxClip2() / 3) then
                    surface.SetDrawColor(100, 50, 50, ammolowcolor1.a)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor(255, 0, 0, ammolowcolor.a)
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                elseif ammo2 ~= -1 or (ARC9Installed and a9 and inf_reserve) or infmag2 > 0 then
                    surface.SetDrawColor(10, 50, 50, ammolowcolor1.a)                    
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale, scale * 5)
                    surface.SetDrawColor()
                    surface.DrawRect(scrw * 0.81 + vp.z, scrh * 0.94 + 1 + vp.x, 100 * scale * magrate2, scale * 5)
                    surface.SetDrawColor(corner_color_c)
                end
            end
        end

        --if melee then
        --    surface.SetDrawColor(255,255,255,255)
        --    surface.DrawRect(256, 256, 256, 256)
        --end

        if ArcCWInstalled and isweparccw and ProcessFiremode:GetBool() and pkad_firemode_text ~= "SWITCH" and pkad_firemode_text ~= "UNDERBARREL" then
            for i=1,#ArcPossibleFiremodes do
                if (string.match(pkad_firemode_text, ArcPossibleFiremodes[i])) then
                    pkad_firemode_text = ArcFiremodeDisplay[i]
                end
            end
        elseif not isweparccw and ProcessFiremode:GetBool() then
            local ARC9Firemodes = {
                "AUTO",
                "SINGLE",
                "SAFE",
                "3-BURST",
                "2-BURST"
            }
            local ARC9ModeDisplay = {
                "FULL AUTO",
                "SEMI AUTO",
                "SAFETY",
                "3-BURST",
                "2-BURST"
            }
            if ARC9Installed and a9 then
                for i=1,#ArcPossibleFiremodes do
                    if (string.match(pkad_firemode_text, ArcPossibleFiremodes[i])) and not ARC9UsingAltfire then
                        pkad_processed_firemode_text = i
                    end
                end
                for i=1,#ArcFiremodeDisplay do
                    if (string.match(pkad_processed_firemode_text, i)) and not ARC9UsingAltfire then
                        --print(pkad_firemode_text .. ArcFiremodeDisplay[i])
                        pkad_processed_firemode_text = ArcFiremodeDisplay[i]
                    end
                end
            end
            if ARC9Installed and a9 and weapon:GetUBGL() then -- This is the ONLY way for ARC9 altfire detection to work. For some godforsaken reason.
                pkad_processed_firemode_text = "SWITCH"
            end   
        end
        string.Replace(pkad_firemode_text, "BST", "BURST")
        --[[for i=1,#ArcFiremodeDisplay do
            if (string.match(pkad_firemode_text, )) then
                pkad_firemode_text = ArcFiremodeDisplay[i]
            end
        end]]
        pkad_processed_firemode_text = pkad_firemode_text
         
        if ActivePrimaryFire == false or pkad_processed_firemode_text == "SWITCH" then
            surface.SetTextColor(255,255,255,othertext.a)
            surface.SetFont("funnitexttiny")
        else
            surface.SetTextColor(153,153,153,othertext.a)
            surface.SetFont("funnitexttiny")
        end
        if isweparccw and pkad_processed_firemode_text == "UNDERBARREL" then
            local firemodethicc, firemodetall = surface.GetTextSize("SWITCH")
            surface.SetTextPos(rscrbor - firemodethicc + vp.z, scrh * 0.95 + vp.x)
            surface.SetTextColor(text_color)
            surface.DrawText("SWITCH")
        else
            local firemodethicc, firemodetall = surface.GetTextSize(pkad_processed_firemode_text)
            surface.SetTextPos(rscrbor - firemodethicc + vp.z, scrh * 0.95 + vp.x)
            surface.DrawText(pkad_processed_firemode_text)
        end

        local usekey = string.upper(string.Replace(input.LookupBinding("+use", 1), "MOUSE", "M"))
        local attack2 = string.upper(string.Replace(input.LookupBinding("+attack2", 1), "MOUSE", "M"))
        local reloadkey = string.upper(string.Replace(input.LookupBinding("+reload", 1), "MOUSE", "M"))
        local zoomkey = nil
        
        if IsInputBound("+zoom") then 
            zoomkey = string.upper(string.Replace(input.LookupBinding("+zoom", 1), "MOUSE", "M")) 
        else 
            zoomkey = "NONE" 
        end

        local ubglkey = "HELP" -- FALLBACK!!!
        local firemodekey = "NONE"
        if ARC9Installed and a9 and not IsInputBound("+arc9_ubgl") then
            ubglkey = "[" .. usekey .."]+" .. "[" .. attack2 .. "]"
        elseif ARC9Installed and a9 and IsInputBound("+arc9_ubgl") then
            ubglkey = "[" .. string.upper(input.LookupBinding("+arc9_ubgl", 1)) .. "]"
        elseif ArcCWInstalled and isweparccw and IsInputBound("arccw_toggle_ubgl") then
            ubglkey = "[" .. string.upper(input.LookupBinding("arccw_toggle_ubgl", 1)) .. "]"
        elseif ArcCWInstalled and isweparccw then
            ubglkey = "[" .. usekey .."]+" .. "[" .. reloadkey .. "]"
        end

        if ARC9Installed and a9 then
            firemodekey = "[" .. zoomkey .. "]"
        elseif ArcCWInstalled and isweparccw and IsInputBound("arccw_firemode") then
            firemodekey = "[" .. string.upper(input.LookupBinding("arccw_firemode", 1)) .. "]"
        elseif ArcCWInstalled and isweparccw then
            firemodekey = "[" .. zoomkey .. "]"
        end

        print(ubglkey)

        if HasAltFire and isweparccw and pkad_firemode_text == "UNDERBARREL" then
            surface.SetTextColor(255,255,255,othertext.a)
            surface.SetTextPos(scrw * 0.887 + vp.z, scrh * 0.95 + vp.x)
            surface.DrawText(ubglkey)
        elseif HasAltFire and not isweparccw and ActivePrimaryFire == false and not automatics[weapon:GetClass()] then
            surface.SetTextColor(255,255,255,othertext.a)
            surface.SetTextPos(scrw * 0.887 + vp.z, scrh * 0.95 + vp.x)
            surface.DrawText(ubglkey)
        elseif HasAltFire and not isweparccw and ActivePrimaryFire == true and not automatics[weapon:GetClass()] then
            surface.SetTextColor(255,255,255,othertext.a)
            surface.SetTextPos(scrw * 0.784 + vp.z, scrh * 0.95 + vp.x)
            surface.DrawText(ubglkey)
            surface.SetTextPos(scrw * 0.888 + vp.z, scrh * 0.95 + vp.x)
            surface.SetTextColor(172,172,172,othertext.a)
            surface.DrawText(firemodekey)
        else
            surface.SetTextPos(scrw * 0.888 + vp.z, scrh * 0.95 + vp.x)
            surface.SetTextColor(172,172,172,othertext.a)
            surface.DrawText(firemodekey)
        end
        
        if HasAltFire then
            local altmodew, altmodeh = nil
            local altfiremode = nil
            if automatics[weapon:GetClass()] then
                surface.SetTextColor(text_color)
                altfiremode = "FIRE"
                altmodew, altmodeh = surface.GetTextSize(altfiremode)
            elseif ActivePrimaryFire == true and not automatics[weapon:GetClass()] then
                surface.SetTextColor(text_color)
                altfiremode = "SWITCH"
                altmodew, altmodeh = surface.GetTextSize(altfiremode)
            elseif isweparccw and pkad_firemode_text ~= "UNDERBARREL" and not automatics[weapon:GetClass()] then
                surface.SetTextColor(text_color)
                altfiremode = "SWITCH"
                altmodew, altmodeh = surface.GetTextSize(altfiremode)
            else
                surface.SetTextColor(153,153,153,othertext.a)
                altfiremode = "UNDERBARREL"
                altmodew, altmodeh = surface.GetTextSize(altfiremode)
            end
            surface.SetTextPos(scrw * 0.86 - altmodew + vp.z, scrh * 0.95 + vp.x)
            surface.DrawText(altfiremode)
        end
    elseif ply:IsValid() and ply:Alive() and melee then
        -- Spaghetti for EasyChat to STOP SPITTING ERRORS MY WAY
        if ply:Alive() or ply:IsValid() then
            surface.SetTextColor(255,255,255,othertext.a)
            surface.SetFont("funnitexttiny")
        else
            surface.SetTextColor(153,153,153,othertext.a)
            surface.SetFont("funnitexttiny")
        end
    end

    if (showspeed:GetBool() and ply:IsValid() and ply:Alive() and not melee) then
        if showspeed:GetBool() then -- bruh GMod still renders this for some reason
            surface.SetDrawColor(corner_color_c)
            surface.DrawRect(scrw * 0.886 + scale * bgpadding + vp.z, scrh * 0.865 + vp.x, 40 * scale, scale * 25)
            DrawBlurRect2(scrw * 0.886 + vp.z, scrh * 0.865 + vp.x, scale * bgpadding, scale * 25, math.max(255 - hidealpha, 2))
        end
    
        surface.SetDrawColor(corner_color_c)
        surface.DrawOutlinedRect(scrw * 0.886 + vp.z, scrh * 0.865 + vp.x, scale * bgpadding, scale * 25)
    
        if roundvel > 738.6 then
            surface.SetDrawColor(252, 202, 95)
        else
            surface.SetDrawColor(corner_color_c)
        end
        surface.DrawRect(scrw * 0.89 + vp.z, scrh * 0.873 + vp.x, scale * math.Clamp(roundvel / 7.034632, 0, 105), scale * 6)   
        speedtxt = math.Round(roundvel * 0.06858125) .. "km/h" 
        --surface.SetFont(funnitexttiny)
        local speedw, speedh = surface.GetTextSize(speedtxt)
        if roundvel > 738.6 then
            surface.SetTextColor(252, 202, 95, othertext.a)
        else
            surface.SetTextColor(text_color)
        end
        surface.SetTextPos(scrw * 0.986 - speedw + vp.z, scrh * 0.87 + vp.x)
        surface.DrawText(math.Round(roundvel * 0.06858125) .. "km/h") 
    elseif (showspeed:GetBool() and ply:IsValid() and ply:Alive()) then
        surface.SetDrawColor(corner_color_c)
        surface.DrawRect(scrw * 0.886 + scale * bgpadding + vp.z, scrh * 0.95 + vp.x, 40 * scale, scale * 25)
        DrawBlurRect2(scrw * 0.886 + vp.z, scrh * 0.95 + vp.x, scale * bgpadding, scale * 25, math.max(255 - hidealpha, 2))
    
        surface.SetDrawColor(corner_color_c)
        surface.DrawOutlinedRect(scrw * 0.886 + vp.z, scrh * 0.95 + vp.x, scale * bgpadding, scale * 25)
    
        if roundvel > 738.6 then
            surface.SetDrawColor(252, 202, 95, othertext.a)
        else
            surface.SetDrawColor(corner_color_c)
        end
        surface.DrawRect(scrw * 0.89 + vp.z, scrh * 0.961 + vp.x, scale * math.Clamp(roundvel / 7.034632, 0, 105), scale * 6)   
        speedtxt = math.Round(roundvel * 0.06858125) .. "km/h"
        local speedw, speedh = surface.GetTextSize(speedtxt)
        if roundvel > 738.6 then
            surface.SetTextColor(252, 202, 95, othertext.a)
        else
            surface.SetTextColor(text_color)
        end
        surface.SetTextPos(scrw * 0.986 - speedw + vp.z, scrh * 0.955 + vp.x)
        surface.DrawText(math.Round(roundvel * 0.06858125) .. "km/h")
    end

    if ply:Armor() > 0 then
        local BlurHeight = 0.862
        local VerticalBars = 0.8675
        local TextHeight = 0.864
        if IsPlayingBeatrun and GetConVar("Beatrun_HUDHidden"):GetInt() == 1 then
            BlurHeight = 0.925
            VerticalBars = 0.9295
            TextHeight = 0.927
        elseif IsPlayingBeatrun and GetConVar("Beatrun_HUDHidden"):GetInt() == 2 then
            BlurHeight = 0.95
            VerticalBars = 0.9545
            TextHeight = 0.952
        end
        surface.SetDrawColor(corner_color_c)
	    surface.DrawRect(-20 * scale + vp.z, scrh * BlurHeight + vp.x, scale * 40, scale * 26)
	    DrawBlurRect2(scale * 20 + vp.z, scrh * BlurHeight + vp.x, scale * 200, scale * 26, math.max(255 - hidealpha, 2))
        surface.SetDrawColor(corner_color_c)
        surface.DrawOutlinedRect(scale * 20 + vp.z, scrh * BlurHeight + vp.x, scale * 200, scale * 26)
        
        surface.SetDrawColor(110,110,110,armorbackground.a)
        surface.DrawRect(24 * scale + vp.z, scrh * VerticalBars + vp.x, scale * 35, scale *14)
        surface.DrawRect(62 * scale + vp.z, scrh * VerticalBars + vp.x, scale * 35, scale* 14)
        surface.DrawRect(100 * scale + vp.z, scrh * VerticalBars + vp.x, scale * 35, scale* 14)
        surface.DrawRect(138 * scale + vp.z, scrh * VerticalBars + vp.x, scale * 35, scale * 14)

        if ply:Armor() > 15 then
            surface.SetDrawColor(corner_color_c)
        else
            surface.SetDrawColor(230,0,0,corner_color_c.a)
        end
        surface.DrawRect(24 * scale + vp.z, scrh * VerticalBars + vp.x, scale * (1.40 * armorsegment), scale * 14)
        surface.DrawRect(62 * scale + vp.z, scrh * VerticalBars + vp.x, scale * (1.40 * armorsegment1), scale * 14)
        surface.DrawRect(100 * scale + vp.z, scrh * VerticalBars + vp.x, scale * (1.40 * armorsegment2), scale * 14)
        surface.DrawRect(138 * scale + vp.z, scrh * VerticalBars + vp.x, scale * (1.40 * armorsegment3), scale * 14)
        
        armor_color = nil
        if ply:Armor() > 15 then
            armor_color = text_color
        else
            armor_color = string.ToColor("230 0 0 " .. corner_color_c.a)
        end
        if ply:Armor() < 10 then
            surface.SetTextPos(182 * scale + vp.z, scrh * TextHeight + vp.x)
            surface.SetTextColor(120,120,120,armorbackground.a)
            surface.DrawText("00")
            surface.SetTextColor(armor_color)
            surface.DrawText(ply:Armor())
        elseif ply:Armor() < 100 then
            surface.SetTextPos(182 * scale + vp.z, scrh * TextHeight + vp.x)
            surface.SetTextColor(120,120,120,armorbackground.a)
            surface.DrawText("0")
            surface.SetTextColor(armor_color)
            surface.DrawText(ply:Armor())
        else
            surface.SetTextPos(182 * scale + vp.z, scrh * TextHeight + vp.x)
            surface.SetTextColor(armor_color)
            surface.DrawText(ply:Armor())
        end
    end

    if PerfDisplay:GetBool() then
        local text1 = nil
        if GetConVar("fps_max"):GetInt() ~= 0 then
            text1 = framerate .. "fps/" .. GetConVar("fps_max"):GetInt() .. "fps max (~" .. lastframetime .. "ms, " .. scrw .. "x" .. scrh .. ")" 
        else
            text1 = framerate .. "fps (~" .. lastframetime .. "ms, " .. scrw .. "x" .. scrh .. ")" 
        end
        local text2 = nil
        surface.SetFont("DebugTextScale")
        local txw, txh = surface.GetTextSize(text1)
        surface.SetTextPos(scrw - 8 * scale - txw, 0 + 10 * scale)
        surface.SetTextColor(128,128,128,200)
        surface.DrawText(text1)
        if game.SinglePlayer then
            text2 = ply:Ping() .. "ms to server on Singleplayer"
        else
            text2 = ply:Ping() .. "ms to server on " .. game.GetIPAddress
        end
        local tx2w, tx2h = surface.GetTextSize(text2)
        surface.SetTextPos(scrw - 8 * scale - tx2w, 0 + 10 * scale + txh * 1.25)
        surface.DrawText(text2)
    end
end

hook.Add("HUDPaint", "funnicounter", funnihud)

local DispSegments = { -- Element alighment helpers, used while debugging
    "0",
    "0.1",
    "0.2",
    "0.3",
    "0.4",
    "0.5",
    "0.6",
    "0.7",
    "0.8",
    "0.9",
    "0.05",
    "0.15",
    "0.25",
    "0.35",
    "0.45",
    "0.55",
    "0.65",
    "0.75",
    "0.85",
    "0.95",
}

local debug = CreateClientConVar("PKAmmoDisp_Debug", "0", true, false, "Enable some debugging functions\nWARNING: Will cause a lot of Lua errors on death.", 0, 1)

hook.Add( "HUDPaint", "drawsegment", function( name )
    local scale = ScrH() / 1080

    if debug:GetBool() then
        local weapon = LocalPlayer():GetActiveWeapon()
        local ammo1, ammo1mag, ammo2, ammo2mag, hasSecondaryAmmoType = -1, -1, -1, -1, false;
        for i=1,#DispSegments do
            surface.SetDrawColor(255,255,255,128)
            surface.DrawRect(ScrW() * DispSegments[i], 1, 1, ScrH()) 
            surface.DrawRect(1, ScrH() * DispSegments[i], ScrW(), 1) 
            surface.SetDrawColor(255,255,255,64)
            surface.DrawRect(ScrW() * (DispSegments[i] + 0.025), 1, 1, ScrH()) 
            surface.DrawRect(1, ScrH() * (DispSegments[i] + 0.025), ScrW(), 1) 
        end
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.6) -- Debugging stuff, enable if you're interested.
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: MaxClip1: " .. weapon:GetMaxClip1())
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.62)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: PrimaryAmmoType: " .. weapon:GetPrimaryAmmoType())
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.64)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: MaxClip2: " .. weapon:GetMaxClip2())
        surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.66)
        surface.SetFont("funnitexttiny")
        surface.DrawText("DEBUG: SecondaryAmmoType: " .. weapon:GetSecondaryAmmoType())
    end
end )