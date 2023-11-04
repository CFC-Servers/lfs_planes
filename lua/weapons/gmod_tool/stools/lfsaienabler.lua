
TOOL.Category = "LFS"
TOOL.Name	 = "#AI Enabler"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar["aiteam"] = 0

if CLIENT then
	language.Add( "tool.lfsaienabler.name", "AI Enabler" )
	language.Add( "tool.lfsaienabler.desc", "A tool used to enable/disable AI on LFS-Vehicles" )
	language.Add( "tool.lfsaienabler.0", "Left click on a LFS-Vehicle to enable AI, Right click to disable." )
	language.Add( "tool.lfsaienabler.1", "Left click on a LFS-Vehicle to enable AI, Right click to disable." )
end

function TOOL:LeftClick( trace )
	local ent = trace.Entity

	if not IsValid( ent ) or not ent.LFS then return false end

	if isfunction( ent.SetAI ) then
		ent:SetAI( true )
		ent:SetAITEAM( self:GetClientNumber( "aiteam" ) )
	end

	return true
end

function TOOL:RightClick( trace )
	local ent = trace.Entity

	if not IsValid( ent ) or not ent.LFS then return false end

	if isfunction( ent.SetAI ) then
		ent:SetAI( false )

	end

	return true
end

function TOOL:Reload( trace )
	return false
end

function TOOL:Think()
	if SERVER then return end

	local ply = LocalPlayer()
	local tr = ply:GetEyeTrace()

	local ent = tr.Entity
	if not IsValid( ent ) or not ent.LFS then return end

	local Text = tostring(ent:GetAITEAM())

	AddWorldTip( ent:EntIndex(), Text, SysTime() + 0.05, ent:GetPos(), ent )
end

function TOOL.BuildCPanel( panel )

	local cbox = panel:ComboBox( "AI Team", "lfsaienabler_aiteam" )
	cbox:AddChoice( "0 - Friendly to everyone", 0 )
	cbox:AddChoice( "1 - Friendly to team 1 and 0, hostile to everything else", 1 )
	cbox:AddChoice( "2 - Friendly to team 2 and 0, hostile to everything else", 2 )
	cbox:AddChoice( "3 - Hostile to everyone", 3 )
end
