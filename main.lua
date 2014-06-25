math.randomseed(os.time())
math.random()
math.random()
math.random()

function love.keypressed(key)
  if key == "escape" then
    love.event.push("quit")
  end
end

local function init()
  -- objects
  bbox = require("bbox")
  implicit_primative_set = require("implicit_primative_set")
  implicit_point = require("implicit_point")
  implicit_line = require("implicit_line")
  implicit_rectangle = require("implicit_rectangle")
  
  -- globals
  lg = love.graphics
  SCR_WIDTH = lg.getWidth()
  SCR_HEIGHT = lg.getHeight()
  
  -- graphics
  lg.setPointStyle("rough")
  lg.setBackgroundColor(255, 255, 255, 255)
end

function love.load()
  init()
  
  rect = implicit_rectangle:new(200, 200, 300, 100, 100)
  rect:set_position(120, 300)
  rect:set_rectangle(200, 120, 200, 300)
  
  line = implicit_line:new(500, 200, 400, 400, 120)
  point = implicit_point:new(600, 400, 200)
  
  set = implicit_primative_set:new()
  set:add_primative(rect)
  set:add_primative(line)
  set:add_primative(point)
end

function love.update(dt)
  local mx, my = love.mouse.getPosition()
  
  local p = set:get_primative_at_position(mx, my)
  print(set:get_field_value(mx, my))
end

function love.draw()
  set:draw()
end
