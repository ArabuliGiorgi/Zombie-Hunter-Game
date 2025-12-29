local Defeat = {}
Defeat.__index = Defeat
local Audio = require("audio")

function Defeat:new(game)
    local self = setmetatable({}, Defeat)
    self.game = game

    -- Assets
    self.background = love.graphics.newImage("Images/Defeat.png")
    self.titleFont = love.graphics.newFont(64)
    self.menuFont = love.graphics.newFont(28)

    -- Colors
    self.buttonColor = {0.6, 0, 0}
    self.buttonHover = {0.9, 0.1, 0.1}
    self.textColor = {1, 1, 1}

    -- Button
    self.button = {
        w = 260,
        h = 60,
        hovered = false
    }

    return self
end

function Defeat:enter()
    Audio.stopMusic()
    Audio.playMusic("Audio/defeat.mp3", 0.8)

    game.upgradeManager:ResetAll()
    game.coins = 200  -- Reset coins to starting amount
end

-- ======================
-- DRAW
-- ======================
function Defeat:draw()
    local w, h = love.graphics.getDimensions()

    -- Background
    love.graphics.draw(
        self.background,
        0, 0,
        0,
        w / self.background:getWidth(),
        h / self.background:getHeight()
    )

    -- Button position
    self.button.x = w / 2 - self.button.w / 2
    self.button.y = h - 120

    -- Button
    if self.button.hovered then
        love.graphics.setColor(self.buttonHover)
    else
        love.graphics.setColor(self.buttonColor)
    end

    love.graphics.rectangle(
        "fill",
        self.button.x,
        self.button.y,
        self.button.w,
        self.button.h,
        10, 10
    )

    -- Button text
    love.graphics.setFont(self.menuFont)
    love.graphics.setColor(self.textColor)
    love.graphics.printf(
        "Main Menu",
        self.button.x,
        self.button.y + 15,
        self.button.w,
        "center"
    )

    love.graphics.setColor(1, 1, 1)
end

-- ======================
-- INPUT
-- ======================
function Defeat:keypressed(key)
    if key == "return" or key == "space" or key == "escape" then
        self.game.reset = true
        self.game.state:switch("menu")
    end
end

function Defeat:mousemoved(x, y)
    local b = self.button
    b.hovered =
        x >= b.x and x <= b.x + b.w and
        y >= b.y and y <= b.y + b.h
end

function Defeat:mousepressed(x, y, button)
    if button ~= 1 then return end

    local b = self.button
    if x >= b.x and x <= b.x + b.w and
       y >= b.y and y <= b.y + b.h then
        self.game.reset = true
        self.game.state:switch("menu")
    end
end

return Defeat