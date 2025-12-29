local MainMenu = {}
MainMenu.__index = MainMenu
local Audio = require("audio")

function MainMenu:new(game)
    local self = setmetatable({}, MainMenu)
    self.game = game

    -- Assets
    self.background = love.graphics.newImage("Images/MenuBackground.png")
    self.titleFont = love.graphics.newFont(64)
    self.menuFont = love.graphics.newFont(28)
    self.tutorialFont = love.graphics.newFont(24)

    -- Colors
    self.normalColor = {0.85, 0.85, 0.85}
    self.selectedColor = {1, 0.8, 0.2}

    -- Menu layout
    self.spacing = 45
    self.startY = 400
    self.cursor = 1

    self.showTutorial = false

    self.tutorialText =
    [[Welcome to Monster Hunter!

    • Click any hero to control it
    • Click esc to release control
    • Move with WASD
    • Aim with mouse
    • Shoot to survive
    • Monsters get stronger & faster after each wave
    • Collect coins to upgrade stuff between waves


    Good luck, hunter.]]

    self.menuOptions = {
        {
            "Start Game",
            function()
                self.game.state:switch("prepare")
            end
        },
        { "Tutorial", function()
                self.showTutorial = true
            end
        },
        { "Exit", function() love.event.quit() end }
    }

    return self
end

function MainMenu:drawBoldText(text, x, y, limit, align)
    love.graphics.printf(text, x, y, limit, align)
    love.graphics.printf(text, x + 1, y, limit, align)
    love.graphics.printf(text, x, y + 1, limit, align)
end

function MainMenu:drawTutorialModal()
    local w, h = love.graphics.getDimensions()

    -- Dark background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Box
    local boxW, boxH = 700, 500
    local boxX = w / 2 - boxW / 2
    local boxY = h / 2 - boxH / 2

    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 12, 12)

    -- Border
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 12, 12)

    -- Text
    love.graphics.setFont(self.tutorialFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        self.tutorialText,
        boxX + 20,
        boxY + 20,
        boxW - 40,
        "left"
    )

    -- OK button
    local btnW, btnH = 120, 50
    local btnX = w / 2 - btnW / 2
    local btnY = boxY + boxH - 70

    self.tutorialButton = {
        x = btnX,
        y = btnY,
        w = btnW,
        h = btnH
    }

    love.graphics.setColor(0.6, 0.1, 0.1)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 8, 8)

    love.graphics.setColor(1, 1, 1)
    self:drawBoldText("Okay", btnX, btnY + 8, btnW, "center")
end

-- ======================
-- THEME MUSIC
-- ======================
function MainMenu:enter()
    Audio.stopMusic()
    Audio.playMusic("Audio/menu.mp3", 1)
end

-- ======================
-- DRAW
-- ======================
function MainMenu:draw()
    local w, h = love.graphics.getDimensions()

    -- Background
    love.graphics.draw(
        self.background,
        0, 0,
        0,
        w / self.background:getWidth(),
        h / self.background:getHeight()
    )

    -- Title
    love.graphics.setFont(self.titleFont)

    -- Shadow
    love.graphics.setColor(0.2, 0, 0, 1)
    love.graphics.printf("Zombie Hunter", 4, 104, w, "center")

    -- Main red text
    love.graphics.setColor(0.8, 0.1, 0.1, 1)
    love.graphics.printf("Zombie Hunter", 0, 100, w, "center")

    love.graphics.setColor(1, 1, 1)

    -- Menu
    love.graphics.setFont(self.menuFont)

    for i, option in ipairs(self.menuOptions) do
        local y = self.startY + (i - 1) * self.spacing

        if i == self.cursor then
            love.graphics.setColor(self.selectedColor)
            self:drawBoldText("> " .. option[1], 0, y, w, "center")
        else
            love.graphics.setColor(self.normalColor)
            self:drawBoldText(option[1], 0, y, w, "center")
        end
    end

    love.graphics.setColor(1, 1, 1)

    if self.showTutorial then
        self:drawTutorialModal()
    end
end

-- ======================
-- KEYBOARD INPUT
-- ======================
function MainMenu:keypressed(key)
    if self.showTutorial then
        if key == "return" or key == "escape" then
            self.showTutorial = false
        end
        return
    end

    -- existing menu navigation
    if key == "up" then
        self.cursor = self.cursor - 1
        if self.cursor < 1 then self.cursor = #self.menuOptions end
    elseif key == "down" then
        self.cursor = self.cursor + 1
        if self.cursor > #self.menuOptions then self.cursor = 1 end
    elseif key == "return" or key == "space" then
        self.menuOptions[self.cursor][2]()
    end
end

-- ======================
-- MOUSE INPUT
-- ======================
function MainMenu:mousemoved(x, y)
    local w = love.graphics.getWidth()
    local menuWidth = 300
    local menuX1 = w / 2 - menuWidth / 2
    local menuX2 = w / 2 + menuWidth / 2

    -- Ignore mouse if outside menu horizontally
    if x < menuX1 or x > menuX2 then
        return
    end

    for i = 1, #self.menuOptions do
        local optionY = self.startY + (i - 1) * self.spacing
        if y >= optionY and y <= optionY + self.spacing then
            self.cursor = i
            return
        end
    end
end

function MainMenu:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self.showTutorial and self.tutorialButton then
        local b = self.tutorialButton
        if x >= b.x and x <= b.x + b.w and
           y >= b.y and y <= b.y + b.h then
            self.showTutorial = false
        end
        return
    end

    -- Only accept clicks inside the visible menu area and the specific option
    local w = love.graphics.getWidth()
    local menuWidth = 300
    local menuX1 = w / 2 - menuWidth / 2
    local menuX2 = w / 2 + menuWidth / 2

    if x < menuX1 or x > menuX2 then
        return
    end

    for i = 1, #self.menuOptions do
        local optionY = self.startY + (i - 1) * self.spacing
        if y >= optionY and y <= optionY + self.spacing then
            -- set cursor to clicked option and invoke its action
            self.cursor = i
            self.menuOptions[self.cursor][2]()
            return
        end
    end
end

return MainMenu