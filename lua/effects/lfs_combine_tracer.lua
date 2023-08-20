EFFECT.Mat = Material( "effects/gunshiptracer" )

function EFFECT:Init( data )

	self.StartPos = data:GetStart()
	self.EndPos = data:GetOrigin()

	self.Dir = self.EndPos - self.StartPos

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

	self.TracerTime = math.min( 1, self.StartPos:Distance( self.EndPos ) / 15000 )
	self.Length = math.Rand( 0.1, 0.15 )

	-- Die when it reaches its target
	self.DieTime = CurTime() + self.TracerTime

	local Dir = self.Dir:GetNormalized()

	local emitter = ParticleEmitter( self.StartPos, false )

	for i = 0, 12 do
		local Pos = self.StartPos + Dir * i * 0.7 * math.random(1,2) * 0.5

		local particle = emitter:Add( "effects/gunshipmuzzle", Pos )
		local Size = 1

		if particle then
			particle:SetVelocity( Dir * 800 )
			particle:SetDieTime( 0.05 )
			particle:SetStartAlpha( 255 * Size )
			particle:SetStartSize( math.max( math.random(20,48) - i * 0.5,0.1 ) * Size )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 255,255,255 )
			particle:SetCollide( false )
		end
	end

	for i = 0, 5 do
		local particle = emitter:Add( "effects/combinemuzzle2", self.EndPos )

		if particle then
			particle:SetVelocity( VectorRand() * 30 )
			particle:SetDieTime( 0.25 )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 0 )
			particle:SetEndSize( math.Rand(5,20) )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 255,255,255 )
			particle:SetCollide( false )
		end
	end

	emitter:Finish()

end

function EFFECT:Think()

	if CurTime() > self.DieTime then
		return false
	end

	return true

end

function EFFECT:Render()

	local fDelta = ( self.DieTime - CurTime() ) / self.TracerTime
	fDelta = math.Clamp( fDelta, 0, 1 ) ^ 1

	local sinWave = math.sin( fDelta * math.pi )

	local Pos1 = self.EndPos - self.Dir * ( fDelta - sinWave * self.Length )

	render.SetMaterial( self.Mat )
	render.DrawBeam( Pos1,
		self.EndPos - self.Dir * ( fDelta + sinWave * self.Length ),
		15, 1, 0, Color(255,255,255,255) )
end
