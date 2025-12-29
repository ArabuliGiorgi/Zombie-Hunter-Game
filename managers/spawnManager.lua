local SpawnManager = {}
SpawnManager.__index = SpawnManager

function SpawnManager:new(waveManager)
    local self = setmetatable({}, SpawnManager)

    self.waveManager = waveManager
    self.timer = 0
    self.spawnDelay = 1.2
    self.spawnCallback = nil

    return self
end

function SpawnManager:update(dt)
    if not self.waveManager or not self.waveManager:isActive() then return end
    if not self.waveManager:hasPending() then return end

    self.timer = self.timer + dt
    if self.timer < self.spawnDelay then return end
    self.timer = self.timer - self.spawnDelay

    local t = self.waveManager:popNext()
    if not t then return end
    if self.spawnCallback then
        -- spawn at right edge with random Y
        local sw = love.graphics.getWidth()
        local sh = love.graphics.getHeight()
        local x = sw + math.random(200, 400)
        local y = math.random(200, sh - 200)
        self.spawnCallback(t, x, y)
    end
end

function SpawnManager:onSpawn(cb)
    self.spawnCallback = cb
end

function SpawnManager:hasPending()
    if not self.waveManager then return false end
    return self.waveManager:hasPending()
end

return SpawnManager