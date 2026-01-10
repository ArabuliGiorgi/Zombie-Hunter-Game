local sti = require("Libraries/sti")
local Game = {}
Game.__index = Game

local Zombie1 = require("entities.zombie1")
local Zombie2 = require("entities.zombie2")
local Zombie3 = require("entities.zombie3")
local Hero = require("entities.hero")
local WaveManager = require("managers.waveManager")
local SpawnManager = require("managers.spawnManager")
local Audio = require("audio")

function Game:new(game)
    local self = setmetatable({}, Game)
    self.game = game

    -- map + collision
    self.map = sti("Maps/MH_map.lua")
    self.heroWalls = {}
    for _, obj in pairs(self.map.layers["ForCharacter"].objects) do
        table.insert(self.heroWalls, { x = obj.x, y = obj.y, width = obj.width, height = obj.height })
    end

    -- load health bar image
    self.healthBarImage = love.graphics.newImage("Images/healthbar.png")

    -- heroes (copy from upgrade state settings)
    self.heroes = {}
    for i = 1, self.game.upgradeManager.heroAmount do
        local pos = self.game.heroPositions[i]
        if pos then
            table.insert(self.heroes, Hero:new(pos.x, pos.y, self.game.upgradeManager.weaponLevel, self.game.upgradeManager.hpLevel, self.heroWalls))
        end
    end

    -- wave configuration
    self.waves = nil
    self.currentWave = 0
    self.zombies = {}

    -- end sequence state
    self.endTimer = nil
    self.endType = nil -- 'defeat' or 'victory'

    -- managers
    self.waveManager = WaveManager:new()
    self.spawnManager = SpawnManager:new(self.waveManager)
    self.spawnManager.spawnDelay = 0.6
    self.spawnCallback = function(t,x,y)
        local z
        if t == 1 then z = Zombie1:new(x, y, self.currentWave*2) end
        if t == 2 then z = Zombie2:new(x, y, self.currentWave*3) end
        if t == 3 then z = Zombie3:new(x, y, self.currentWave*3 + 3) end
        if z then table.insert(self.zombies, z) end
    end

    self.spawnManager:onSpawn(self.spawnCallback)

    return self
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function Game:enter()
    Audio.stopMusic()
    if self.game.music then
        Audio.playMusic("Audio/gametheme.mp3", 0.8)
    end

    if self.game.reset then
        -- Reset managers and state for fresh start
        self.waveManager = WaveManager:new()
        self.spawnManager = SpawnManager:new(self.waveManager)
        self.spawnManager.spawnDelay = 0.6
        self.spawnManager:onSpawn(self.spawnCallback)

        self.currentWave = 0
        self.game.reset = false
    end

    self.zombies = {}
    self.endTimer = nil
    self.endType = nil

    -- start next wave via manager
    local started = self.waveManager:startNextWave()
    if not started then
        self.game.state:switch("prepare")
        return
    end

    self.currentWave = self.waveManager.currentWave
    self.game.waveNumber = self.currentWave

    -- recreate heroes to reflect current upgrade levels and positions
    self.heroes = {}
    for i = 1, self.game.upgradeManager.heroAmount do
        local pos = self.game.heroPositions[i]
        if pos then
            table.insert(self.heroes, Hero:new(pos.x, pos.y, self.game.upgradeManager.weaponLevel, self.game.upgradeManager.hpLevel, self.heroWalls))
        end
    end
    self.controlledHero = nil

    -- clear zombies
    self.zombies = {}
end

function Game:mousepressed(x, y, button)
    if button ~= 1 then return end

    for _, hero in ipairs(self.heroes) do
        local hb = hero:getHitbox()
        if x >= hb.x and x <= hb.x + hb.width and
           y >= hb.y and y <= hb.y + hb.height then

            if self.controlledHero and self.controlledHero ~= hero then
                self.controlledHero:startReturn()
            end

            hero.inControl = true
            hero.returning = false
            self.controlledHero = hero
            return
        end
    end
end

function Game:keypressed(key)
    if key == "escape" then
        if self.controlledHero then
            self.controlledHero:startReturn()
            self.controlledHero = nil
        end
    end
end

