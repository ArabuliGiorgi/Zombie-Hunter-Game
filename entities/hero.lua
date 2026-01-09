local Hero = {}
Hero.__index = Hero
local Weapon = require("weapons.weapon")

function Hero:new(x, y, weaponLevel, hpLevel, heroWalls)
    local self = setmetatable({}, Hero)
    self.x = x
    self.y = y

    -- store original spawn position so we can return here when deselected
    self.origX = x
    self.origY = y
    self.returning = false

    self.hp = 50+hpLevel*80
    self.speed = 250  -- Movement speed in pixels per second
    self.weapon = Weapon.new(weaponLevel, self.x, self.y)
    self.isDead = false
    self.inControl = false

    self.heroWalls = heroWalls

    self.state = "idle" -- "idle" or "walk"
    self.direction = 1 -- 1 = forward (right), -1 = backward (left)
    self.spriteOffsetX = 0

    -- Idle animation setup
    self.animation = {
        idle = {
            image = love.graphics.newImage("Sprites/man/Idle.png"),
            frames = 7,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1  -- Time per frame in seconds
        },
        walk = {
            image = love.graphics.newImage("Sprites/man/Walk.png"),
            frames = 10,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.08
        },
        dead = {
            image = love.graphics.newImage("Sprites/man/Dead.png"),
            frames = 5,
            currentFrame = 1,
            timer = 0,
            frameDuration = 0.1
        }
    }

    -- Calculate frame sizes
    for _, anim in pairs(self.animation) do
        anim.width  = anim.image:getWidth() / anim.frames
        anim.height = anim.image:getHeight()
    end

    -- Collision box (half height, positioned at bottom half)
    self.hitbox = {
        offsetX = 45,
        offsetY = 5,
        width = 30,
        height = 65
    }

    return self
end

function Hero:startReturn()
    -- begin smooth return to original position
    self.inControl = false
    self.returning = true
    self.state = "walk"
end

function Hero:startTeleport()
    -- teleport to original position
    self.inControl = false
    self.returning = false
    self.state = "idle"
    self.x = self.origX
    self.y = self.origY
end

