local Zombie1 = {}
Zombie1.__index = Zombie1

function Zombie1:new(x, y, level)
    local self = setmetatable({}, Zombie1)
    self.scale = 0.38
    self.x = x
    self.y = y
    self.maxHp = 50 + (level * 40)
    self.hp = self.maxHp
    self.speed = 50 + (level * 10)
    self.damage = 5 + level

    self.retreatX = 1500
    self.retreatSpeed = self.speed * 0.5

    -- self.walls = walls

    self.attackRange = 20
    self.isAttacking = false
    self.didDamage = false

    self.state = "idle" -- "idle" or "walk" or "run" or "attack" or "hurt"
    self.isDead = false
    self.remove = false

    -- AUDIO
    self.groanSound = love.audio.newSource("Audio/zombie1.mp3", "static")
    self.groanSound:setVolume(0.5)

    self.hurtSound = love.audio.newSource("Audio/zombiehurt.mp3", "static")
    self.hurtSound:setVolume(0.6)

    self.groanTimer = 0
    self.nextGroanTime = love.math.random(1, 15)

    self.isRetreating = false

    self.alpha = 1
    self.fadeSpeed = 1 -- seconds to fully fade
    self.deathAnimFinished = false

    self.hurtTriggered = false

    self.direction = -1 -- 1:right, -1:left
    self.spriteOffsets = {
        idle = -25,
        walk = -25,
        run = -25,
        dead = -65,
        hurt = -30
    }
    self.spriteOffsetX = self.spriteOffsets.idle
    self.animation = {
        idle = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie1/idle.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.2
        },
        walk = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie1/walk.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.15
        },
        attack = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie1/attack.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        },
        run = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie1/run.png"),
            frames = 6,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.08
        },
        hurt = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie1/hurt.png"),
            frames = 5,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        },
        die = {
            image = love.graphics.newImage("Sprites/Zombie/Zombie1/dead.png"),
            frames = 8,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        }
    }

    self.hitbox = {
        offsetX = -15,
        offsetY = 5,
        width = 30,
        height = 60
    }

    return self
end

function Zombie1:update(dt, targetX, targetY, target)
    -- ======================
    -- Death
    -- ======================
    if self.isDead then
        if not self.deathAnimFinished then
            local finished = self:updateAnimation(dt, self.animation.die, false)
            if finished then
                self.deathAnimFinished = true
            end
        else
            -- fade out AFTER death animation
            self.alpha = self.alpha - dt / self.fadeSpeed
            if self.alpha <= 0 then
                self.alpha = 0
                self.remove = true
            end
        end
        return
    end

    if target and target.isDead then
        self:setState("idle")
        self.isRetreating = false
        self:updateAnimation(dt, self.animation.idle, true)
        return
    end

    if self.hp <= 0 then
        self.state = "die"
        self.isDead = true
        self.spriteOffsetX = self.spriteOffsets.dead
        self.animation.die.currentFrame = 1
        self.animation.die.timer = 0
        return
    end

    -- ======================
    -- RANDOM ZOMBIE GROANS
    -- ======================
    if not self.isDead then
        self.groanTimer = self.groanTimer + dt

        if self.groanTimer >= self.nextGroanTime then
            local sound = self.groanSound:clone()
            sound:setPitch(0.9 + math.random() * 0.2)
            sound:play()

            self.groanTimer = 0
            self.nextGroanTime = love.math.random(1, 15)
        end
    end

    -- ======================
    -- Distance calculation (FIRST!)
    -- ======================
    local zx, zy = self:getBodyCenter()
    local dx = targetX - zx
    local dy = targetY - zy
    local dist = math.sqrt(dx*dx + dy*dy)

    self.direction = dx >= 0 and 1 or -1

    -- ======================
    -- ATTACK STATE (LOCKED)
    -- ======================
    if self.state == "attack" then
        local finished = self:updateAnimation(dt, self.animation.attack, false)

        -- deal damage once (mid animation)
        if not self.didDamage and self.animation.attack.currentFrame >= 3 then
            if self.onAttackHit then
                self.onAttackHit()
            end
            self.didDamage = true
        end

        if finished then
            self.didDamage = false

            if target and target.isDead then
                self:setState("idle")
            elseif dist <= self.attackRange then
                self:startAttack()
            else
                self:setState(self.speed >= 100 and "run" or "walk")
            end
        end

        return -- NO movement while attacking
    end

    -- ======================
    -- HURT STATE
    -- ======================
    if not self.hurtTriggered and self.hp <= self.maxHp * 0.3 then
        self:setState("hurt")
        self.hurtTriggered = true

        -- Play hurt sound ONCE
        local sound = self.hurtSound:clone()
        sound:setPitch(0.95 + math.random() * 0.1)
        sound:play()
        return
    end

    if self.state == "hurt" then
        if self:updateAnimation(dt, self.animation.hurt, false) then
            self.isRetreating = true
            self:setState(self.retreatSpeed >= 100 and "run" or "walk")
        end
        return
    end

    -- ======================
    -- RETREAT AI
    -- ======================
    if self.isRetreating then
        local newX = self.x + self.retreatSpeed * dt

        local newHitbox = {
            x = newX + self.hitbox.offsetX,
            y = self.y + self.hitbox.offsetY,
            width = self.hitbox.width,
            height = self.hitbox.height
        }

        local canMove = true
        local function checkCollision(rect1, rect2)
            return rect1.x < rect2.x + rect2.width and
                   rect1.x + rect1.width > rect2.x and
                   rect1.y < rect2.y + rect2.height and
                   rect1.y + rect1.height > rect2.y
        end

        -- for _, wall in ipairs(self.walls) do
        --     if checkCollision(newHitbox, wall) then
        --         canMove = false
        --         break
        --     end
        -- end

        if canMove then
            self.direction = 1 -- force right
            self.x = newX

            self:updateAnimation(dt, self.animation[self.state], true)
        end

        if self.x >= self.retreatX then
            -- Force death outside screen
            self.hp = 0
            self.isRetreating = false
            self.state = "die"
            self.isDead = true
            self.spriteOffsetX = self.spriteOffsets.dead
            self.animation.die.currentFrame = 1
            self.animation.die.timer = 0
        end

        return
    end

    -- ======================
    -- START ATTACK
    -- ======================
    if dist <= self.attackRange then
        self:startAttack()
        return
    end

    -- ======================
    -- MOVEMENT
    -- ======================
    if dist > 1 then
        local nx = dx / dist
        local ny = dy / dist

        local newX = self.x + nx * self.speed * dt
        local newY = self.y + ny * self.speed * dt

        -- Try X movement
        local testHitboxX = {
            x = newX + self.hitbox.offsetX,
            y = self.y + self.hitbox.offsetY,
            width = self.hitbox.width,
            height = self.hitbox.height
        }
        local canMoveX = true
        local function checkCollision(rect1, rect2)
            return rect1.x < rect2.x + rect2.width and
                   rect1.x + rect1.width > rect2.x and
                   rect1.y < rect2.y + rect2.height and
                   rect1.y + rect1.height > rect2.y
        end
        -- for _, wall in ipairs(self.walls) do
        --     if checkCollision(testHitboxX, wall) then
        --         canMoveX = false
        --         break
        --     end
        -- end
        if canMoveX then
            self.x = newX
        end

        -- Try Y movement
        local testHitboxY = {
            x = self.x + self.hitbox.offsetX,
            y = newY + self.hitbox.offsetY,
            width = self.hitbox.width,
            height = self.hitbox.height
        }
        local canMoveY = true
        -- for _, wall in ipairs(self.walls) do
        --     if checkCollision(testHitboxY, wall) then
        --         canMoveY = false
        --         break
        --     end
        -- end
        if canMoveY then
            self.y = newY
        end

        self.isRetreating = false
        self:setState(self.speed >= 120 and "run" or "walk")
    else
        self:setState("idle")
    end

    self:updateAnimation(dt, self.animation[self.state], true)
