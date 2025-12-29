local Bullet = {}
Bullet.__index = Bullet

-- x, y       → start position
-- ex, ey     → target position
-- damage     → damage on hit
-- speed      → pixels per second
-- image      → sprite
-- maxDist    → max travel distance (default 1000)
function Bullet:new(x, y, ex, ey, damage, speed, image, maxDist, weaponType)
    local self = setmetatable({}, Bullet)

    self.x = x
    self.y = y
    self.hitX = x
    self.hitY = y
    self.startX = x
    self.startY = y

    self.damage = damage
    self.speed = speed
    self.image = image

    self.maxDist = maxDist or 1000
    self.isDead = false
    self.remove = false

    self.width = image:getWidth()
    self.height = image:getHeight()

    -- Audio
    self.shootSound = love.audio.newSource("Audio/bulletimpact.mp3", "static")
    self.shootSound:setVolume(0.6)

    -- Direction vector
    local dx = ex - x
    local dy = ey - y
    local length = math.sqrt(dx * dx + dy * dy)

    -- Avoid division by zero
    if length == 0 then length = 1 end

    self.dirX = dx / length
    self.dirY = dy / length
    self.rotation = math.atan2(self.dirY, self.dirX)

    self.scale = 0.7
    if weaponType == "AKM" or weaponType == "Uzi" then
        self.scale = 0.8
    end

    -- 🔥 HIT EFFECT
    self.hit = {
        image = love.graphics.newImage("Sprites/Weapon/FIRE/HitEffect.png"),
        frames = 6,
        currentFrame = 1,
        timer = 0,
        frameDuration = 0.04,
        active = false
    }

    self.hit.frameWidth  = self.hit.image:getWidth() / self.hit.frames
    self.hit.frameHeight = self.hit.image:getHeight()

    return self
end

function Bullet:update(dt)
    -- BULLET MOVEMENT
    if not self.isDead then
        self.x = self.x + self.dirX * self.speed * dt
        self.y = self.y + self.dirY * self.speed * dt

        local dx = self.x - self.startX
        local dy = self.y - self.startY
        local traveled = math.sqrt(dx * dx + dy * dy)

        if traveled >= self.maxDist then
            self:die()
        end
    end

    -- HIT EFFECT UPDATE
    if self.hit.active then
        self.hit.timer = self.hit.timer + dt

        if self.hit.timer >= self.hit.frameDuration then
            self.hit.timer = 0
            self.hit.currentFrame = self.hit.currentFrame + 1

            if self.hit.currentFrame > self.hit.frames then
                self.hit.active = false
                self.remove = true -- ✅ safe to delete bullet
            end
        end
    end
end

function Bullet:die()
    if self.isDead then return end

    self.isDead = true

    -- Play gunshot sound (clone to allow overlap)
    local sound = self.shootSound:clone()
    sound:play()

    -- Freeze hit position
    self.hitX = self.x
    self.hitY = self.y

    self.hit.active = true
    self.hit.currentFrame = 1
    self.hit.timer = 0
end

function Bullet:draw()
    -- 🔥 ONLY hit effect after death
    if self.hit.active then
        local quad = love.graphics.newQuad(
            (self.hit.currentFrame - 1) * self.hit.frameWidth,
            0,
            self.hit.frameWidth,
            self.hit.frameHeight,
            self.hit.image:getDimensions()
        )

        love.graphics.draw(
            self.hit.image,
            quad,
            self.hitX,
            self.hitY,
            0,
            0.5,
            0.5,
            self.hit.frameWidth / 2,
            self.hit.frameHeight / 2
        )

        return
    end

    -- draw bullet ONLY if alive
    if not self.isDead then
        love.graphics.draw(
            self.image,
            self.x,
            self.y,
            self.rotation,
            self.scale,
            self.scale,
            self.width / 2,
            self.height / 2
        )
    end
end

function Bullet:checkCollision(zombie)
    if self.isDead or zombie.isDead then return end

    local hb = zombie:getHitbox()

    if self.x < hb.x + hb.width + 10 and
       hb.x < self.x + self.width - 10 and
       self.y < hb.y + hb.height and
       hb.y < self.y + self.height then

        zombie:takeDamage(self.damage)
        self:die()
        return true
    end
end

return Bullet