function Hero:update(dt)
    if self.isDead then
        local anim = self.animation.dead
        anim.timer = anim.timer + dt

        if anim.timer >= anim.frameDuration then
            anim.timer = 0
            if anim.currentFrame < anim.frames then
                anim.currentFrame = anim.currentFrame + 1
            end
            -- stop on last frame (no looping)
        end

        return -- no movement, no shooting, no weapon update
    end

    local moving = false
    self.direction = 1

    local function checkCollision(rect1, rect2)
        return rect1.x < rect2.x + rect2.width and
               rect1.x + rect1.width > rect2.x and
               rect1.y < rect2.y + rect2.height and
               rect1.y + rect1.height > rect2.y
    end

    if self.returning then
        -- move towards original position smoothly
        local dx = self.origX - self.x
        local dy = self.origY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist <= 1 then
            -- reached
            self.x = self.origX
            self.y = self.origY
            self.returning = false
            self.state = "idle"
            self.direction = 1
            moving = false
        else
            local nx, ny = dx / dist, dy / dist
            local newX = self.x + nx * self.speed * dt
            local newY = self.y + ny * self.speed * dt

            -- X movement
            local testHitboxX = {
                x = newX + self.hitbox.offsetX,
                y = self.y + self.hitbox.offsetY,
                width = self.hitbox.width,
                height = self.hitbox.height
            }
            local canMoveX = true
            for _, wall in ipairs(self.heroWalls) do
                if checkCollision(testHitboxX, wall) then
                    canMoveX = false
                    break
                end
            end
            if canMoveX then self.x = newX end

            -- Y movement
            local testHitboxY = {
                x = self.x + self.hitbox.offsetX,
                y = newY + self.hitbox.offsetY,
                width = self.hitbox.width,
                height = self.hitbox.height
            }
            local canMoveY = true
            for _, wall in ipairs(self.heroWalls) do
                if checkCollision(testHitboxY, wall) then
                    canMoveY = false
                    break
                end
            end
            if canMoveY then self.y = newY end

            moving = true
            self.state = "walk"
            self.direction = (nx >= 0) and 1 or -1
        end

    else
        -- Player-controlled movement
        local mvx, mvy = 0, 0
        if self.inControl then
            if love.keyboard.isDown('w', 'up') then mvy = -1 end
            if love.keyboard.isDown('s', 'down') then mvy = 1 end
            if love.keyboard.isDown('a', 'left') then mvx = -1 end
            if love.keyboard.isDown('d', 'right') then mvx = 1 end
        end

        if mvx ~= 0 or mvy ~= 0 then
            local dir = math.atan2(mvy, mvx)
            local newX = self.x + math.cos(dir) * self.speed * dt
            local newY = self.y + math.sin(dir) * self.speed * dt

            -- X movement
            local testHitboxX = {
                x = newX + self.hitbox.offsetX,
                y = self.y + self.hitbox.offsetY,
                width = self.hitbox.width,
                height = self.hitbox.height
            }
            local canMoveX = true
            for _, wall in ipairs(self.heroWalls) do
                if checkCollision(testHitboxX, wall) then
                    canMoveX = false
                    break
                end
            end
            if canMoveX then self.x = newX end

            -- Y movement
            local testHitboxY = {
                x = self.x + self.hitbox.offsetX,
                y = newY + self.hitbox.offsetY,
                width = self.hitbox.width,
                height = self.hitbox.height
            }
            local canMoveY = true
            for _, wall in ipairs(self.heroWalls) do
                if checkCollision(testHitboxY, wall) then
                    canMoveY = false
                    break
                end
            end
            if canMoveY then self.y = newY end

            moving = true
            self.state = "walk"
            if mvx ~= 0 then self.direction = (mvx > 0) and 1 or -1 end
        end
    end

    self.state = moving and "walk" or "idle"

    -- Update current animation
    local anim = self.animation[self.state]
    anim.timer = anim.timer + dt

    if anim.timer >= anim.frameDuration then
        if self.state == "walk" and self.direction == -1 then
            -- Play backwards
            anim.currentFrame = anim.currentFrame - 1
            if anim.currentFrame < 1 then
                anim.currentFrame = anim.frames
            end
        else
            -- Normal forward play
            anim.currentFrame = (anim.currentFrame % anim.frames) + 1
        end

        anim.timer = 0
    end

    self.weapon:update(dt, self.x, self.y)
    if love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()
        self:shoot(mx, my)
    end
end

function Hero:getHitbox()
    return {
        x = self.x + self.hitbox.offsetX,
        y = self.y + self.hitbox.offsetY,
        width = self.hitbox.width,
        height = self.hitbox.height
    }
end

function Hero:takeDamage(amount)
    if self.isDead then return end

    self.hp = self.hp - amount
    if self.hp <= 0 then
        self.hp = 0
        self.isDead = true
        self.state = "dead"

        local anim = self.animation.dead
        anim.currentFrame = 1
        anim.timer = 0
    end
end

function Hero:getBodyCenter()
    return
        self.x + self.hitbox.offsetX + self.hitbox.width / 2,
        self.y + self.hitbox.offsetY + self.hitbox.height / 2
end

function Hero:draw()
    local anim = self.animation[self.state]
    if not anim then return end

    local quad = love.graphics.newQuad(
        (anim.currentFrame - 1) * anim.width,
        0,
        anim.width,
        anim.height,
        anim.image:getDimensions()
    )

    love.graphics.draw(anim.image, quad, self.x + self.spriteOffsetX, self.y)

    -- Draw weapon ONLY if alive
    if not self.isDead then
        self.weapon:draw()
    end

    -- Debug hitbox (optional)
    -- local hb = self:getHitbox()
    -- love.graphics.setColor(1, 0, 0, 0.5)
    -- love.graphics.rectangle("line", hb.x, hb.y, hb.width, hb.height)
    -- love.graphics.setColor(1, 1, 1, 1)
end

function Hero:shoot(mx, my)
    if self.isDead or not self.inControl then return end
    self.weapon:shoot(mx, my)
end

function Hero:autoShoot(mx, my)
    if self.isDead then return end
    -- bypass inControl check for AI shooting
    self.weapon:shoot(mx, my)
end

function Hero:BulletsCollision(zombie)
    return self.weapon:BulletsCollision(zombie)
end

return Hero