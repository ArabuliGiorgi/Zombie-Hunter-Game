local Audio = {}

Audio.currentMusic = nil

function Audio.playMusic(path, volume)
    if Audio.currentMusic then
        Audio.currentMusic:stop()
    end

    local music = love.audio.newSource(path, "stream")
    music:setLooping(true)
    music:setVolume(volume or 0.6)
    music:play()

    Audio.currentMusic = music
end

function Audio.stopMusic()
    if Audio.currentMusic then
        Audio.currentMusic:stop()
        Audio.currentMusic = nil
    end
end

return Audio