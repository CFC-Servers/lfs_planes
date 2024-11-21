AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

function ENT:RunOnSpawn()
	for _, Pos in pairs( { Vector(5,-8,38), Vector(-35,-8,38), Vector(-35,8,38) } ) do
		self:AddPassengerSeat( Pos, self.SeatAng )
	end
end

function ENT:OnEngineStarted()
	self:EmitSound( "lfs/cessna/start.mp3" )
end

function ENT:OnEngineStopped()
	self:EmitSound( "lfs/cessna/stop.mp3" )
end
