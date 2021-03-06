GameObject = require "src.entities.GameObject"
Bullet = require "src.entities.Bullet"

local Player = GameObject:extend()
local assets =  require "src.assets"

local gravity = 100 * 1.5
local flySpeed = 150 * 1.5
local leftRightSpeed = 800
local xDrag = 300
local maxVelY = 60

function Player:new()
	Player.super.new(self, push:getWidth()/2, push:getHeight()/2 - 20)
	self.name = "Player"
	self.isPlayer = true

	-- sprite component
	self.sprite = assets.player
	self.offset = { x = 4, y = 4 }
	self.flippedH = false
	local g = anim8.newGrid(12, 12, self.sprite:getWidth(), self.sprite:getHeight())
	shootBottom = anim8.newAnimation(g('1-5',1), .05, false)
	shootBottomRight = anim8.newAnimation(g('1-5',2), .05, false)
	shootRight = anim8.newAnimation(g('1-5',3), .05, false)
	shootUpRight = anim8.newAnimation(g('1-5',4), .05, false)
	shootUp = anim8.newAnimation(g('1-5',5), .05, false)
	self.animation = shootRight

	-- movable component
	self.movable = {
		velocity = { x = 0, y = 0 },
		acceleration = { x = 0, y = 0 },
		drag = { x = xDrag, y = -gravity }, -- 80 = gravity
		maxVelocity = { x = 80, y = maxVelY },
		speed = { x = 0, y = 0 } -- used to assign to acceleration
	}

	-- shooter component
	self.shooter = {
		atkDelay = 0.1,
		canAtk = true,
		shoot = false
	}
	self.shootAngle = 0

	-- collider
	self.collider = HC:rectangle(self.pos.x - 6, self.pos.y + 6, 3,3)
	self.collider:moveTo(self.pos.x, self.pos.y)
	self.collider['parent'] = self

	self.setupParticles()

	return self
end

function Player:update(dt)
	self:shootControls(dt)
	-- moveControls(self, dt)
	self:updateAnimations()

	self:checkBoundaries()

    bulletPs:update(dt)
	trailPs:update(dt)
end

function moveControls(self, dt)
	local z = love.keyboard.isDown('z')
	local left = love.keyboard.isDown('left')
	local right = love.keyboard.isDown('right')

	if z then
		self.movable.acceleration.y = -flySpeed
		-- self.movable.velocity.y = self.movable.maxVelocity.y
	else
		self.movable.acceleration.y = 0
	end

	if left and not right then
		self.movable.acceleration.x = -leftRightSpeed
	elseif right and not left then
		self.movable.acceleration.x = leftRightSpeed
	else
		self.movable.acceleration.x = 0
	end
end

function Player:shootControls(dt)
	local down = love.keyboard.isDown('down')
	local up = love.keyboard.isDown('up')
	local left = love.keyboard.isDown('left')
	local right = love.keyboard.isDown('right')

	self.shooter.shootUp = false
	self.shooter.shootDown = false
	self.shooter.shootLeft = false
	self.shooter.shootRight = false

	if up then
		self.movable.acceleration.y = flySpeed
	elseif down then
		self.movable.acceleration.y = -flySpeed
	else
		self.movable.acceleration.y = 0
	end

	if left then
		self.movable.acceleration.x = flySpeed/1.5
	elseif right then
		self.movable.acceleration.x = -flySpeed/1.5
	else
		self.movable.acceleration.x = 0
	end

	if left or up or down or right then
		self.shooter.shoot = true
		self.animation = shootRight
	end

	self.movable.maxVelocity.y = maxVelY

	if left then
		self.shootAngle = -90
		self.animation = shootRight

		if up then self.shootAngle = self.shootAngle + 45
			self.animation = shootUpRight
		elseif down then
			self.shootAngle = self.shootAngle - 45
			self.animation = shootBottomRight
		else
			self.movable.maxVelocity.y = maxVelY/10
		end
	elseif right then
		self.shootAngle = 90
		self.animation = shootRight

		if up then
			self.shootAngle = self.shootAngle - 45
			self.animation = shootUpRight
		elseif down then
			self.shootAngle = self.shootAngle + 45
			self.animation = shootBottomRight
		else
			self.movable.maxVelocity.y = maxVelY/10
		end
	elseif up then
		self.shootAngle = 0
		self.animation = shootUp
	elseif down then
		self.shootAngle = 180
		self.animation = shootBottom
	else
		self.animation = shootRight
	end

	if down then
		trailPs:setPosition(self.pos.x + math.random(-2,2), self.pos.y + 10)
		trailPs:emit(1)
	end
