-- Fallback for different Lua versions
local unpack = table.unpack or unpack

-- Game states and item types
local ITEM_TYPES = {
    JUMP_BOOST = {
        name = "Jump Boost",
        color = {0, 0.7, 1}, -- Blue (common)
        rarity = 0.1,        -- 10% chance
        size = 15
    },
    SCORE_BOOST = {
        name = "Score Boost",
        color = {0, 1, 0.5}, -- Green (uncommon)
        rarity = 0.05,       -- 5% chance
        size = 15
    },
    SWOOSH = {
        name = "Swoosh",
        color = {0.8, 0, 1}, -- Purple (epic)
        rarity = 0.03,       -- 3% chance
        size = 15
    },
    WIDE_PLATFORMS = {
        name = "Wide Platforms",
        color = {1, 0.8, 0}, -- Gold (legendary)
        rarity = 0.01,       -- 1% chance
        size = 15
    }
}

local MENU = "menu"
local PLAYING = "playing"
local GAME_OVER = "gameover"
local gameState = MENU

-- Button dimensions
local buttonWidth = 200
local buttonHeight = 50

-- Active effects
local activeEffects = {
    jumpBoost = 0,    -- Timer for jump boost
    swoosh = 0,       -- Timer for swoosh
    widePlatforms = 0, -- Timer for wide platforms
    scoreBoost = 0    -- Timer for score multiplier
}

-- Game constants
local normalJumpForce = -500  -- Adjusted for sprite size
local boostedJumpForce = -700
local normalPlatformWidth = 70
local widePlatformWidth = 120
local scoreMultiplier = 1

-- Sprite images
local sprites = {
    hero = nil,
    typescript = nil,
    keyboard = nil,
    haskell = nil,
    rust = nil,
    platform = nil
}

-- Game state
local player = {
    x = 400,
    y = 450,
    width = 48,
    height = 48,
    yVelocity = -200,
    xVelocity = 0,
    speed = 300,
    jumpForce = normalJumpForce
}

local platforms = {}
local items = {}
local gravity = 800  -- Reduced gravity for better control
local platformWidth = normalPlatformWidth
local platformHeight = 15  -- Slimmer platform height
local score = 0
local highestY = 0

-- Initialize game
function initializeLevel()
    -- Create starting platform directly under player
    table.insert(platforms, {
        x = player.x - platformWidth/2,
        y = player.y + player.height + 5,
        width = platformWidth,
        height = platformHeight
    })
    
    -- Create initial platforms with controlled spacing
    local lastY = player.y + player.height
    for i = 1, 10 do
        -- Adjusted platform spacing for reliable jumps
        lastY = lastY - love.math.random(120, 140)
        local platform = {
            x = love.math.random(50, 750),
            y = lastY,
            width = platformWidth,
            height = platformHeight
        }
        table.insert(platforms, platform)
    end
end

function resetGame()
    player.x = 400
    player.y = 450
    player.yVelocity = -200
    player.xVelocity = 0
    highestY = 0
    score = 0
    scoreMultiplier = 1
    
    -- Reset effects
    activeEffects.jumpBoost = 0
    activeEffects.swoosh = 0
    activeEffects.widePlatforms = 0
    activeEffects.scoreBoost = 0
    player.jumpForce = normalJumpForce
    platformWidth = normalPlatformWidth
    
    -- Clear and reset platforms and items
    platforms = {}
    items = {}
    
    -- Initialize platforms
    initializeLevel()
end

-- Error handler for release mode
local function errorHandler(msg)
    print("Error: " .. tostring(msg))
    return msg
end

-- Safely load an image with error handling
local function loadImage(path)
    local success, result = pcall(love.graphics.newImage, path)
    if success then
        return result
    else
        print("Failed to load image: " .. path)
        -- Return a 1x1 white pixel as fallback
        local data = love.image.newImageData(1, 1)
        data:setPixel(0, 0, 1, 1, 1, 1)
        return love.graphics.newImage(data)
    end
end

function love.load()
    -- Load sprites with error handling
    sprites.hero = loadImage("sprites/hero.png")
    sprites.typescript = loadImage("sprites/ts.png")
    sprites.keyboard = loadImage("sprites/keyboard.png")
    sprites.haskell = loadImage("sprites/haskell.png")
    sprites.rust = loadImage("sprites/rust.png")
    sprites.platform = loadImage("sprites/platform.png")
    
    -- Set error handler
    love.errhand = errorHandler
    
    resetGame()
end

function pointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState == MENU then
        local playButton = {
            x = 400 - buttonWidth/2,
            y = 300 - buttonHeight/2,
            width = buttonWidth,
            height = buttonHeight
        }
        
        if pointInButton(x, y, playButton) then
            gameState = PLAYING
            resetGame()
        end
    elseif gameState == GAME_OVER then
        local replayButton = {
            x = 400 - buttonWidth/2,
            y = 350 - buttonHeight/2,
            width = buttonWidth,
            height = buttonHeight
        }
        
        if pointInButton(x, y, replayButton) then
            gameState = PLAYING
            resetGame()
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "space" then
        if gameState == MENU then
            gameState = PLAYING
            resetGame()
        elseif gameState == GAME_OVER then
            gameState = PLAYING
            resetGame()
        end
    end
 end

local function updateEffects(dt)
    -- Update jump boost
    if activeEffects.jumpBoost > 0 then
        activeEffects.jumpBoost = activeEffects.jumpBoost - dt
        if activeEffects.jumpBoost <= 0 then
            player.jumpForce = normalJumpForce
        end
    end
    
    -- Update swoosh
    if activeEffects.swoosh > 0 then
        activeEffects.swoosh = activeEffects.swoosh - dt
        if activeEffects.swoosh > 0 then
            player.y = player.y - 300 * dt -- Strong upward movement
        end
    end
    
    -- Update wide platforms
    if activeEffects.widePlatforms > 0 then
        activeEffects.widePlatforms = activeEffects.widePlatforms - dt
        if activeEffects.widePlatforms <= 0 then
            platformWidth = normalPlatformWidth
        else
            platformWidth = widePlatformWidth
        end
    end
    
    -- Update score boost
    if activeEffects.scoreBoost > 0 then
        activeEffects.scoreBoost = activeEffects.scoreBoost - dt
        if activeEffects.scoreBoost <= 0 then
            scoreMultiplier = 1
        end
    end
end

function love.update(dt)
    if gameState ~= PLAYING then
        return
    end
    
    updateEffects(dt)
    
    -- Player horizontal movement
    if love.keyboard.isDown('left') then
        player.xVelocity = -player.speed
    elseif love.keyboard.isDown('right') then
        player.xVelocity = player.speed
    else
        player.xVelocity = 0
    end

    -- Update player position
    player.x = player.x + player.xVelocity * dt
    player.y = player.y + player.yVelocity * dt
    
    -- Apply gravity
    player.yVelocity = player.yVelocity + gravity * dt
    
    -- Screen wrapping
    if player.x < 0 then player.x = 800
    elseif player.x > 800 then player.x = 0 end
    
    -- Platform collision
    for i, platform in ipairs(platforms) do
        if player.yVelocity > 0 and -- Moving downward
           player.y + player.height > platform.y and
           player.y < platform.y + platform.height and
           player.x + player.width > platform.x and
           player.x < platform.x + platform.width then
            
            player.yVelocity = player.jumpForce
            player.y = platform.y - player.height
        end
    end
    
    -- Item collection
    for i = #items, 1, -1 do
        local item = items[i]
        if not item.collected and
           player.x + player.width > item.x - item.type.size and
           player.x < item.x + item.type.size and
           player.y + player.height > item.y - item.type.size and
           player.y < item.y + item.type.size then
            
            -- Apply item effect
            if item.type == ITEM_TYPES.JUMP_BOOST then
                player.jumpForce = boostedJumpForce
                activeEffects.jumpBoost = 5
            elseif item.type == ITEM_TYPES.SCORE_BOOST then
                scoreMultiplier = 2
                activeEffects.scoreBoost = 5
            elseif item.type == ITEM_TYPES.SWOOSH then
                activeEffects.swoosh = 5
            elseif item.type == ITEM_TYPES.WIDE_PLATFORMS then
                platformWidth = widePlatformWidth
                activeEffects.widePlatforms = 5
            end
            
            table.remove(items, i)
        end
    end
    
    -- Update camera and generate new platforms
    if player.y < 300 then
        local shift = 300 - player.y
        player.y = 300
        
        -- Move platforms and items down
        for i = #platforms, 1, -1 do
            platforms[i].y = platforms[i].y + shift
            if platforms[i].y > 600 then
                table.remove(platforms, i)
                
                -- Create new platform at top
                local newPlatform = {
                    x = love.math.random(50, 750),
                    y = love.math.random(-70, -20),  -- More controlled vertical placement
                    width = platformWidth,
                    height = platformHeight
                }
                table.insert(platforms, newPlatform)
                
                -- Chance to spawn item on platform
                for _, itemType in pairs(ITEM_TYPES) do
                    if love.math.random() < itemType.rarity then
                        local item = {
                            type = itemType,
                            x = newPlatform.x + newPlatform.width/2,
                            y = newPlatform.y - 25,
                            collected = false
                        }
                        table.insert(items, item)
                        break -- Only spawn one item per platform
                    end
                end
            end
        end
        
        -- Move existing items down
        for i = #items, 1, -1 do
            items[i].y = items[i].y + shift
            if items[i].y > 600 then
                table.remove(items, i)
            end
        end
        
        -- Update score with multiplier
        highestY = highestY - shift
        score = math.floor((-highestY / 100) * scoreMultiplier)
    end
    
    -- Game over condition
    if player.y > 600 then
        gameState = GAME_OVER
    end
