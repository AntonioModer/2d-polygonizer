require("table_utils")
math.randomseed(os.time())
math.random()
math.random()
math.random()

function love.keypressed(key)
  if key == "escape" then
    love.event.push("quit")
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
  DEBUG = true
  
  -- graphics
  lg.setPointStyle("rough")
  lg.setBackgroundColor(255, 255, 255, 255)
end

function love.load()
  init()

  pwidth, pheight = 1000, 700
  polygonizer = polygonizer:new(10, 10, 1000, 700)
  
  polygonizer:add_point(210, 200)
  polygonizer:add_line(360, 200, 500, 500)
  polygonizer:add_rectangle(750, 200, 100, 300)
end

function love.update(dt)
  polygonizer:update(dt)

  
end

function love.draw()
  polygonizer:draw()
  
  if DEBUG then
    lg.setColor(0,0,0,255)
    lg.print("FPS: "..love.timer.getFPS(), 0, 0)
  end
end



