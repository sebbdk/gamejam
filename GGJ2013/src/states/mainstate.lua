-- intro

require("core/gamestate")
require("core/resources")
require("core/objectgroup")
require("objects/player")
require("objects/door")
require("objects/file")
require("objects/trigger")
require("objects/level")
require("objects/enemy")
require("objects/sprite")

MainState = class("MainState", GameState)

function MainState:__init()
    self.lifetime = 0
    self.centerX = 0
    self.centerY = 0
    self.currentLevel = 0

    self.objects = {}
    self.levels = {}

    for i = 0, 4 do
        self:loadLevel(i)
    end

    self.player = Player()
    self.nextLevelSpawn = "spawn_01"
    self:setLevel(0)

    self.levelFade = 0
    self.nextLevel = 0

    self.canvas = nil
end

function MainState:parseLevel(i)
    -- relative level switching ("+1")
    local fc = string.sub(i, 0, 1)
    if fc == "+" or fc == "-" then
        i = self.currentLevel + tonumber(i)
    end
    return i
end

function MainState:fadeToLevel(i, spawnName)
    self.levelFade = 1.0
    self.nextLevel = i
    self.nextLevelSpawn = spawnName
end

function MainState:setLevel(i)
    -- make sure to transfer the player into the new level
    self:world():remove(self.player)
    self.currentLevel = self:parseLevel(i)
    if self.nextLevelSpawn then
        local spawn = self:world():byName(self.nextLevelSpawn)
        if not spawn then
            print("WARNING! Level Spawn " .. self.nextLevelSpawn .. " in Level " .. self.currentLevel .. " not found.")
        else
            self.player.x = spawn.x + spawn.w / 2
            self.player.y = spawn.y + spawn.h / 2
        end
        self.nextLevelSpawn = nil
    end
    self:world():add(self.player)
    self:playLevelMusic(i)
end

function MainState:playLevelMusic (i)
    local playlist = {
        { "dark_factory", 0.1 },
        { "cave_theme", 0.1 }
    }

    local audio_set = resources:makeSound(playlist[i+1][1], "stream", true)
    audio_set:setVolume(playlist[i+1][2])
    audio_set:play()

end

function MainState:loadLevel(i)
    self.objects[i] = ObjectGroup()

    self.objects[i].physicsWorld = love.physics.newWorld(0, 0, false)
    self.objects[i].physicsWorld:setCallbacks(function(a, b, coll) self.objects[i]:beginContact(a, b, coll) end,
                                   function(a, b, coll) self.objects[i]:endContact(a, b, coll) end,
                                   function(a, b, coll) self.objects[i]:preSolve(a, b, coll) end,
                                   function(a, b, coll) self.objects[i]:postSolve(a, b, coll) end)

    local level = Level("level" .. i, self.objects[i])
    self.levels[i] = level
    self.objects[i]:add(level)

    -- HERE STARTS MAGIC
    local o = self.objects[i]
    if i == 0 then
        o:byName("trigger_01").onEnter = function()
            o:byName("trigger_02").enabled = true
        end

        o:byName("trigger_02").onEnter = function()
            o:byName("door_09").locked = false
        end
    end
    -- HERE ENDS MAGIC
end

function MainState:world()
    return self.objects[self.currentLevel]
end

function MainState:getOffset()
    return math.round(love.graphics.getWidth() / 2 - self.centerX),
        math.round(love.graphics.getHeight() / 2 - self.centerY)
end

function MainState:screenToWorld(x, y)
    local ox, oy = self:getOffset()
    local scale = 1
    return (x - ox) / scale, (y - oy) / scale
end

function MainState:worldToScreen(x, y)
    local ox, oy = self:getOffset()
    return x + ox, y + oy
end

function MainState:getMousePosition()
    return self:screenToWorld(love.mouse.getPosition())
end

function MainState:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    if not self.canvas or self.canvas:getWidth() ~= w or self.canvas:getHeight() ~= h then
        self.canvas = love.graphics.newCanvas(w, h)
    end
    love.graphics.setCanvas(self.canvas)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.clear()

    love.graphics.push()
    love.graphics.translate(self:getOffset())

    self:world():draw()
    love.graphics.pop()

    -- draw darkness
    resources:sendShaderValue("darkness", "range", 46 * 2.5 * (1 + 0.05 * (math.sin(self.lifetime * 2))))
    resources:sendShaderValue("darkness", "blur", 128)
    resources:sendShaderValue("darkness", "width", love.graphics.getWidth())
    resources:sendShaderValue("darkness", "height", love.graphics.getHeight())

    resources:sendShaderValue("darkness", "shadowmap", self.player.shadowMap)
    love.graphics.setPixelEffect(resources.shaders.darkness)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setPixelEffect()

    love.graphics.setColor(255, 255, 255)
    if debug then
        love.graphics.setFont(resources.fonts.tiny)
        love.graphics.print(love.timer.getFPS() .. " FPS", 10, 10)
    end

    love.graphics.setFont(resources.fonts.handBig)
    if activeActionObject then
        local t = "[E] " .. activeActionObject.actionText
        love.graphics.print(t, love.graphics.getWidth() / 2 -  love.graphics.getFont():getWidth(t) / 2, love.graphics.getHeight() - 100)
    end


    -- distortion shader
    resources:sendShaderValue("distort", "lifetime", self.lifetime)
    resources:sendShaderValue("distort", "distortion", 1)
    love.graphics.setPixelEffect(resources.shaders.distort)
    love.graphics.setColor(255, 255, 255)
    love.graphics.setCanvas()
    love.graphics.draw(self.canvas, 0, 0)
    love.graphics.setPixelEffect()

    if self.levelFade > 0 then
        love.graphics.setColor(0, 0, 0, math.sin(math.pi * self.levelFade) * 255)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function MainState:update(dt)
    self.lifetime = self.lifetime + dt

    self.player:bakeShadows(self:world().physicsWorld)
    self:world():update(dt)

    if self.levelFade > 0 then
        if self.nextLevel and self.levelFade < 0.5 then
            self:setLevel(self.nextLevel)
            self.nextLevel = nil
        end

        self.levelFade = self.levelFade - dt * 0.6
        if self.levelFade < 0 then self.levelFade = 0 end
    end
end

function MainState:keypressed(k, u)
    if k == "escape" then
        stack:pop()
    elseif k == "f" then
        file.number = "21494"
        stack:push(file)
    elseif k == "e" then
        if activeActionObject then
            activeActionObject:onAction()
            activeActionObject = nil
        end
    elseif k == "up" then
        self:fadeToLevel("+1")
    elseif k == "down" then
        self:fadeToLevel("-1")
    end
end
