function love.conf(t)
    t.window.title = "Corporate Ladder"
    t.window.icon = "sprites/hero.png"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.vsync = true
    
    -- Identity for save directory
    t.identity = "corporate_ladder"
    
    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    
    -- Version info
    t.version = "11.4"
    t.window.minwidth = 800
    t.window.minheight = 600
    
    -- Release mode settings
    t.console = false
    t.externalstorage = true
    t.accelerometerjoystick = false
end
