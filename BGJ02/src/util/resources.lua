-- resources

require("util/helper")

Resources = class("Resources")

function Resources:__init(prefix)
    self.prefix = prefix
    self.imageQueue = {}
    self.musicQueue = {}
    self.fontQueue = {}
    self.shaderQueue = {}

    self.images = {}
    self.music = {}
    self.fonts = {}
    self.shaders = {}
end

function Resources:addFont(name, src, size)
    self.fontQueue[name] = {src, size}
end

function Resources:addImage(name, src)
    self.imageQueue[name] = src
end

function Resources:addMusic(name, src)
    self.musicQueue[name] = src
end

function Resources:addShader(name, src)
    self.shaderQueue[name] = src
end

function Resources:load(threaded)
    for name, pair in pairs(self.fontQueue) do
        self.fonts[name] = love.graphics.newFont(self.prefix .. pair[1], pair[2])
        self.fontQueue[name] = nil
    end

    for name, src in pairs(self.imageQueue) do
        self.images[name] = love.graphics.newImage(self.prefix .. src)
        self.imageQueue[name] = nil
    end

    for name, src in pairs(self.musicQueue) do
        self.music[name] = love.audio.newSource(self.prefix .. src)
        self.musicQueue[name] = nil
    end

    for name, src in pairs(self.shaderQueue) do
        contents, size = love.filesystem.read(self.prefix .. src)
        self.shaders[name] = love.graphics.newPixelEffect(contents)
        self.shaderQueue[name] = nil
    end
end
