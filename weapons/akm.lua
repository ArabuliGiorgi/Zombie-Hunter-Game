local AKM = {}
AKM.__index = AKM
local Bullet = require("weapons.bullet")

function AKM.new(x, y, fireRate, damage)
    local self = setmetatable({}, AKM)
    self.x = x
    self.y = y
    self.fireRate = fireRate - 0.1
    self.damage = damage*0.4
    self.cooldown = 0
    self.bullets = {}

    self.image = love.graphics.newImage('Sprites/Weapon/AKM/AKM.png')
    self.bulletImage = love.graphics.newImage('Sprites/Weapon/AKM/7,62mm.png')
    self.state = "idle" -- "idle" or "shoot"

    -- Audio
    self.shootSound = love.audio.newSource("Audio/akm.mp3", "static")
    self.shootSound:setVolume(0.6)

    self.animation = {
        frames = 8,
        currentFrame = 1,
        timer = 0,
        frameDuration = 0.05  -- Time per frame in seconds
    }

    self.frameWidth  = self.image:getWidth() / self.animation.frames
    self.frameHeight = self.image:getHeight()

    self.muzzle = {
        image = love.graphics.newImage("Sprites/Weapon/FIRE/FireMuzzle.png"),
        frames = 8,
        currentFrame = 1,
        timer = 0,
        frameDuration = 0.04,
        active = false
    }

    self.muzzle.frameWidth  = self.muzzle.image:getWidth() / self.muzzle.frames
    self.muzzle.frameHeight = self.muzzle.image:getHeight()

    return self
end

function AKM:update(dt, x, y)
    -- Fire rate cooldown
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end

    if self.state == "shoot" then
        self.animation.timer = self.animation.timer + dt

        if self.animation.timer >= self.animation.frameDuration then
            self.animation.currentFrame = self.animation.currentFrame + 1
            self.animation.timer = 0

            -- End shooting animation (frame 8)
            if self.animation.currentFrame > 8 then
                self.animation.currentFrame = 1
                self.state = "idle"
            end
        end
    else
        -- Idle always stays on frame 1
        self.animation.currentFrame = 1
    end

    -- 🔥 Update muzzle flash
    if self.muzzle.active then
        self.muzzle.timer = self.muzzle.timer + dt

        if self.muzzle.timer >= self.muzzle.frameDuration then
            self.muzzle.timer = 0
            self.muzzle.currentFrame = self.muzzle.currentFrame + 1

            if self.muzzle.currentFrame > self.muzzle.frames then
                self.muzzle.active = false
                self.muzzle.currentFrame = 1
            end
        end
    end

    self.x = x
    self.y = y

    -- Update bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)

        if b.remove then
            table.remove(self.bullets, i)
        end
    end
end

function AKM:shoot(targetX, targetY)
    if self.cooldown <= 0 then
        self.state = "shoot"
        self.animation.currentFrame = 2
        self.animation.timer = 0
        self.cooldown = self.fireRate

        -- Activate muzzle flash
        self.muzzle.active = true
        self.muzzle.currentFrame = 1
        self.muzzle.timer = 0

        -- 🔫 Spawn bullet here
        local bullet = Bullet:new(
            self.x + 50,
            self.y + 10,
            targetX,
            targetY,
            self.damage,
            1000,
            self.bulletImage,
            1000,
            "AKM"
        )

        -- Play gunshot sound (clone to allow overlap)
        local sound = self.shootSound:clone()
        sound:play()

        table.insert(self.bullets, bullet)
    end
end

function AKM:draw()
    local frame = self.animation.currentFrame

    local quad = love.graphics.newQuad(
        (frame - 1) * self.frameWidth,
        0,
        self.frameWidth,
        self.frameHeight,
        self.image:getDimensions()
    )

    for _, b in ipairs(self.bullets) do
        b:draw()
    end

    love.graphics.draw(self.image, quad, self.x, self.y, 0, 0.8, 0.8)
    
    -- 🔥 Draw muzzle flash
    if self.muzzle.active then
        local frame = self.muzzle.currentFrame

        local quad = love.graphics.newQuad(
            (frame - 1) * self.muzzle.frameWidth,
            0,
            self.muzzle.frameWidth,
            self.muzzle.frameHeight,
            self.muzzle.image:getDimensions()
        )

        -- Adjust offsets to fit muzzle position
        love.graphics.draw(
            self.muzzle.image,
            quad,
            self.x + 47, 
            self.y + 7, 
            0,
            0.9,
            0.9
        )
    end
end

function AKM:BulletsCollision(zombie)
    for _, b in ipairs(self.bullets) do
        if b:checkCollision(zombie) then
            return b.damage
        end
    end
end

return AKM