end

function love.draw()
    -- Draw background
    love.graphics.setColor(0.8, 0.85, 0.95)  -- Light cool gray with blue tint
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    if gameState == MENU then
        -- Draw menu
        love.graphics.setColor(0.2, 0.2, 0.4)  -- Dark blue-ish color
        love.graphics.rectangle("line", 400 - buttonWidth/2, 300 - buttonHeight/2, buttonWidth, buttonHeight)
        love.graphics.printf("Play", 0, 300 - 12, 800, "center")
        love.graphics.printf("Corporate Ladder", 0, 150, 800, "center")
        love.graphics.printf("Climb the tech stack!", 0, 200, 800, "center")
        
    elseif gameState == PLAYING then
        -- Draw player
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(sprites.hero, player.x, player.y, 0, player.width/sprites.hero:getWidth(), player.height/sprites.hero:getHeight())
        
        -- Draw platforms as RGB keyboard-like platforms
        for _, platform in ipairs(platforms) do
            -- Platform base (darker gray with slight transparency)
            love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
            love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
            
            -- RGB effect on the top
            local segments = 3
            local segmentWidth = platform.width / segments
            love.graphics.setColor(1, 0.2, 0.2, 0.8) -- Red
            love.graphics.rectangle("fill", platform.x, platform.y, segmentWidth, 5)
            love.graphics.setColor(0.2, 1, 0.2, 0.8) -- Green
            love.graphics.rectangle("fill", platform.x + segmentWidth, platform.y, segmentWidth, 5)
            love.graphics.setColor(0.2, 0.2, 1, 0.8) -- Blue
            love.graphics.rectangle("fill", platform.x + segmentWidth * 2, platform.y, segmentWidth, 5)
        end
        
        -- Draw items
        for _, item in ipairs(items) do
            love.graphics.setColor(1, 1, 1)
            local sprite
            if item.type == ITEM_TYPES.JUMP_BOOST then
                sprite = sprites.typescript
            elseif item.type == ITEM_TYPES.SCORE_BOOST then
                sprite = sprites.keyboard
            elseif item.type == ITEM_TYPES.SWOOSH then
                sprite = sprites.haskell
            else
                sprite = sprites.rust
            end
            love.graphics.draw(sprite, item.x - item.type.size, item.y - item.type.size, 0, 
                             item.type.size*2/sprite:getWidth(), item.type.size*2/sprite:getHeight())
        end
        
        -- Draw active effect timers
        love.graphics.setColor(0.2, 0.2, 0.4)  -- Dark blue-ish color
        love.graphics.print("Score: " .. score, 10, 10)
        
        local y = 30
        if activeEffects.jumpBoost > 0 then
            love.graphics.setColor(unpack(ITEM_TYPES.JUMP_BOOST.color))
            love.graphics.print("Jump Boost: " .. string.format("%.1f", activeEffects.jumpBoost), 10, y)
            y = y + 20
        end
        if activeEffects.scoreBoost > 0 then
            love.graphics.setColor(unpack(ITEM_TYPES.SCORE_BOOST.color))
            love.graphics.print("Score x2: " .. string.format("%.1f", activeEffects.scoreBoost), 10, y)
            y = y + 20
        end
        if activeEffects.swoosh > 0 then
            love.graphics.setColor(unpack(ITEM_TYPES.SWOOSH.color))
            love.graphics.print("Swoosh: " .. string.format("%.1f", activeEffects.swoosh), 10, y)
            y = y + 20
        end
        if activeEffects.widePlatforms > 0 then
            love.graphics.setColor(unpack(ITEM_TYPES.WIDE_PLATFORMS.color))
            love.graphics.print("Wide Platforms: " .. string.format("%.1f", activeEffects.widePlatforms), 10, y)
        end
        
    elseif gameState == GAME_OVER then
        -- Draw game over screen
        love.graphics.setColor(0.2, 0.2, 0.4)  -- Dark blue-ish color
        love.graphics.printf("Game Over!", 0, 200, 800, "center")
        love.graphics.printf("Final Score: " .. score, 0, 250, 800, "center")
        
        -- Draw replay button
        love.graphics.rectangle("line", 400 - buttonWidth/2, 350 - buttonHeight/2, buttonWidth, buttonHeight)
        love.graphics.printf("Play Again", 0, 350 - 12, 800, "center")
    end
end