end

function Player:setupParticles()
	bulletPs = love.graphics.newParticleSystem(assets.shells, 100)
	bulletPs:setPosition(push:getWidth()/2, push:getHeight()/2)
	bulletPs:setParticleLifetime(0.3, 0.5)
	bulletPs:setDirection(1.5*3.14)
	bulletPs:setSpread(3.14/3)
	bulletPs:setSpeed(100, 150)
	bulletPs:setLinearAcceleration(0, 600)
	bulletPs:setLinearDamping(0.5)
	bulletPs:setSpin(3, 15)
	bulletPs:setRotation(0, 2*3.14)
	bulletPs:setInsertMode('random')

	trailPs = love.graphics.newParticleSystem(assets.smoke, 100)
	trailPs:setPosition(push:getWidth()/2, push:getHeight()/2)
	trailPs:setParticleLifetime(0.2, 0.4)
	trailPs:setDirection(1.5*3.14)
	trailPs:setSpread(3.14/3)
	trailPs:setLinearAcceleration(0, -400)
	trailPs:setLinearDamping(50)
	trailPs:setSpin(0, 30)
	trailPs:setColors(82, 127, 57, 255)
	trailPs:setRotation(0, 2*3.14)
	trailPs:setInsertMode('random')
	trailPs:setSizes(0.4, 0)
end

function Player:shoot(dt)
	-- shoot
	world:addEntity(Bullet(self.pos.x, self.pos.y, math.rad(self.shootAngle)))
	bullet_sfx = lume.randomchoice({
		assets.shoot1_sfx:clone(),
		assets.shoot3_sfx:clone(),
	})
	bullet_sfx:play()


	-- fx
	screen:setShake(1.5)

	bulletPs:setPosition(self.pos.x, self.pos.y)
	bulletPs:emit(1)

	love.graphics.setColor(215, 232, 148)
	love.graphics.setLineStyle('rough')

	local flashX = 0
	local flashY = 0

	-- Check shoot direction
	if love.keyboard.isDown('right') then
		flashX = 12
	elseif love.keyboard.isDown('left') then
		flashX = -12
	end

	if love.keyboard.isDown('up') then
		flashY = -12
	elseif love.keyboard.isDown('down') then
		flashY = 12
		-- trailPs:setPosition(self.pos.x + math.random(-2,2), self.pos.y + 12)
		-- trailPs:emit(1)
	end

	-- Draw gun flash in position flashX and flashY
	love.graphics.circle("fill", self.pos.x + math.random(-2,2) + flashX
														 , self.pos.y + math.random(-2,2) + flashY
														 , 5 + math.random(1,2), 100 )
end

function Player:draw()
    love.graphics.draw(bulletPs, 0, 0, 0, 1, 1)
		love.graphics.draw(trailPs, 0, 0, 0, 1, 1)
end

function Player:updateAnimations()
	if self.movable.acceleration.x < 0 then
		self.flippedH = false
	elseif self.movable.acceleration.x > 0 then
		self.flippedH = true
	end
end

function Player:onCollision(other, delta)
	if self.isAlive and (other.isEnemy or other.isEnemyBullet) and other.isAlive then
		other:die()
		self:die()
	end
end

function Player:die()
	death = assets.death:clone()
	death:play()
	
	timer.after(0.08, function() love.timer.sleep(0.1) end)

	screen:setShake(70)
	-- screen:setRotation(0.1)

	for i=5,1,-1
	do
		timer.after((lume.random(0, .2)), function()
			world:add(Explosion(self.pos.x + lume.random(-10, 10), self.pos.y + lume.random(-10, 10)))
		end)
	end

	self.toRemove = true

	playstate.gameover()
end

function Player:checkBoundaries()
	if self.pos.x <= 18 then
		self.pos.x = 18
	elseif self.pos.x >= push:getWidth() - 18 then
		self.pos.x = push:getWidth() - 18
	end

	if self.pos.y <= 28 or self.pos.y > 150 then
		self:die()
	end
end

return Player
