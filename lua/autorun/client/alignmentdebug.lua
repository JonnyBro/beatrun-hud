local DispSegments = {
	-- Element alighment helpers, used while debugging
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

local debugtoggle = CreateClientConVar("GLua_AlignmentHelpers", "0", true, false, "Alignment helpers or whatever. Causes lots of Lua errors while dead, so...don't be dead.", 0, 1)
hook.Add("HUDPaint", "drawsegment", function(name)
	local scale = ScrH() / 1080
	if debugtoggle:GetBool() then
		local weapon = LocalPlayer():GetActiveWeapon()
		-- local ammo1, ammo1mag, ammo2, ammo2mag, hasSecondaryAmmoType = -1, -1, -1, -1, false

		for i = 1, #DispSegments do
			surface.SetDrawColor(255, 255, 255, 128)
			surface.DrawRect(ScrW() * DispSegments[i], 1, 1, ScrH())
			surface.DrawRect(1, ScrH() * DispSegments[i], ScrW(), 1)
			surface.SetDrawColor(255, 255, 255, 64)
			surface.DrawRect(ScrW() * (DispSegments[i] + 0.025), 1, 1, ScrH())
			surface.DrawRect(1, ScrH() * (DispSegments[i] + 0.025), ScrW(), 1)
		end

		surface.SetTextPos(ScrW() * 0.5 + scale, ScrH() * 0.6)
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
end)
