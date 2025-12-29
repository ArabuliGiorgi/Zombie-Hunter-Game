local GameState = {}
GameState.__index = GameState

function GameState:new()
    local self = setmetatable({}, GameState)

    self.states = {}
    self.current = nil

    return self
end

function GameState:register(name, state)
    self.states[name] = state
end

function GameState:switch(name)
    self.current = self.states[name]
    if self.current and self.current.enter then
        self.current:enter()
    end
end

function GameState:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function GameState:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

function GameState:keypressed(key)
    if self.current and self.current.keypressed then
        self.current:keypressed(key)
    end
end

function GameState:mousepressed(x, y, button)
    if self.current and self.current.mousepressed then
        self.current:mousepressed(x, y, button)
    end
end

return GameState