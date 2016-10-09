io.stdout:setvbuf("no")

-- Global libraries
class = require "lib.30log"
tiny = require "lib.tiny"
editgrid = require "lib.editgrid"
Gamestate = require "lib.hump.gamestate"
Object = require "lib.classic"
timer = require "lib.hump.timer"
anim8 = require "lib.anim8"
gamera = require "lib.gamera"

-- Ulydev camera options
Camera = require "lib.hump.camera"
screen = require "lib.shack"
push = require "lib.push"

-- utils
log = require "lib.log"
tlog = require "lib.alfonzm.tlog"
escquit = require "lib.alfonzm.escquit"

-- States
PlayState = require "playstate"
MenuState = require "menustate"

local assets =  require "src.assets"

-- Declare tiny-ecs world
world = {}
camera = nil

-- Game stuff
local scale = 1

function love.load()
	_G.TILE_SIZE = 8
	scale = love.graphics.getWidth() / 160
	setupPushScreen()
	camera = Camera(0,0)

	Gamestate.registerEvents()
	Gamestate.switch(MenuState)
	-- Gamestate.switch(PlayState)


	palette1ShaderCode = [[
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
		{
			vec4 c = Texel(texture, texture_coords);		

			return vec4(c.r, c.g, c.b, 1.0);
		}
	]]

	palette1Shader = love.graphics.newShader(palette1ShaderCode)
end

function love.update(dt)
	screen:update(dt)
	timer.update(dt)
end

function love.draw()
	-- camera:attach()
	push:apply("start")
	screen:apply()

	if world and world.update then
		world:update(love.timer.getDelta())
	end
	push:apply("end")
	-- camera:detach()
end

function setupPushScreen()
	-- setup push screen
	local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
	local gameWidth, gameHeight = windowWidth / scale, windowHeight / scale
	push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {fullscreen = false})
	screen:setDimensions(push:getDimensions())
end