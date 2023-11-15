AddCSLuaFile()

SWEP.Category			= "Other"
SWEP.PrintName			= "[LFS] Missile Launcher"
SWEP.Author				= "Luna"
SWEP.Slot				= 4
SWEP.SlotPos			= 9

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false
SWEP.ViewModel			= "models/weapons/c_rpg.mdl"
SWEP.WorldModel			= "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 53
SWEP.Weight 			= 42
SWEP.AutoSwitchTo 		= true
SWEP.AutoSwitchFrom		= true
SWEP.HoldType			= "rpg"

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 8
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo1			= "RPG_Round"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:SetupDataTables()
	self:NetworkVar( "Entity",0, "ClosestEnt" )
	self:NetworkVar( "Float",0, "ClosestDist" )
	self:NetworkVar( "Bool",0, "IsLocked" )
end

local wepIconColor = Color( 255, 210, 0, 255 )
function SWEP:DrawWeaponSelection( x, y, wide, tall, _ )
	draw.SimpleText( "i", "WeaponIcons", x + wide / 2, y + tall * 0.2, wepIconColor, TEXT_ALIGN_CENTER )
end

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

local lfsRpgLockTime = CreateConVar( "lfs_rpglocktime", 3, FCVAR_ARCHIVE )
local lfsRpgLockAngle = CreateConVar( "lfs_rpglockangle", 15, FCVAR_ARCHIVE )

function SWEP:Think()
	if CLIENT then return end

	self.nextSortTargets = self.nextSortTargets or 0
	self.FindTime = self.FindTime or 0
	self.nextFind = self.nextFind or 0

	local curtime = CurTime()
	local Owner = self:GetOwner()

	if self.FindTime + lfsRpgLockTime:GetFloat() < curtime and IsValid( self:GetClosestEnt() ) then
		self.Locked = true
	else
		self.Locked = false
	end

	if self.Locked ~= self:GetIsLocked() then
		self:SetIsLocked( self.Locked )

		if self.Locked then
			self.LockSND = CreateSound( Owner, "lfs/radar_lock.wav" )
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

	if self.nextFind < curtime then
		self.nextFind = curtime + 3
		self.FoundVehicles = {}

		for _, vehicle in pairs( simfphys.LFS:PlanesGetAll() ) do
			if vehicle.LFS then
				table.insert( self.FoundVehicles, vehicle )
			end
		end

		for _, vehicle in pairs( ents.FindByClass( "wac_hc*" ) ) do
			table.insert( self.FoundVehicles, vehicle )
		end

		for _, vehicle in pairs( ents.FindByClass( "wac_pl*" ) ) do
			table.insert( self.FoundVehicles, vehicle )
		end

		for _, vehicle in ipairs( ents.FindByClass( "prop_vehicle_*" ) ) do
			if IsValid( vehicle:GetDriver() ) then
				table.insert( self.FoundVehicles, vehicle )
			end
		end
	end

	if self:Clip1() <= 0 then
		self:SetClosestEnt( nil )
		if self.TrackSND then
			self.TrackSND:Stop()
			self.TrackSND = nil
		end

	elseif self.nextSortTargets < curtime then
		self.nextSortTargets = curtime + 0.25
		self.FoundVehicles = self.FoundVehicles or {}

		local AimForward = Owner:GetAimVector()
		local startpos = Owner:GetShootPos()

		local Vehicles = {}
		local ClosestEnt = NULL
		local ClosestDist = math.huge
		local SmallestAng = math.huge

		for index, vehicle in pairs( self.FoundVehicles ) do
			if not IsValid( vehicle ) then self.FoundVehicles[ index ] = nil continue end

			local hookResult = hook.Run( "LFS.RPGBlockLockon", self, vehicle )
			if hookResult == true then self.FoundVehicles[ index ] = nil continue end

			local sub = ( vehicle:GetPos() - startpos )
			local toEnt = sub:GetNormalized()
			local Ang = math.acos( math.Clamp( AimForward:Dot( toEnt ), -1, 1 ) ) * ( 180 / math.pi )

			if Ang >= lfsRpgLockAngle:GetInt() or not self:CanSee( vehicle, Owner ) then continue end

			table.insert( Vehicles, vehicle )

			local stuff = WorldToLocal( vehicle:GetPos(), Angle( 0, 0, 0 ), startpos, Owner:EyeAngles() + Angle(90,0,0) )
			local dist = stuff:Length()

			if dist < ClosestDist and Ang < SmallestAng then
				ClosestDist = dist
				SmallestAng = Ang
				if ClosestEnt ~= vehicle then
					ClosestEnt = vehicle
				end
			end
		end

		if self:GetClosestEnt() ~= ClosestEnt then
			self:SetClosestEnt( ClosestEnt )
			self:SetClosestDist( ClosestDist )

			self.FindTime = curtime

			if IsValid( ClosestEnt ) then
				self.TrackSND = CreateSound( Owner, "lfs/radar_track.wav" )
				self.TrackSND:PlayEx( 0, 100 )
				self.TrackSND:ChangeVolume( 0.5, 2 )
			elseif self.TrackSND then
				self.TrackSND:Stop()
				self.TrackSND = nil
			end
		end

		if not IsValid( ClosestEnt ) and self.TrackSND then
			self.TrackSND:Stop()
			self.TrackSND = nil
		end
	end
