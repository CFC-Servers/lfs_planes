--DO NOT EDIT OR REUPLOAD THIS FILE

AddCSLuaFile()

SWEP.Category			= "Other"
SWEP.PrintName		= "[LFS] Missile Launcher"
SWEP.Author			= "Luna"
SWEP.Slot				= 4
SWEP.SlotPos			= 9
SWEP.DrawWeaponInfoBox 	= false
SWEP.BounceWeaponIcon = false

SWEP.Spawnable		= true
SWEP.AdminSpawnable	= false
SWEP.ViewModel		= "models/weapons/c_rpg.mdl"
SWEP.WorldModel		= "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 53
SWEP.Weight 			= 42
SWEP.AutoSwitchTo 		= true
SWEP.AutoSwitchFrom 	= true
SWEP.HoldType			= "rpg"

SWEP.Primary.ClipSize	= 1
SWEP.Primary.DefaultClip	= 8
SWEP.Primary.Automatic	= false
SWEP.Primary.Ammo		= "RPG_Round"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

local ANG_UP = Angle( 90, 0, 0 )
local ANG_ZERO = Angle( 0, 0, 0 )

local IsValid = IsValid
local WorldToLocal = WorldToLocal

local surface_DrawLine = surface.DrawLine

function SWEP:SetupDataTables()
	self:NetworkVar( "Entity",0, "ClosestEnt" )
	self:NetworkVar( "Float",0, "ClosestDist" )
	self:NetworkVar( "Bool",0, "IsLocked" )
end

local weaponSelectColor = Color( 255, 210, 0, 255 )
function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	draw.SimpleText( "i", "WeaponIcons", x + wide / 2, y + tall * 0.2, weaponSelectColor, TEXT_ALIGN_CENTER )
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:LockThink()
	if self.Locked == self:GetIsLocked() then return end
	self:SetIsLocked( self.Locked )
	
	if self.Locked then
		self.LockSND = CreateSound( self:GetOwner(), "lfs/radar_lock.wav" )
		self.LockSND:PlayEx( 0.5, 100 )
		
		if self.TrackSND then
			self.TrackSND:Stop()
			self.TrackSND = nil
		end
	else
		if self.LockSND then
			self.LockSND:Stop()
			self.LockSND = nil
		end
	end
end

function SWEP:StartTrackSound()
	self.TrackSND = CreateSound( self:GetOwner(), "lfs/radar_track.wav" )
	self.TrackSND:PlayEx( 0, 100 )
	self.TrackSND:ChangeVolume( 0.5, 2 )
end

function SWEP:StopTrackSound()
	self.TrackSND:Stop()
	self.TrackSND = nil
end

function SWEP:GuidedThink()
	self.FoundVehicles = self.FoundVehicles or {}
	
	local Owner = self:GetOwner()
	local AimForward = Owner:GetAimVector()
	local startpos = Owner:GetShootPos()

	local Vehicles = {}
	local ClosestEnt = NULL
	local ClosestDist = 0
	
	for k, v in ipairs( self.FoundVehicles ) do
		if IsValid( v ) then
			local sub = v:GetPos() - startpos

			local dist = sub:Length()
			local toEnt = sub:GetNormalized()
			local Ang = math.acos( math.Clamp( AimForward:Dot( toEnt ), -1, 1) ) * ( 180 / math.pi )
			
			if Ang < 30 and dist < 7500 and self:CanSee( v ) then
				table.insert( Vehicles, v )
				
				local stuff = WorldToLocal( v:GetPos(), ANG_ZERO, startpos, Owner:EyeAngles() + ANG_UP )
				stuff.z = 0
				local stuffDist = stuff:Length()
			
				if not IsValid( ClosestEnt ) then
					ClosestEnt = v
					ClosestDist = stuffDist
				end
				
				if stuffDist < ClosestDist then
					ClosestDist = stuffDist
					if ClosestEnt ~= v then
						ClosestEnt = v
					end
				end
			end
		else
			self.FoundVehicles[k] = nil
		end
	end
	
	if self:GetClosestEnt() ~= ClosestEnt then
		self:SetClosestEnt( ClosestEnt )
		self:SetClosestDist( ClosestDist )
		
		self.FindTime = CurTime()
		
		if IsValid( ClosestEnt ) then
			self:StartTrackSound( ClosestEnt )
		else
			if self.TrackSND then
				self:StopTrackSound()
			end
		end
	end
	
	if not IsValid( ClosestEnt ) and self.TrackSND then
		self.TrackSND:Stop()
		self.TrackSND = nil
	end
