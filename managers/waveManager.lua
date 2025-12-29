local WaveManager = {}
WaveManager.__index = WaveManager

function WaveManager:new()
    local self = setmetatable({}, WaveManager)

    self.waves = {10,20,30,35,40}
    self.currentWave = 0
    self.spawnQueue = {}
    self.active = false

    return self
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function WaveManager:startNextWave()
    self.currentWave = self.currentWave + 1
    if self.currentWave > #self.waves then
        self.spawnQueue = {}
        self.active = false
        return false
    end

    local total = self.waves[self.currentWave]
    local q = {}

    if self.currentWave == 1 then
        for i=1,total do q[#q+1] = 1 end
    elseif self.currentWave == 2 then
        local need2 = 5
        local n1 = total - need2
        for i=1,n1 do q[#q+1] = 1 end
        for i=1,need2 do q[#q+1] = 2 end
    elseif self.currentWave == 3 then
        local half = math.floor(total/2)
        for i=1,half do q[#q+1] = 1 end
        for i=1,half do q[#q+1] = 2 end
        if #q < total then q[#q+1] = 1 end
    elseif self.currentWave == 4 then
        local need3 = 5
        local rem = total - need3
        local half = math.floor(rem/2)
        for i=1,half do q[#q+1] = 1 end
        for i=1,half do q[#q+1] = 2 end
        for i=1,need3 do q[#q+1] = 3 end
        while #q < total do q[#q+1] = 1 end
    elseif self.currentWave == 5 then
        for i=1,total do q[#q+1] = math.random(1,3) end
    end

    shuffle(q)
    self.spawnQueue = q
    self.active = true
    return true
end

function WaveManager:hasPending()
    return #self.spawnQueue > 0
end

function WaveManager:pendingCount()
    return #self.spawnQueue
end

function WaveManager:popNext()
    return table.remove(self.spawnQueue)
end

function WaveManager:isActive()
    return self.active
end

function WaveManager:finishWave()
    self.active = false
end

return WaveManager