end

function SWEP:CanSee( entity, owner )
	local pos = entity:GetPos()

	owner = owner or self:GetOwner()

	local trStruc = {
		start = owner:GetShootPos(),
		endpos = pos,
		filter = owner,
	}

	local trResult = util.TraceLine( trStruc )
	return ( trResult.HitPos - pos ):Length() < 500
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimaryFire( CurTime() + 0.5 )
	self:TakePrimaryAmmo( 1 )

	timer.Simple( 0, function()
		if not IsValid( self ) then return end
		if not SERVER then return end
		self:Reload()

	end )

	local Owner = self:GetOwner()

	Owner:ViewPunch( Angle( -10, -5, 0 ) )

	if CLIENT then return end

	Owner:EmitSound( "Weapon_RPG.NPC_Single" )

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

	if IsValid( LockOnTarget ) and self:GetIsLocked() then
		ent:SetLockOn( LockOnTarget )
	end
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

local NextFind = 0
local AllPlanes = {}
local function PaintPlaneIdentifier( ply )
	if NextFind < CurTime() then
		NextFind = CurTime() + 3
		AllPlanes = simfphys.LFS:PlanesGetAll()
	end

	local MyPos = ply:GetPos()
	local MyTeam = ply:lfsGetAITeam()
	local startpos = ply:GetShootPos()

	for _, vehicle in pairs( AllPlanes ) do
		if not IsValid( vehicle ) then continue end

		local rPos = vehicle:LocalToWorld( vehicle:OBBCenter() )

		local Pos = rPos:ToScreen()
		local Dist = ( MyPos - rPos ):Length()
		if util.TraceLine( { start = startpos,endpos = rPos,mask = MASK_NPCWORLDSTATIC } ).Hit then continue end

		local Alpha = math.max( 255 - Dist * 0.015, 0 )
		local Team = vehicle:GetAITEAM()
		local IndicatorColor = Color( 255, 0, 0, Alpha )

		if Team == 0 then
			IndicatorColor = Color( 0, 255, 0, Alpha )
		elseif Team == 1 or Team == 2 then
			if Team ~= MyTeam and MyTeam ~= 0 then
				IndicatorColor = Color( 255, 0, 0, Alpha )
			else
				IndicatorColor = Color( 0, 127, 255, Alpha )
			end
		end

		simfphys.LFS.HudPaintPlaneIdentifier( Pos.x, Pos.y, IndicatorColor, vehicle )
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

	surface.DrawLine( scrW, scrH, X, Y )

	local Size = self:GetIsLocked() and 30 or 60

	surface.DrawLine( X - Size, Y + Size, X - Size * 0.5, Y + Size )
	surface.DrawLine( X + Size, Y + Size, X + Size * 0.5, Y + Size )

	surface.DrawLine( X - Size, Y + Size, X - Size, Y + Size * 0.5 )
	surface.DrawLine( X - Size, Y - Size, X - Size, Y - Size * 0.5 )

	surface.DrawLine( X + Size, Y + Size, X + Size, Y + Size * 0.5 )
	surface.DrawLine( X + Size, Y - Size, X + Size, Y - Size * 0.5 )

	surface.DrawLine( X - Size, Y - Size, X - Size * 0.5, Y - Size )
	surface.DrawLine( X + Size, Y - Size, X + Size * 0.5, Y - Size )


	X = X + 1
	Y = Y + 1
	surface.SetDrawColor( 0, 0, 0, 100 )
	surface.DrawLine( X - Size, Y + Size, X - Size * 0.5, Y + Size )
	surface.DrawLine( X + Size, Y + Size, X + Size * 0.5, Y + Size )

	surface.DrawLine( X - Size, Y + Size, X - Size, Y + Size * 0.5 )
	surface.DrawLine( X - Size, Y - Size, X - Size, Y - Size * 0.5 )

	surface.DrawLine( X + Size, Y + Size, X + Size, Y + Size * 0.5 )
	surface.DrawLine( X + Size, Y - Size, X + Size, Y - Size * 0.5 )

	surface.DrawLine( X - Size, Y - Size, X - Size * 0.5, Y - Size )
	surface.DrawLine( X + Size, Y - Size, X + Size * 0.5, Y - Size )
end