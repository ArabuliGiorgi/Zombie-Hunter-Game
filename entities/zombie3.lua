local Zombie3 = {}
Zombie3.__index = Zombie3
local Zombie1 = require("entities.zombie1")

function Zombie3:new(x, y, level, walls)
    local self = setmetatable(Zombie1:new(x, y, level, walls), Zombie3)

    self.groanSound = love.audio.newSource("Audio/zombie3.mp3", "static")

    self.animation = {
        idle = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie3/idle.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.2
        },
        walk = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie3/walk.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.15
        },
        attack = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie3/attack.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        },
        run = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie3/run.png"),
            frames = 7,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.08
        },
        hurt = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie3/hurt.png"),
            frames = 5,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        },
        die = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie3/dead.png"),
            frames = 8,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        }
    }
    self.spriteOffsets.walk = -20
    
    return self
end

function Zombie3:update(dt, targetX, targetY, target)
    Zombie1.update(self, dt, targetX, targetY, target)
end

function Zombie3:startAttack()
    Zombie1.startAttack(self)
end

function Zombie3:takeDamage(amount)
    Zombie1.takeDamage(self, amount)
end

function Zombie3:getAttackDamage()
    return Zombie1.getAttackDamage(self)
end

function Zombie3:getHitbox()
    return Zombie1.getHitbox(self)
end

function Zombie3:setState(newState)
    Zombie1.setState(self, newState)
end

function Zombie3:updateAnimation(dt, anim, loop)
    return Zombie1.updateAnimation(self, dt, anim, loop)
end

function Zombie3:getBodyCenter()
    return Zombie1.getBodyCenter(self)
end

function Zombie3:draw()
    Zombie1.draw(self)
end

return Zombie3