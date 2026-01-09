local sti = require("Libraries/sti")
local PrepareState = {}
PrepareState.__index = PrepareState
local Hero = require("entities/hero")
local Audio = require("audio")

function PrepareState:new(game)
    map = sti("Maps/MH_map.lua")
    local self = setmetatable({}, PrepareState)

    heroWalls = {}
    for _, obj in pairs(map.layers["ForCharacter"].objects) do
        table.insert(heroWalls, {
            x = obj.x,
            y = obj.y,
            width = obj.width,
            height = obj.height
        })
    end
    self.heroes = {}
    for i = 1, game.upgradeManager.heroAmount do
        local pos = game.heroPositions[i]
        local hero = Hero:new(pos.x, pos.y, game.upgradeManager.weaponLevel, game.upgradeManager.hpLevel, heroWalls)
        table.insert(self.heroes, hero)
    end

    self.game = game
    self.upgradeManager = game.upgradeManager

    -- UI
    self.showTextbox = true
    self.buttons = {}

    self.titleFont  = love.graphics.newFont(22)
    self.buttonFont = love.graphics.newFont(18)
    self.smallFont  = love.graphics.newFont(14)

    self:createButtons()

    -- currently controlled hero (or nil)
    self.controlledHero = nil

    return self
end

-- ======================
-- THEME MUSIC
-- ======================
function PrepareState:enter()
    Audio.stopMusic()
    Audio.playMusic("Audio/gametheme.mp3", 0.8)

    if not self.game.reset then
        return
    end
    -- Recreate heroes to reflect reset upgrades
    self.heroes = {}
    for i = 1, self.game.upgradeManager.heroAmount do
        local pos = self.game.heroPositions[i]
        local hero = Hero:new(pos.x, pos.y, self.game.upgradeManager.weaponLevel, self.game.upgradeManager.hpLevel, heroWalls)
        table.insert(self.heroes, hero)
    end
    self.controlledHero = nil
end

function PrepareState:canAfford(price)
    return self.game.coins >= price
end

function PrepareState:createButtons()
    self.buttons = {
        {
            id = "weapon",
            text = "Upgrade Weapon",
            getLevel = function()
                return self.upgradeManager.weaponLevel
            end,
            getPrice = function()
                return self.upgradeManager:getWeaponPrice()
            end
        },
        {
            id = "hp",
            text = "Upgrade HP",
            getLevel = function()
                return self.upgradeManager.hpLevel
            end,
            getPrice = function()
                return self.upgradeManager:getHPPrice()
            end
        },
        {
            id = "hero",
            text = "Add Hero",
            getLevel = function()
                return self.upgradeManager.heroAmount
            end,
            getPrice = function()
                return self.upgradeManager:getHeroPrice()
            end
        },
        {
            id = "start",
            text = "Start War",
            isStart = true
        }
    }
end

function PrepareState:drawUpgradeBox()
    local w, h = love.graphics.getDimensions()

    local boxW, boxH = 450, 500
    local boxX = w - boxW - 40
    local boxY = h / 2 - boxH / 2

    local padding = 30

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 12, 12)

    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        "Prepare for Next Wave",
        boxX, boxY + 20, boxW, "center"
    )

    -- ======================
    -- UPGRADE BUTTONS
    -- ======================
    local btnW, btnH = boxW - 200, 70
    local btnX = boxX + padding
    local startY = boxY + 90
    local spacing = 20

    -- Right column for levels
    local levelX = boxX + boxW - 90

    local row = 0
    for _, btn in ipairs(self.buttons) do
        if not btn.isStart then
            row = row + 1
            local by = startY + (row - 1) * (btnH + spacing)

            -- Button color and label (show Maxed when nil)
            local price = btn.getPrice()
            if price == nil then
                love.graphics.setColor(0.35, 0.35, 0.35) -- grey (maxed)
            else
                if self:canAfford(price) then
                    love.graphics.setColor(0.2, 0.6, 0.2) -- green
                else
                    love.graphics.setColor(0.35, 0.35, 0.35) -- grey
                end
            end

            -- Button
            love.graphics.rectangle("fill", btnX, by, btnW, btnH, 10, 10)

            -- Text inside button
            love.graphics.setFont(self.buttonFont)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.text, btnX, by + 10, btnW, "center")

            love.graphics.setFont(self.smallFont)
            if price == nil then
                love.graphics.printf("Maxed", btnX, by + btnH - 22, btnW, "center")
            else
                love.graphics.printf("Price: " .. price, btnX, by + btnH - 22, btnW, "center")
            end

            -- Level text (RIGHT SIDE OF BOX)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(
                "Level: " .. btn.getLevel(),
                levelX,
                by + btnH / 2 - 8
            )
        end
    end

    -- ======================
    -- START WAR BUTTON (SEPARATE)
    -- ======================
    local startBtnW = boxW - 160
    local startBtnH = 80
    local startBtnX = boxX + (boxW - startBtnW) / 2
    local startBtnY = boxY + boxH - startBtnH - 30

    love.graphics.setColor(0.7, 0.1, 0.1) -- red
    love.graphics.rectangle("fill", startBtnX, startBtnY, startBtnW, startBtnH, 14, 14)

    love.graphics.setFont(self.buttonFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        "START WAR",
        startBtnX,
        startBtnY + startBtnH / 2 - 10,
        startBtnW,
        "center"
    )

    love.graphics.setColor(1, 1, 1)