end

function SWEP:FindVehicles()
	self.FoundVehicles = {}
	local foundVehicles = self.FoundVehicles
	
	local class
	for _, ent in ipairs( ents.GetAll() ) do
		if ent.LFS then
			table.insert( foundVehicles, ent )
		else
			class = ent:GetClass()

			if string.StartsWith( class, "wac_hc" ) then
				table.insert( foundVehicles, ent )
			end

			if string.StartsWith( class, "wac_pl" ) then
				table.insert( foundVehicles, ent )
			end
		end
	end
end

function SWEP:Think()
	if CLIENT then return end
	
	self.guided_nextThink = self.guided_nextThink or 0
	self.FindTime = self.FindTime or 0
	self.nextFind = self.nextFind or 0
	
	local curtime = CurTime()
	
	if self.FindTime + 3 < curtime and IsValid( self:GetClosestEnt() ) then
		self.Locked = true
	else
		self.Locked = false
	end

	self:LockThink()
	
	if self.nextFind < curtime then
		self.nextFind = curtime + 3
		self:FindVehicles()
	end
	
	if self.guided_nextThink < curtime then
		self.guided_nextThink = curtime + 0.25
		self:GuidedThink()
	end
end

-- TODO: Can this be refactored to use self:GetOwner():Visible( entity ) or a basic distance check?
local canSeeFilter = {}
local canSeeTrace = {}
function SWEP:CanSee( entity )
	local pos = entity:GetPos()
	local owner = self:GetOwner()

	canSeeFilter[1] = self:GetOwner()
	canSeeTrace.start = owner:GetShootPos()
	canSeeTrace.endpos = pos
	canSeeTrace.filter = canSeeFilter
	
	local tr = util.TraceLine( canSeeFilter )

	return (tr.HitPos - pos):Length() < 500
end

local punchAngle = Angle( -10, -5, 0 )
function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	self:SetNextPrimaryFire( CurTime() + 0.5 )	
	
	self:TakePrimaryAmmo( 1 )
	
	local Owner = self:GetOwner()
	Owner:ViewPunch( punchAngle )
	
	if CLIENT then return end

	if not self:GetIsLocked() then return end
	
	Owner:EmitSound("Weapon_RPG.NPC_Single")
	
	local startpos = Owner:GetShootPos() + Owner:EyeAngles():Right() * 10
	local ent = ents.Create( "lunasflightschool_missile" )
	ent:SetPos( startpos )
	ent:SetAngles( ( Owner:GetEyeTrace().HitPos - startpos ):Angle() )
	ent:SetOwner( Owner )
	ent.Attacker = Owner
	ent:Spawn()
	ent:Activate()
	
	ent:SetAttacker( Owner )
	ent:SetInflictor( Owner:GetActiveWeapon() )
	
	local LockOnTarget = self:GetClosestEnt()
	if not IsValid( LockOnTarget ) then return end

	ent:SetLockOn( LockOnTarget )
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	return true
end

function SWEP:Reload()
	if self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 then
		self:DefaultReload( ACT_VM_RELOAD )
		self:UnLock()
	end
end

function SWEP:UnLock()
	self:StopSounds()
end

function SWEP:StopSounds()
	if self.TrackSND then
		self.TrackSND:Stop()
		self.TrackSND = nil
	end
	
	if self.LockSND then
		self.LockSND:Stop()
		self.LockSND = nil
	end
	
	self:SetClosestEnt( NULL )
	self:SetClosestDist( 99999999999999 )
	self:SetIsLocked( false )
end

function SWEP:Holster()
	self:StopSounds()
	return true
end

function SWEP:OnDrop()
	self:StopSounds()
end

function SWEP:OwnerChanged()
	self:StopSounds()
end

