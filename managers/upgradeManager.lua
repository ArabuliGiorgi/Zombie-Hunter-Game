local UpgradeManager = {}
UpgradeManager.__index = UpgradeManager

function UpgradeManager:new()
    local self = setmetatable({}, UpgradeManager)

    self.weaponLevel = 1
    self.hpLevel = 1
    self.heroAmount = 1

    return self
end

function UpgradeManager:getWeaponPrice()
    if self.weaponLevel >= (self.maxWeaponLevel or 15) then return nil end
    return 50 + 40 * self.weaponLevel
end

function UpgradeManager:getHPPrice()
    if self.hpLevel >= (self.maxHPLevel or 5) then return nil end
    return 100 * self.hpLevel
end

function UpgradeManager:getHeroPrice()
    if self.heroAmount >= (self.maxHeroAmount or 4) then return nil end
    return 50 + 150 * self.heroAmount
end

function UpgradeManager:isWeaponMax()
    return self.weaponLevel >= (self.maxWeaponLevel or 15)
end

function UpgradeManager:isHPMax()
    return self.hpLevel >= (self.maxHPLevel or 5)
end

function UpgradeManager:isHeroMax()
    return self.heroAmount >= (self.maxHeroAmount or 4)
end

function UpgradeManager:upgradeWeapon()
    if self:isWeaponMax() then return false end
    self.weaponLevel = self.weaponLevel + 1
    return true
end

function UpgradeManager:upgradeHP()
    if self:isHPMax() then return false end
    self.hpLevel = self.hpLevel + 1
    return true
end

function UpgradeManager:addHero()
    if self:isHeroMax() then return false end
    self.heroAmount = self.heroAmount + 1
    return true
end

function UpgradeManager:canAfford(price, coins)
    return coins >= price
end

function UpgradeManager:ResetAll()
    self.weaponLevel = 1
    self.hpLevel = 1
    self.heroAmount = 1
end

return UpgradeManager