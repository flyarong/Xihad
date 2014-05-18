require 'Assets.script.AllPackages'	-- change package.path

-- local resume = coroutine.resume
-- coroutine.resume = function(co, ...)
-- 	print('resuming from ', coroutine.running(), ' to ', co)
-- 	return resume(co, ...)
-- end

-- create g_scheduler
local functional 	= require 'std.functional'
local TaskScheduler = require 'Scheduler.TaskScheduler'
g_scheduler = TaskScheduler.new()
g_scene:appendUpdateHandler { 
	onUpdate = functional.bindself(g_scheduler, 'onUpdate')
}

g_scene:requireSystem(c"Render")	-- load Irrlicht render component system
local levelPath = 'Assets/level/level_01.battle'
local userSavePath = 'User/sav/Save1.hero'

require 'cegui'
require 'math3d'					-- load math3d
require 'CreateMesh'				-- create cube mesh

local LevelFactory 	= require 'Level.XihadLevelFactory'
local WarriorFactory= require 'Warrior.WarriorFactory'

-- register game specific properties
local Warrior = require 'Warrior'
Warrior.registerProperty('MHP')
Warrior.registerProperty('ATK')
Warrior.registerProperty('DFS')
Warrior.registerProperty('MTK')
Warrior.registerProperty('MDF')
Warrior.registerProperty('MAP')

local battle = dofile(levelPath)
local heros  = dofile(userSavePath)
local warriorFactory = WarriorFactory.new()
local loader = LevelFactory.new({ Enemy = warriorFactory, Hero = warriorFactory }, heros)
g_chessboard = loader:create(battle)

local CameraFactory= require 'Camera.SimpleCameraFactory'
local CameraFacade = require 'Camera.CameraFacade'
local cameraObject = CameraFactory.createDefault('camera')
local cameraFacade = CameraFacade.new(cameraObject)
local debugFocusCharacter = {
	onKeyUp = function (self, e)
		print('onKeyUp', e.key)
		local object = g_scene:findObject(c(string.upper(e.key)))
		if not object or not object:findComponent(c'Warrior') then 
			return 1 
		end
		
		local asyncFocus = coroutine.wrap(cameraFacade.focus)
		asyncFocus(cameraFacade, object)
		return 0
	end
}
g_scene:pushController(debugFocusCharacter)
debugFocusCharacter:drop()

-- ADD LIGHT
local sun = g_scene:createObject(c'sun')
local lightControl = sun:appendComponent(c'Light')
lightControl:castShadow(false)
lightControl:setType 'direction'
sun:concatTranslate(math3d.vector(0, 30, 0))

local CommandExecutor = require 'Command.CommandExecutor'
local cmdExecutor = CommandExecutor.new(cameraFacade)

-- INPUT
local ui = {
	showWarriorInfo = function (self, warrior)
		print('ui info: ', warrior:getHostObject():getID())
	end,
	
	showTileInfo = function (self, tile)
		print('ui info: ', tile:getTerrain().type)
	end,
	
	warning = function (self, msg)
		print(msg)
	end,
}

local painter = {
	colorTable = { 
		Reachable   = Color.white, 
		Selected 	= Color.black,
		Destination = Color.cyan,
		Attack      = Color.orange,
		Castable    = Color.magenta,
	},
	
	mark = function (self, tiles, type)
		if not tiles then return end
		
		local color = Color.new(self.colorTable[type])
		
		local handle = {}
		for _, tile in ipairs(tiles) do
			local terrian = tile:getTerrain()
			local idx = terrian:pushColor(color)
			handle[terrian] = idx
		end
		
		return handle
	end,
	
	clear = function (self, handle)
		if not handle then return end
		
		for terrian, idx in pairs(handle) do
			terrian:removeColor(idx)
		end
	end,
}

local PCInputTransformer = require 'Controller.PCInputTransformer'
local PlayerStateMachine = require 'Controller.PlayerStateMachine'
local ControllerAdapter  = require 'Controller.ControllerAdapter'
local stateMachine= PlayerStateMachine.new(ui, cameraFacade, painter, cmdExecutor)
local controller = ControllerAdapter.new(PCInputTransformer.new(stateMachine))
g_scene:pushController(controller)
controller:drop()

local function startEnemy()
	print('player round over')
	for object in g_scene:objectsWithTag('Enemy') do
		local warrior = object:findComponent(c'Warrior')
		warrior:activate()
	end
	
	for object in g_scene:objectsWithTag('Enemy') do
		local tactic = object:findComponent(c'Tactic')
		local cmdList = tactic:giveOrder()
		print(tostring(cmdList))
		cmdExecutor:execute(cmdList)
	end
	
	print('player round begin')
	for object in g_scene:objectsWithTag('Hero') do
		local warrior = object:findComponent(c'Warrior')
		warrior:activate()
	end
	
	local hasActive = false
	for object in g_scene:objectsWithTag('Hero') do
		local warrior = object:findComponent(c'Warrior')
		if warrior:isActive() then
			hasActive = true
			break
		end
	end
	
	if hasActive then
		stateMachine:nextHero()
	else
		startEnemy()
	end
end

local finishListener = {}
function finishListener:onStateEnter(state, prev)
	assert(state == 'Finish', state)
	for object in g_scene:objectsWithTag('Hero') do
		local warrior = object:findComponent(c'Warrior')
		if warrior:isActive() then
			stateMachine:nextHero()
			return
		end
	end
	
	startEnemy()
end

function finishListener:onStateExit(state, next) end

stateMachine:addStateListener('Finish', finishListener)

local enemyRound = false
if not enemyRound then
	for heroObj in g_scene:objectsWithTag('Hero') do
		heroObj:findComponent(c'Warrior'):activate()
	end
else
	coroutine.wrap(startEnemy)()
end

g_world:setTimeScale(3)
