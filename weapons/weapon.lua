local Weapon = {}
Weapon.__index = Weapon

local Pistol = require("weapons.pistol")
local Uzi = require("weapons.uzi")
local AKM = require("weapons.akm")

function Weapon.new(level, x, y)
    local self = setmetatable({}, Weapon)
    self.x = x
    self.y = y
    -- up to level 15
    self.damage = level*10
    self.fireRate = 0.5 - (level * 0.02)
    self.timer = 0

    self.weaponOffset = {
        x = 49,
        y = 25
    }
    self.currentWeapon = Pistol.new(self.x + self.weaponOffset.x, self.y + self.weaponOffset.y, self.fireRate, self.damage)
    if level >= 10 then
        self.weaponOffset = {
            x = 42,
            y = 22
        }
        self.currentWeapon = AKM.new(self.x + self.weaponOffset.x, self.y + self.weaponOffset.y, self.fireRate, self.damage)
    elseif level >=5 then
        self.weaponOffset = {
            x = 49,
            y = 25
        }
        self.currentWeapon = Uzi.new(self.x + self.weaponOffset.x, self.y + self.weaponOffset.y, self.fireRate, self.damage)
    end
    
    return self
end

function Weapon:update(dt, x, y)
    self.currentWeapon:update(dt, x + self.weaponOffset.x, y + self.weaponOffset.y)
end

function Weapon:shoot(mx, my)
    self.currentWeapon:shoot(mx, my)
end

function Weapon:BulletsCollision(zombie)
    return self.currentWeapon:BulletsCollision(zombie)
end

function Weapon:draw()
    self.currentWeapon:draw()
end

return Weapon