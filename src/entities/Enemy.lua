GameObject = require "src.entities.GameObject"
Explosion = require "src.entities.Explosion"
lume = require "lib.lume"

local Enemy = GameObject:extend()
local assets =  require "src.assets"

function Enemy:new(x, y, xVel, yVel)
	Enemy.super.new(self, x, y)
	self.name = "Enemy"
	self.isEnemy = true

	-- sprite/animation component
	self.sprite = assets.enemy
	self.offset = { x = 4, y = 4 }
	local g = anim8.newGrid(_G.TILE_SIZE, _G.TILE_SIZE, self.sprite:getWidth(), self.sprite:getHeight())
	self.animation = anim8.newAnimation(g('1-3',1), 0.1)

	-- movable component
	self.movable = {
		velocity = { x = xVel or 0, y = yVel or 0 },
		acceleration = { x = 0, y = 0 },
		drag = { x = 0, y = 0 }, -- 80 = gravity
		maxVelocity = { x = 80, y = 100 },
		speed = { x = 0, y = 0 } -- used to assign to acceleration
	}

	-- collider
	self.collider = HC:rectangle(self.pos.x - self.offset.x, self.pos.y - self.offset.y, _G.TILE_SIZE, _G.TILE_SIZE)
	self.collider['parent'] = self

	-- destroy off screen
	self.destroyOffScreen = true

	return self
end

function Enemy:update(dt)
end

function Enemy:onCollision(other)
	if other.isBullet and self.isAlive and other.isAlive then
		self:die()
	end
end

function Enemy:hit(damage)
end

function Enemy:die()
	self.toRemove = true

	corpsePs:setPosition(self.pos.x, self.pos.y)
	corpsePs:emit(10)

	-- add 5 explosions
	love.graphics.setColor(215, 232, 148)
	love.graphics.setLineStyle('rough')
	love.graphics.circle("fill", self.pos.x, self.pos.y, 15, 100 )

	for i=5,1,-1
	do
		timer.after((lume.random(0, 0.12)), function()
			world:add(Explosion(self.pos.x + lume.random(-10, 10), self.pos.y + lume.random(-10, 10)))
		end)
	end

	screen:setShake(12)
	screen:setRotation(0.05)
end

return Enemy