end

function PrepareState:update(dt)
    map:update(dt)
    for _, hero in ipairs(self.heroes) do
        hero:update(dt)
    end
    -- nothing yet
end

function PrepareState:keypressed(key)
    if key == "escape" then
        if self.controlledHero then
            self.controlledHero:startReturn()
            self.controlledHero = nil
        end
    end
end

function PrepareState:mousepressed(x, y, button)
    if button ~= 1 then return end
    -- First: check clicks inside the upgrade box (buttons)
    local w, h = love.graphics.getDimensions()
    local boxW, boxH = 450, 500
    local boxX = w - boxW - 40
    local boxY = h / 2 - boxH / 2

    if x >= boxX and x <= boxX + boxW and y >= boxY and y <= boxY + boxH then
        local padding = 30
        local btnW, btnH = boxW - 200, 70
        local btnX = boxX + padding
        local startY = boxY + 90
        local spacing = 20

        -- Non-start buttons
        local row = 0
        for _, btn in ipairs(self.buttons) do
            if not btn.isStart then
                row = row + 1
                local by = startY + (row - 1) * (btnH + spacing)
                if x >= btnX and x <= btnX + btnW and y >= by and y <= by + btnH then
                    local price = btn.getPrice()
                    if price == nil then return end
                    if not self:canAfford(price) then return end

                    -- apply upgrade via manager methods (safe, enforces max)
                    if btn.id == "weapon" then
                        if self.upgradeManager:upgradeWeapon() then
                            self.game.coins = self.game.coins - price
                            for _, hero in ipairs(self.heroes) do
                                hero.weapon = require("weapons.weapon").new(self.upgradeManager.weaponLevel, hero.x, hero.y)
                            end
                        end

                    elseif btn.id == "hp" then
                        if self.upgradeManager:upgradeHP() then
                            self.game.coins = self.game.coins - price
                            for _, hero in ipairs(self.heroes) do
                                hero.hp = 50 + self.upgradeManager.hpLevel * 50
                            end
                        end

                    elseif btn.id == "hero" then
                        if self.upgradeManager:addHero() then
                            self.game.coins = self.game.coins - price
                            local nextIndex = #self.heroes + 1
                            if self.game.heroPositions and self.game.heroPositions[nextIndex] then
                                local pos = self.game.heroPositions[nextIndex]
                                local newHero = Hero:new(pos.x, pos.y, self.upgradeManager.weaponLevel, self.upgradeManager.hpLevel, heroWalls)
                                table.insert(self.heroes, newHero)
                            end
                        end
                    end

                    return
                end
            end
        end

        -- Start button
        local startBtnW = boxW - 160
        local startBtnH = 80
        local startBtnX = boxX + (boxW - startBtnW) / 2
        local startBtnY = boxY + boxH - startBtnH - 30
        if x >= startBtnX and x <= startBtnX + startBtnW and y >= startBtnY and y <= startBtnY + startBtnH then
            if self.game and self.game.state and self.game.state.switch then
                self.game.state:switch("game")
                
                if self.controlledHero then
                    self.controlledHero:startTeleport()
                    self.controlledHero = nil
                end
            end
            return
        end
    end

    -- If click wasn't on UI, check hero clicks (topmost hero first)
    for _, hero in ipairs(self.heroes) do
        local hb = hero:getHitbox()
        if x >= hb.x and x <= hb.x + hb.width and
           y >= hb.y and y <= hb.y + hb.height then

            -- switch control: deselect previous if different
            if self.controlledHero and self.controlledHero ~= hero then
                self.controlledHero:startReturn()
            end

            -- set this hero in control
            hero.inControl = true
            hero.returning = false
            self.controlledHero = hero
            return
        end
    end
end

function PrepareState:draw()
    map:draw()
    local w, h = love.graphics.getDimensions()

    -- Coins
    love.graphics.printf(
        "Coins: " .. self.game.coins,
        0, 20, w, "center"
    )

    for _, hero in ipairs(self.heroes) do
        -- draw small red upward-pointing triangle below the controlled hero
        if hero.inControl then
            local cx, cy = hero:getBodyCenter()
            local baseY = cy + 46
            local halfW = 8
            local height = 12
            local x1, y1 = cx - halfW, baseY
            local x2, y2 = cx + halfW, baseY
            local x3, y3 = cx, baseY - height

            love.graphics.setColor(0.9, 0.1, 0.1)
            love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3)
            love.graphics.setColor(1, 1, 1)
        end

        hero:draw()
    end

    -- Upgrade box
    self:drawUpgradeBox()
end

return PrepareState