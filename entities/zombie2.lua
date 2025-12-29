local Zombie2 = {}
Zombie2.__index = Zombie2
local Zombie1 = require("entities.zombie1")

function Zombie2:new(x, y, level, walls)
    local self = setmetatable(Zombie1:new(x, y, level, walls), Zombie2)

    self.groanSound = love.audio.newSource("Audio/zombie2.mp3", "static")

    self.animation = {
        idle = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie2/idle.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.2
        },
        walk = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie2/walk.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.15
        },
        attack = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie2/attack.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        },
        run = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie2/run.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.08
        },
        hurt = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie2/hurt.png"),
            frames = 5,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        },
        die = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie2/dead.png"),
            frames = 8,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        }
    }
    self.spriteOffsets.walk = -17

    return self
end

function Zombie2:update(dt, targetX, targetY, target)
    Zombie1.update(self, dt, targetX, targetY, target)
end

function Zombie2:startAttack()
    Zombie1.startAttack(self)
end

function Zombie2:takeDamage(amount)
    Zombie1.takeDamage(self, amount)
end

function Zombie2:getAttackDamage()
    return Zombie1.getAttackDamage(self)
end

function Zombie2:getHitbox()
    return Zombie1.getHitbox(self)
end

function Zombie2:setState(newState)
    Zombie1.setState(self, newState)
end

function Zombie2:updateAnimation(dt, anim, loop)
    return Zombie1.updateAnimation(self, dt, anim, loop)
end

function Zombie2:getBodyCenter()
    return Zombie1.getBodyCenter(self)
end

function Zombie2:draw()
    Zombie1.draw(self)
end

return Zombie2