local traceTable = { mask = MASK_NPCWORLDSTATIC }
local RED = { 255, 0, 0 }
local GREEN = { 0, 255, 0 } 
local AZURE = { 0, 127, 255 }

local function paintIdentifierForPlane( plane, myPos, myTeam, startPos )
	if not IsValid( plane ) then return end

	local rPos = plane:LocalToWorld( plane:OBBCenter() )
	local screenPos = rPos:ToScreen()
	local Dist = ( myPos - rPos ):Length()
	if Dist >= 13000 then return end

	traceTable.start = startPos
	traceTable.endpos = rPos
	if util.TraceLine( traceTable ).Hit then return end

	local color = RED
	local Team = plane:GetAITEAM()
	local alpha = math.max( 255 - Dist * 0.015, 0 )

	if Team == 0 then
		color = GREEN
	else
		if Team == 1 or Team == 2 then
			if Team ~= MyTeam and MyTeam ~= 0 then
				color = RED
			else
				color = AZURE
			end
		end
	end

	simfphys.LFS.HudPaintPlaneIdentifier( plane, screenPos.x, screenP.y, color[1], color[2], color[3], alpha )
end

local NextFind = 0
local AllPlanes = {}
local function PaintPlaneIdentifier( ply )
	if NextFind < CurTime() then
		NextFind = CurTime() + 3
		AllPlanes = simfphys.LFS:PlanesGetAll()
	end

	local myPos = ply:GetPos()
	local myTeam = ply:lfsGetAITeam()
	local startpos = ply:GetShootPos()

	for _, v in pairs( AllPlanes ) do
		paintIdentifierForPlane( v, myPos, myTeam, startpos )
	end
end

function SWEP:DrawHUD()
	local ply = LocalPlayer()
	if ply:InVehicle() then return end

	PaintPlaneIdentifier( ply )

	local ent = self:GetClosestEnt()
	if not IsValid( ent ) then return end
	
	local pos = ent:LocalToWorld( ent:OBBCenter() )
	
	local scr = pos:ToScreen()
	local scrW = ScrW() / 2
	local scrH = ScrH() / 2

	local X = scr.x
	local Y = scr.y
	
	draw.NoTexture()
	if self:GetIsLocked() then
		surface.SetDrawColor( 200, 0, 0, 255 )
	else
		surface.SetDrawColor( 200, 200, 200, 255 )
	end
	
	surface_DrawLine( scrW, scrH, X, Y )

	local Size = self:GetIsLocked() and 30 or 60

	surface_DrawLine( X - Size, Y + Size, X - Size * 0.5, Y + Size )
	surface_DrawLine( X + Size, Y + Size, X + Size * 0.5, Y + Size )

	surface_DrawLine( X - Size, Y + Size, X - Size, Y + Size * 0.5 )
	surface_DrawLine( X - Size, Y - Size, X - Size, Y - Size * 0.5 )

	surface_DrawLine( X + Size, Y + Size, X + Size, Y + Size * 0.5 )
	surface_DrawLine( X + Size, Y - Size, X + Size, Y - Size * 0.5 )

	surface_DrawLine( X - Size, Y - Size, X - Size * 0.5, Y - Size )
	surface_DrawLine( X + Size, Y - Size, X + Size * 0.5, Y - Size )


	X = X + 1
	Y = Y + 1
	surface.SetDrawColor( 0, 0, 0, 100 )
	surface_DrawLine( X - Size, Y + Size, X - Size * 0.5, Y + Size )
	surface_DrawLine( X + Size, Y + Size, X + Size * 0.5, Y + Size )

	surface_DrawLine( X - Size, Y + Size, X - Size, Y + Size * 0.5 )
	surface_DrawLine( X - Size, Y - Size, X - Size, Y - Size * 0.5 )

	surface_DrawLine( X + Size, Y + Size, X + Size, Y + Size * 0.5 )
	surface_DrawLine( X + Size, Y - Size, X + Size, Y - Size * 0.5 )

	surface_DrawLine( X - Size, Y - Size, X - Size * 0.5, Y - Size )
	surface_DrawLine( X + Size, Y - Size, X + Size * 0.5, Y - Size )
end