end

function Zombie1:setState(newState)
    if self.state ~= newState then
        self.state = newState
        local anim = self.animation[newState]
        if anim then
            anim.currentFrame = 1
            anim.timer = 0
        end
        -- Update sprite offset for the new state
        if self.spriteOffsets[newState] then
            self.spriteOffsetX = self.spriteOffsets[newState]
        end
    end
end

function Zombie1:updateAnimation(dt, anim, loop)
    anim.timer = anim.timer + dt

    if anim.timer >= anim.frameDuration then
        anim.timer = 0
        anim.currentFrame = anim.currentFrame + 1

        if anim.currentFrame > anim.frames then
            if loop then
                anim.currentFrame = 1
            else
                anim.currentFrame = anim.frames
                return true -- finished
            end
        end
    end

    return false
end

function Zombie1:startAttack()
    self.state = "attack"
    self.isRetreating = false
    self.animation.attack.currentFrame = 1
    self.animation.attack.timer = 0
    self.didDamage = false
end

function Zombie1:takeDamage(amount)
    if self.isDead then return end

    self.hp = self.hp - amount
    if self.hp < 0 then
        self.hp = 0
    end
end

function Zombie1:getAttackDamage()
    return self.damage
end

function Zombie1:getHitbox()
    return {
        x = self.x + self.hitbox.offsetX,
        y = self.y + self.hitbox.offsetY,
        width = self.hitbox.width,
        height = self.hitbox.height
    }
end

function Zombie1:getBodyCenter()
    return
        self.x + self.hitbox.offsetX + self.hitbox.width / 2,
        self.y + self.hitbox.offsetY + self.hitbox.height / 2
end

function Zombie1:draw()
    local anim = self.animation[self.state]
    if not anim then return end

    local frameWidth = anim.image:getWidth() / anim.frames
    local frameHeight = anim.image:getHeight()

    local quad = love.graphics.newQuad(
        (anim.currentFrame - 1) * frameWidth,
        0,
        frameWidth,
        frameHeight,
        anim.image:getDimensions()
    )

    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.draw(
        anim.image,
        quad,
        self.x + self.spriteOffsetX * self.direction,
        self.y,
        0,
        self.direction * self.scale,
        self.scale
    )
    love.graphics.setColor(1, 1, 1, 1)

    -- local hb = self:getHitbox()
    -- love.graphics.setColor(1, 0, 0, 0.5)
    -- love.graphics.rectangle("line", hb.x, hb.y, hb.width, hb.height)
    -- love.graphics.setColor(1, 1, 1, 1)
end

return Zombie1