function Game:update(dt)
    self.map:update(dt)
    -- update spawn manager (spawns zombies via callback)
    self.spawnManager:update(dt)

    -- update heroes
    for _, hero in ipairs(self.heroes) do
        hero:update(dt)
    end

    -- if the currently controlled hero died while in control, release control immediately
    if self.controlledHero and self.controlledHero.isDead then
        self.controlledHero.inControl = false
        self.controlledHero = nil
    end

    -- auto-shoot for non-controlled alive heroes
    for _, hero in ipairs(self.heroes) do
        if not hero.isDead and not hero.inControl then
            -- find nearest zombie
            local bestZ, bestDist, zx, zy = nil, nil, 0, 0
            for _, z in ipairs(self.zombies) do
                if not z.isDead then
                    local zcx, zcy = z:getBodyCenter()
                    local dx = zcx - hero.x
                    local dy = zcy - hero.y
                    local d2 = dx*dx + dy*dy
                    if not bestDist or d2 < bestDist then
                        bestDist = d2
                        bestZ = z
                        zx, zy = zcx, zcy
                    end
                end
            end
            if bestZ and bestDist and bestDist <= (700*700) then
                hero:autoShoot(zx, zy)
            end
        end
    end

    -- if all heroes dead -> start defeat end-sequence (5s fade -> Defeat)
    local aliveHeroes = {}
    for _, h in ipairs(self.heroes) do
        if not h.isDead then table.insert(aliveHeroes, h) end
    end
    if #aliveHeroes == 0 then
        if not self.endTimer then
            self.endTimer = 0
            self.endType = "defeat"
            -- stop further spawns
            self.waveManager:finishWave()
        end
        -- continue updating (allow animations) but don't progress game
    end

    -- if an end sequence is active, advance it and switch when elapsed (3s)
    if self.endTimer then
        self.endTimer = self.endTimer + dt
        if self.endTimer >= 3 then
            if self.endType == "defeat" then
                self.game.state:switch("defeat")
                self.game.reset = true
                return
            elseif self.endType == "victory" then
                self.game.state:switch("victory")
                self.game.reset = true
                return
            end
        end
    end

    -- update zombies; target nearest alive hero
    local aliveCount = #aliveHeroes
    for i = #self.zombies, 1, -1 do
        local z = self.zombies[i]

        -- find nearest hero
        local zx, zy = z:getBodyCenter()
        if aliveCount == 0 then
            -- no heroes alive: call zombie update with a fake dead target so
            -- the zombie's internal logic switches to idle cleanly
            local fakeDead = { isDead = true }
            z:update(dt, zx, zy, fakeDead)
            if z.remove then
                local awarded = true
                if z.retreatX and z.x and z.x >= (z.retreatX - 1) then
                    awarded = false
                end
                if awarded then
                    self.game.coins = (self.game.coins or 0) + math.floor((z.maxHp or 10)/5)
                end
                table.remove(self.zombies, i)
            else
                for _, hero in ipairs(self.heroes) do
                    if hero:BulletsCollision(z) then end
                end
            end
        else
            local bestHero, bestDist, bestX, bestY = nil, nil, 0, 0
            for _, h in ipairs(aliveHeroes) do
                local hx, hy = h:getBodyCenter()
                local dx = hx - zx
                local dy = hy - zy
                local d2 = dx*dx + dy*dy
                if not bestDist or d2 < bestDist then
                    bestDist = d2
                    bestHero = h
                    bestX = hx
                    bestY = hy
                end
            end

            if bestHero then
                local targetHero = bestHero
                local tx, ty = bestX, bestY
                if z.state ~= "attack" then
                    z.onAttackHit = function()
                        if targetHero and not targetHero.isDead then
                            targetHero:takeDamage(z:getAttackDamage())
                        end
                    end
                end
                z:update(dt, tx, ty, targetHero)
            else
                z:update(dt, -1000, z.y, nil)
            end

            if z.remove then
                -- award coins when fully removed unless the zombie retreated off-screen
                local awarded = true
                if z.retreatX and z.x and z.x >= (z.retreatX - 1) then
                    awarded = false
                end
                if awarded then
                    self.game.coins = (self.game.coins or 0) + math.floor((z.maxHp or 10)/5)
                end
                table.remove(self.zombies, i)
            else
                -- check collisions with bullets from heroes
                for _, hero in ipairs(self.heroes) do
                    if hero:BulletsCollision(z) then
                        -- assumed handled inside, no-op
                    end
                end
            end
        end
    end

    -- wave end: if no pending spawns and no zombies, finish
    if not self.waveManager:hasPending() and #self.zombies == 0 then
        -- if final wave completed, start victory end-sequence
        if self.currentWave == 5 then
            if not self.endTimer then
                self.endTimer = 0
                self.endType = "victory"
                self.waveManager:finishWave()
            end
        else
            self.waveManager:finishWave()
            self.game.state:switch("prepare")
            return
        end
    end
end

function Game:draw()
    self.map:draw()

    -- draw heroes and zombies
    for _, hero in ipairs(self.heroes) do
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
    for _, z in ipairs(self.zombies) do z:draw() end

    -- HUD
    love.graphics.setColor(1,1,0)
    love.graphics.print("Coins: " .. tostring(self.game.coins), 10, 10)
    love.graphics.print("Wave: " .. tostring(self.currentWave), 10, 30)
    love.graphics.print("Zombies: " .. tostring(#self.zombies + self.waveManager:pendingCount()), 10, 50)
    love.graphics.setColor(1,1,1)

    -- draw health bars for alive heroes
    local screenW, screenH = love.graphics.getDimensions()
    for i, hero in ipairs(self.heroes) do
        if not hero.isDead then
            local barX = 10
            local barY = screenH - 60 - (i-1)*40
            local rectX = barX + 28
            local rectY = barY + 5
            local barWidth = 180
            local barHeight = 35
            local maxHp = 50 + self.game.upgradeManager.hpLevel * 80
            local healthPercent = hero.hp / maxHp
            local rectWidth = barWidth * healthPercent * 0.822
            local rectHeight = barHeight - 10

            -- draw red health rectangle behind
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", rectX, rectY, rectWidth, rectHeight)
            love.graphics.setColor(1, 1, 1)

            -- draw health bar png on top
            local scaleX = barWidth / 1643
            local scaleY = barHeight / 340
            love.graphics.draw(self.healthBarImage, barX, barY, 0, scaleX, scaleY)
        end
    end

    -- draw fade overlay when ending
    if self.endTimer then
        local w, h = love.graphics.getDimensions()
        local alpha = math.min(1, self.endTimer / 3)
        love.graphics.setColor(0,0,0, alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1,1,1)
    end
end

return Game
