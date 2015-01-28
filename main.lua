--[[
  CSC 486A - Assignment #2
  Ryan Guy
]]--

require("table_utils")
math.randomseed(os.time())
math.random()
math.random()
math.random()

is_rendering = false
function love.keypressed(key)
  if key == "escape" then
    love.event.push("quit")
  end

  if key == "r" then
    is_rendering = not is_rendering
  end
  
  polygonizer:keypressed(key)
end

function love.keyreleased(key)
  polygonizer:keyreleased(key)
end

function love.mousepressed(x, y, button)
  polygonizer:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  polygonizer:mousereleased(x, y, button)
end

local function init()
  -- objects
  bbox = require("bbox")
  polygonizer = require("polygonizer")
  implicit_primative_set = require("implicit_primative_set")
  implicit_point = require("implicit_point")
  implicit_line = require("implicit_line")
  implicit_rectangle = require("implicit_rectangle")
  
  -- globals
  lg = love.graphics
  SCR_WIDTH = lg.getWidth()
  SCR_HEIGHT = lg.getHeight()
  DEBUG = false
  
  -- graphics
  lg.setPointStyle("rough")
  lg.setBackgroundColor(255, 255, 255, 255)
end

function love.load()
  init()

  pwidth, pheight = SCR_WIDTH - 530, SCR_HEIGHT
  polygonizer = polygonizer:new(0, 0, pwidth, pheight)
end

function love.update(dt)
  dt = 1/60

  if love.keyboard.isDown("lctrl") then dt = dt / 16 end
  polygonizer.debug = love.keyboard.isDown("d")
  DEBUG = love.keyboard.isDown("d")
  polygonizer:update(dt)

  
end

function love.draw()
  polygonizer:draw()
  
  if DEBUG then
    lg.setColor(0,0,0,255)
    --lg.print("FPS: "..love.timer.getFPS(), 0, 0)
  end
  
  if is_rendering then
    frame_count = frame_count or 0
    local filename = string.format("%06d.png", frame_count);
    local imgdata = love.graphics.newScreenshot()
    imgdata:encode(filename)
    
    frame_count = frame_count + 1
    print("Frame:", frame_count)
  end
end













