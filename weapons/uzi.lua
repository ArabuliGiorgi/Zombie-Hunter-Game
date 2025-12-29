local Uzi = {}
Uzi.__index = Uzi
local Bullet = require("weapons.bullet")
local Pistol = require("weapons.pistol")

function Uzi.new(x, y, fireRate, damage)
    local self = setmetatable(Pistol:new(x, y, fireRate, damage), Uzi)
    self.x = x
    self.y = y 
    self.fireRate = fireRate - 0.1
    self.damage = damage*0.7
    self.cooldown = 0
    self.bullets = {}

    self.image = love.graphics.newImage('Sprites/Weapon/MAC10/Mac10.png')
    self.bulletImage = love.graphics.newImage('Sprites/Weapon/MAC10/.45 acp.png')
    self.state = "idle" -- "idle" or "shoot"

    -- Audio
    self.shootSound = love.audio.newSource("Audio/uzi.mp3", "static")
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

function Uzi:update(dt, x, y)
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

function Uzi:shoot(targetX, targetY)
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
            self.x + 25,
            self.y + 8,
            targetX,
            targetY,
            self.damage,
            700,
            self.bulletImage,
            900,
            "Uzi"
        )

        -- Play gunshot sound (clone to allow overlap)
        local sound = self.shootSound:clone()
        sound:play()

        table.insert(self.bullets, bullet)
    end
end

function Uzi:draw()
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
            self.x + 23, 
            self.y + 4,
            0,
            0.8,
            0.8
        )
    end
end

function Uzi:BulletsCollision(zombie)
    for _, b in ipairs(self.bullets) do
        if b:checkCollision(zombie) then
            return b.damage
        end
    end
end

return Uzi