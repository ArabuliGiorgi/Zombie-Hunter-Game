local GameState = require("States.gameState")
local MainMenu  = require("States.mainmenu")
local PrepareState = require("States.prepareState")
local GamePlay = require("States.game")
local Defeat = require("States.defeat")
local Victory = require("States.victory")
local UpgradeManager = require("managers.upgradeManager")

function love.load()
    game = {}

    -- Global systems
    game.coins = 200
    game.upgradeManager = UpgradeManager:new()
    game.heroPositions = {
        { x = 260, y = 260  },
        { x = 260, y = 380  },
        { x = 150,  y = 260  },
        { x = 150,  y = 380  }
    }

    -- Game state controller
    game.state = GameState:new()
    game.reset = false
    game.music = true

    -- States
    game.mainMenu = MainMenu:new(game)
    game.prepareState = PrepareState:new(game)
    game.gameState = GamePlay:new(game)
    game.defeatState = Defeat:new(game)
    game.victoryState = Victory:new(game)

    game.state:register("menu", game.mainMenu)
    game.state:register("prepare", game.prepareState)
    game.state:register("game", game.gameState)
    game.state:register("defeat", game.defeatState)
    game.state:register("victory", game.victoryState)

    -- Start at menu
    game.state:switch("menu")
end

function love.update(dt)
    game.state:update(dt)
end

function love.draw()
    game.state:draw()
end

function love.keypressed(key)
    game.state:keypressed(key)
end

function love.mousepressed(x, y, button)
    game.state:mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    if not game or not game.state then return end

    -- Prefer GameState-level handler if it exists
    if game.state.mousemoved then
        pcall(function() game.state:mousemoved(x, y, dx, dy) end)
    end

    -- Also forward directly to the currently active state if available
    if game.state.current and game.state.current.mousemoved then
        pcall(function() game.state.current:mousemoved(x, y, dx, dy) end)
    end
end