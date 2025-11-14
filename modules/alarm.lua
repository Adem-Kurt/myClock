local audio = require "audio"

alarm = Object({})

function alarm:constructor(sound_path)
    self.sound = audio.Sound(sound_path or "assets/sound/alarm.mp3")
    self.sound.loop = true
end

function alarm:play()
    self.sound:play()
end

function alarm:stop()
    self.sound:stop()
end

return alarm
