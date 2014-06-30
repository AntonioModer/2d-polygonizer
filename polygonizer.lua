
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- polygonizer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local lg = love.graphics

local CELL_QUAD = 1
local HORIZONTAL_QUAD = 2
local VERTICAL_QUAD = 3
local TRIANGLE_QUAD = 4
local TILE_QUAD = 5

local UI_SELECT = 0
local UI_ADD_POINT = 1
local UI_ADD_LINE = 2
local UI_ADD_RECTANGLE = 3
local UI_ANIMATE = 4

local font_normal = lg.newFont("LiberationMono-Regular.ttf", 20)
local font_small = lg.newFont("LiberationMono-Regular.ttf", 16)
local font_small_bold = lg.newFont("LiberationMono-Bold.ttf", 16)
local font_bold = lg.newFont("LiberationMono-Bold.ttf", 20)

local pgr = {}
pgr.table = 'pgr'
pgr.debug = false
pgr.primatives = nil
pgr.bbox = nil

pgr.tile_width = 4
pgr.tile_height = 4
pgr.cell_width = 2 * pgr.tile_width
pgr.cell_height = 2 * pgr.tile_height
pgr.cols = nil
pgr.rows = nil

pgr.default_radius = 100
pgr.min_radius = 20
pgr.max_radius = 300
pgr.radius_change_speed = 200
pgr.surface_threshold = 0.2

pgr.cell_inside_case = 16
pgr.cell_outside_case = 1

pgr.surface_cells = nil
pgr.flood_fill_cells = nil

pgr.spritebatch_image = nil
pgr.spritebatch_quads = nil
pgr.spritebatch = nil
pgr.gradient = require("orangeyellow")

pgr.marked_cells = nil
pgr.cell_queue = nil
pgr.is_current = false

pgr.ui_mode = UI_SELECT
pgr.selected_primative = nil
pgr.interface_buttons = nil

pgr.click_x = nil
pgr.click_y = nil

pgr.marching_square_draw_cases = {}

do
  local cases = pgr.marching_square_draw_cases
  local tw, th = pgr.tile_width, pgr.tile_height
  local upright = 0
  local downright = math.pi / 2
  local downleft = math.pi
  local upleft = 3 * math.pi / 2
  local ox, oy = 0.5 * tw, 0.5 * th
  
  cases[1] = function(x, y)
               -- blank case
             end
  cases[2] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + th + oy, upright,
                               1, 1, ox, oy)
             end
  cases[3] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + th + oy, upleft,
                               1, 1, ox, oy)
             end
  cases[4] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[HORIZONTAL_QUAD], x, y + th)
             end
  cases[5] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + oy, downleft,
                               1, 1, ox, oy)
             end
  cases[6] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + oy, upleft,
                               1, 1, ox, oy)
                               
               batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + th + oy, downright,
                               1, 1, ox, oy)
                               
               batch:add(q[TILE_QUAD], x + tw, y)
               
               batch:add(q[TILE_QUAD], x, y + th)
             end
  cases[7] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[VERTICAL_QUAD], x + tw, y)
             end
  cases[8] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + oy, upleft,
                               1, 1, ox, oy)
                      
               batch:add(q[TILE_QUAD], x + tw, y)
                               
               batch:add(q[HORIZONTAL_QUAD], x, y + th)
             end
  cases[9] = function(self, x, y)
               local q = self.spritebatch_quads
               local batch = self.spritebatch
               batch:add(q[TRIANGLE_QUAD], x + ox, y + oy, downright,
                               1, 1, ox, oy)
             end
  cases[10] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[VERTICAL_QUAD], x, y)
              end
  cases[11] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + oy, upright,
                                1, 1, ox, oy)
                               
                batch:add(q[TRIANGLE_QUAD], x + ox, y + th + oy, downleft,
                                1, 1, ox, oy)
               
                batch:add(q[TILE_QUAD], x, y)
                
                batch:add(q[TILE_QUAD], x + tw, y + th)
              end
  cases[12] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + oy, upright,
                                1, 1, ox, oy)
                      
                batch:add(q[TILE_QUAD], x, y)
                               
                batch:add(q[HORIZONTAL_QUAD], x, y + th)
              end
  cases[13] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[HORIZONTAL_QUAD], x, y)
              end
  cases[14] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + tw + ox, y + th + oy, downright,
                                1, 1, ox, oy)
                      
                batch:add(q[TILE_QUAD], x + tw, y)
                               
                batch:add(q[VERTICAL_QUAD], x, y)
              end
  cases[15] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[TRIANGLE_QUAD], x + ox, y + th + oy, downleft,
                                1, 1, ox, oy)
                      
                batch:add(q[TILE_QUAD], x, y)
                               
                batch:add(q[VERTICAL_QUAD], x + tw, y)
              end
  cases[16] = function(self, x, y)
                local q = self.spritebatch_quads
                local batch = self.spritebatch
                batch:add(q[CELL_QUAD], x, y)
              end
end
          

local pgr_mt = { __index = pgr }
function pgr:new(x, y, width, height)
  local pgr = setmetatable({}, pgr_mt)
  pgr.primatives = implicit_primative_set:new()
  pgr.marked_cells = {}
  pgr.cell_queue = {}
  pgr.neighbour_storage = {}
  pgr.surface_cells = {}
  pgr.flood_fill_cells = {}
  for i=1,8 do
    pgr.neighbour_storage[i] = {i=nil, j=nil}
  end
  
  local cols = math.ceil(width / pgr.cell_width)
  local rows = math.ceil(height / pgr.cell_height)
  local width, height = cols * pgr.cell_width, rows * pgr.cell_height
  pgr.cols, pgr.rows = cols, rows
  
  pgr.bbox = bbox:new(x, y, width, height)
  
  pgr:_init_textures()
  pgr:_init_interface_buttons()
  
  return pgr
end

function pgr:_init_interface_buttons()
  local ix, iy = 950, 50
  local x, y = ix, iy
  local xpad = 30
  local bpad = 15
  
  local buttons = {}
  
  local str = "Select"
  local bbox = bbox:new(x, y, font_normal:getWidth(str) + bpad, font_normal:getHeight(str))
  buttons[1] = {text = str, mode = UI_SELECT, bbox = bbox}
  
  local x = x + font_normal:getWidth(str) + xpad
  local str = "Animate"
  local bbox = bbox:new(x, y, font_normal:getWidth(str) + bpad, font_normal:getHeight(str))
  buttons[2] = {text = str, mode = UI_ANIMATE, bbox = bbox}
  
  local x, y = ix, y + 40
  local str = "Add Point"
  local bbox = bbox:new(x, y, font_normal:getWidth(str) + bpad, font_normal:getHeight(str))
  buttons[3] = {text = str, mode = UI_ADD_POINT, bbox = bbox}
  
  local x = x + font_normal:getWidth(str) + xpad
  local str = "Add Line"
  local bbox = bbox:new(x, y, font_normal:getWidth(str) + bpad, font_normal:getHeight(str))
  buttons[4] = {text = str, mode = UI_ADD_LINE, bbox = bbox}
  
  local x = x + font_normal:getWidth(str) + xpad
  local str = "Add Rectangle"
  local bbox = bbox:new(x, y, font_normal:getWidth(str) + bpad, font_normal:getHeight(str))
  buttons[5] = {text = str, mode = UI_ADD_RECTANGLE, bbox = bbox}
  
  self.interface_buttons = buttons
  self.selected_interface_button = buttons[3]
  self.ui_mode = UI_ADD_POINT
end

function pgr:_generate_triangle_image(width, height)
  local square = love.image.newImageData(width, height)
  for j=0,square:getWidth()-1 do
    for i=0,square:getHeight()-1 do
      if i > j then
        square:setPixel(j, i, 255,255,255,255)
      end
    end
  end
  return lg.newImage(square)
end

function pgr:_generate_rectangle_image(width, height)
  local square = love.image.newImageData(width, height)
  for j=0,square:getWidth()-1 do
    for i=0,square:getHeight()-1 do
      square:setPixel(j, i, 255,255,255,255)
    end
  end
  return lg.newImage(square)
end


function pgr:_init_textures()
  -- blank white shapes
  local cell_img = self:_generate_rectangle_image(self.cell_width, self.cell_height)
  local horz_img = self:_generate_rectangle_image(2*self.tile_width, self.tile_height)
  local vert_img = self:_generate_rectangle_image(self.tile_width, 2*self.tile_height)
  local triangle_img = self:_generate_triangle_image(self.tile_width, self.tile_height)
  local tile_img = self:_generate_rectangle_image(self.tile_width, self.tile_height)
  
  
  -- place images on a canvas to generate spritebatch
  local w = cell_img:getWidth() + horz_img:getWidth() + 
            vert_img:getWidth() + triangle_img:getWidth() + tile_img:getWidth()
  local h = cell_img:getHeight()
  local canvas = lg.newCanvas(w, h)
  lg.setCanvas(canvas)
  local x, y = 0, 0
  lg.draw(cell_img, x, y)
  x = x + cell_img:getWidth()
  lg.draw(horz_img, x, y)
  x = x + horz_img:getWidth()
  lg.draw(vert_img, x, y)
  x = x + vert_img:getWidth()
  lg.draw(triangle_img, x, y)
  x = x + triangle_img:getWidth()
  lg.draw(tile_img, x, y)
  lg.setCanvas()
  
  local imgdata = canvas:getImageData()
  self.spritebatch_image = lg.newImage(imgdata)
  
  -- generate quads for the spritebatch image
  local quads = {}
  local x, y = 0, 0
  quads[CELL_QUAD] = lg.newQuad(x, y, self.cell_width, self.cell_height, w, h)
  x = x + cell_img:getWidth()
  quads[HORIZONTAL_QUAD] = lg.newQuad(x, y, 2*self.tile_width, self.tile_height, w, h)
  x = x + horz_img:getWidth()
  quads[VERTICAL_QUAD] = lg.newQuad(x, y, self.tile_width, 2*self.tile_height, w, h)
  x = x + vert_img:getWidth()
  quads[TRIANGLE_QUAD] = lg.newQuad(x, y, self.tile_width, self.tile_height, w, h)
  x = x + triangle_img:getWidth()
  quads[TILE_QUAD] = lg.newQuad(x, y, self.tile_width, self.tile_height, w, h)
  
  self.spritebatch_quads = quads
  self.spritebatch = lg.newSpriteBatch(self.spritebatch_image, 20000)
end

function pgr:keypressed(key)
end

function pgr:keyreleased(key)
end

function pgr:mousepressed(x, y, button)
  if not self.bbox:contains_coordinate(x, y) then
    -- check for interface selection
    local btns = self.interface_buttons
    for i=1,#btns do
      local b = btns[i]
      if b.bbox:contains_coordinate(x, y) then
        self.selected_interface_button = b
        self.ui_mode = b.mode
        if self.ui_mode == UI_ANIMATE then
          self:_init_animation()
        end
      end
    end
    
    return
  end
  
  local mode = self.ui_mode
  
  if mode == UI_SELECT and button == "l" then
    local prim = self.primatives:get_primative_at_position(x, y)
    self.selected_primative = prim
  end
  
  if button == "r" then
    local prim = self.primatives:get_primative_at_position(x, y)
    self.primatives:remove_primative(prim)
    if self.selected_primative == prim then
      self.selected_primative = nil
    end
    self.is_current = false
  end
  
  if mode == UI_ADD_POINT and button == "l" then
    local p = self:add_point(x, y)
    -- move to center of bbox if out of range
    if not self.bbox:contains(p:get_bbox()) then
      p:set_position(self.bbox.x + 0.5 * self.bbox.width, 
                     self.bbox.y + 0.5 * self.bbox.height)
    end
    self.is_current = false
  end
  
  if mode == UI_ADD_LINE or mode == UI_ADD_RECTANGLE then
    self.click_x, self.click_y = x, y
  end
  
end

function pgr:mousereleased(x, y, button)
  if not (self.click_x and self.click_y) then
    return
  end
  

  if button == "l" and self.ui_mode == UI_ADD_LINE then
    local p = self:add_line(self.click_x, self.click_y, x, y)
    if not self.bbox:contains(p:get_bbox()) then
      p:set_center(self.bbox.x + 0.5 * self.bbox.width, 
                   self.bbox.y + 0.5 * self.bbox.height)
    end
  
    self.is_current = false
    self.click_x, self.click_y = nil, nil
  end
  
  if button == "l" and self.ui_mode == UI_ADD_RECTANGLE then
    local x1, y1 = self.click_x, self.click_y
    local x2, y2 = x, y
    local x, y = math.min(x1, x2), math.min(y1, y2)
    local width, height = math.abs(x1 - x2), math.abs(y1 - y2)
    local p = self:add_rectangle(x, y, width, height)
    if not self.bbox:contains(p:get_bbox()) then
      p:set_center(self.bbox.x + 0.5 * self.bbox.width, 
                   self.bbox.y + 0.5 * self.bbox.height)
    end
  
    self.is_current = false
    self.click_x, self.click_y = nil, nil
  end
end

function pgr:add_point(x, y)
  local p = implicit_point:new(x, y, self.default_radius)
  self.primatives:add_primative(p)
  return p
end

function pgr:add_line(x1, y1, x2, y2)
  local line = implicit_line:new(x1, y1, x2, y2, self.default_radius)
  self.primatives:add_primative(line)
  return line
end

function pgr:add_rectangle(x, y, width, height)
  local rect = implicit_rectangle:new(x, y, width, height, self.default_radius)
  self.primatives:add_primative(rect)
  return rect
end

-- returns index (i, j) and position (cx, cy) of the cell containing point (x, y)
function pgr:_get_cell_at_position(x, y)
  local i = math.floor((x - self.bbox.x) / self.cell_width) + 1
  local j = math.floor((y - self.bbox.y) / self.cell_height) + 1
  local cx = (i-1) * self.cell_width + self.bbox.x
  local cy = (j-1) * self.cell_height + self.bbox.y
  
  return i, j, cx, cy
end

-- returns top left corner of cell indexed at (i, j)
function pgr:_get_cell_position(i, j)
  return (i-1) * self.cell_width + self.bbox.x, 
         (j-1) * self.cell_height + self.bbox.y
end

-- calculates hash value of cell indexed at (i, j)
function pgr:_get_cell_hash_value(i, j)
  return self.cols * (j-1) + i
end

-- returns whether point (x, y) is inside the implicit surface
function pgr:_is_inside_surface(x, y)
  return self.primatives:get_field_value(x, y) > self.surface_threshold
end

-- calculates marching square case (1 to 16) of cell indexed at (i, j)
function pgr:_get_cell_marching_square_case(i, j)
  local case = 0

  -- top left corner of cell
  local x = (i-1) * self.cell_width + self.bbox.x
  local y = (j-1) * self.cell_height + self.bbox.y
  if self:_is_inside_surface(x, y) then
    case = case + 8
  end
  
  -- top right corner
  x = x + self.cell_width
  if self:_is_inside_surface(x, y) then
    case = case + 4
  end
  
  -- bottom right corner
  y = y + self.cell_height
  if self:_is_inside_surface(x, y) then
    case = case + 2
  end
  
  -- bottom left corner
  x = x - self.cell_width
  if self:_is_inside_surface(x, y) then
    case = case + 1
  end
  
  -- cases start at 1 for lua indexing
  return case + 1
end

-- returns index (i, j) of cell that lies on the boundary of surface near
-- an implicit primative
-- returns false if seed cannot be found
function pgr:_get_primative_seed_cell(primative)
  -- start at center cell
  local cx, cy = primative:get_center()
  local i, j, x, y = self:_get_cell_at_position(cx, cy)
  local case = self:_get_cell_marching_square_case(i, j)
  if case ~= self.cell_inside_case then
    if case == self.cell_outside_case then
      return false
    else
      return i, j
    end
  end
  
  -- move right until cell has a portion outside of the implicit surface
  while true do
    i = i + 1
    local case = self:_get_cell_marching_square_case(i, j)
    if case ~= self.cell_inside_case then
      return i, j
    end
    
    if i > self.cols then
      return false
    end
  end
end

function pgr:_mark_cell(i, j)
  self.marked_cells[self:_get_cell_hash_value(i, j)] = true
end

function pgr:_is_cell_marked(i, j)
  return self.marked_cells[self:_get_cell_hash_value(i, j)]
end

function pgr:_clear_marked_cells()
  table.clear_hash(self.marked_cells)
end

-- places all cell neighbours into storage table
-- storage table in form {{i=i1,j=j1}, {i=i2,j=j2}, {i=i3,j=j3}, ...}
function pgr:_get_cell_neighbours(i, j, storage)
  storage[1].i, storage[1].j = i-1, j-1   -- upleft
  storage[2].i, storage[2].j = i,   j-1   -- up
  storage[3].i, storage[3].j = i+1, j-1   -- upright
  storage[4].i, storage[4].j = i+1, j     -- right
  storage[5].i, storage[5].j = i+1, j+1   -- downright
  storage[6].i, storage[6].j = i,   j+1   -- down
  storage[7].i, storage[7].j = i-1, j+1   -- downleft
  storage[8].i, storage[8].j = i-1, j     -- left
end

-- creates a new cell table
function pgr:_new_cell_table(i, j, case)
  local cell = {i=i, j=j, case=case}
  cell.x, cell.y = self:_get_cell_position(cell.i, cell.j)
  return cell
end

function pgr:_polygonalize_surface()
  local surface_cells = self.surface_cells
  local neighbours = self.neighbour_storage
  local queue = self.cell_queue
  table.clear(queue)
  table.clear(surface_cells)
  self:_clear_marked_cells()
  
  local primatives = self.primatives:get_primatives()
  
  for i=1,#primatives do
    local primative = primatives[i]
    
    -- seed may already have been marked
    local i, j = self:_get_primative_seed_cell(primative)
    if not self:_is_cell_marked(i, j) then
    
      self:_mark_cell(i, j)
      local case = self:_get_cell_marching_square_case(i, j)
      queue[#queue+1] = self:_new_cell_table(i, j, case)
      
      -- continuation algorithm
      local in_case, out_case = self.cell_inside_case, self.cell_outside_case
      while #queue > 0 do
        local cell = table.pop(queue)
        self:_get_cell_neighbours(cell.i, cell.j, neighbours)
        
        for i=1,#neighbours do
          local ncell = neighbours[i]
          if not self:_is_cell_marked(ncell.i, ncell.j) then
            self:_mark_cell(ncell.i, ncell.j)
            local case = self:_get_cell_marching_square_case(ncell.i, ncell.j)
            if case ~= in_case and case ~= out_case then
              queue[#queue+1] = self:_new_cell_table(ncell.i, ncell.j, case)
            end
          end
        end
        
        surface_cells[#surface_cells + 1] = cell
      end
    end
  end

end

function pgr:_flood_fill_surface()
  local flood_cells = self.flood_fill_cells
  local neighbours = self.neighbour_storage
  local queue = self.cell_queue
  table.clear(queue)
  table.clear(flood_cells)
  self:_clear_marked_cells()
  
  local primatives = self.primatives:get_primatives()
  
  for i=1,#primatives do
    local primative = primatives[i]
    
    -- seed cell is at the centre of each primative
    local i, j = self:_get_cell_at_position(primative:get_center())
    if not self:_is_cell_marked(i, j) then
    
      self:_mark_cell(i, j)
      local case = self:_get_cell_marching_square_case(i, j)
      queue[#queue+1] = self:_new_cell_table(i, j, case)
      
      -- flood fill algorithm
      local in_case = self.cell_inside_case
      while #queue > 0 do
        local cell = table.pop(queue)
        self:_get_cell_neighbours(cell.i, cell.j, neighbours)
        
        for i=2,#neighbours,2 do
          local ncell = neighbours[i]
          if not self:_is_cell_marked(ncell.i, ncell.j) then
            self:_mark_cell(ncell.i, ncell.j)
            local case = self:_get_cell_marching_square_case(ncell.i, ncell.j)
            if case == in_case then
              queue[#queue+1] = self:_new_cell_table(ncell.i, ncell.j, case)
            end
          end
        end
        
        flood_cells[#flood_cells + 1] = cell
      end
    end
  end

end

function pgr:_draw_to_spritebatch()
  local cells = self.surface_cells
  local batch = self.spritebatch
  local case_funcs = self.marching_square_draw_cases
  batch:clear()
  batch:bind()
  
  local hw, hh = 0.5 * self.cell_width, 0.5 * self.cell_height
  local min, max = self.surface_threshold, 1
  local idiff = 1 / (max - min)
  local grad = self.gradient
  local glen = #grad
  
  local c = grad[1]
  batch:setColor(c[1], c[2], c[3], c[4])
  for i=1,#cells do
    local cell = cells[i]
    case_funcs[cell.case](self, cell.x, cell.y)
  end
  
  local fcells = self.flood_fill_cells
  for i=1,#fcells do
    local cell = fcells[i]
    local cx, cy = cell.x + hw, cell.y + hh
    local val = self.primatives:get_field_value(cx, cy)
    local ratio = (val - min) * idiff
    ratio = math.min(1, ratio)
    ratio = math.max(0, ratio)
    
    local c = grad[math.floor(1 + ratio * (glen - 1))]
    batch:setColor(c[1], c[2], c[3], c[4])
    
    case_funcs[cell.case](self, cell.x, cell.y)
  end
  
  batch:unbind()
end

------------------------------------------------------------------------------
function pgr:_update_primative_selection(dt)
  if not (self.ui_mode == UI_SELECT and self.selected_primative) then
    return
  end
  
  -- update radius
  local primative = self.selected_primative
  local min, max = self.min_radius, self.max_radius
  local speed = self.radius_change_speed
  local current_radius = primative:get_radius()
  local orig_radius = current_radius
  if     love.keyboard.isDown("up") then
    current_radius = current_radius + speed * dt
  elseif love.keyboard.isDown("down") then
    current_radius = current_radius - speed * dt
  end
  current_radius = math.min(current_radius, max)
  current_radius = math.max(current_radius, min)
  primative:set_radius(current_radius)
  
  -- make sure primative's bbox is still inside the polygonizer bbox
  local bbox = primative:get_bbox()
  if not self.bbox:contains(bbox) then
    primative:set_radius(orig_radius)
  end
  
  if current_radius ~= orig_radius then
    self.is_current = false
  end
  
  -- update move
  if not love.mouse.isDown("l") then
    return
  end
  
  local primative = self.selected_primative
  local mx, my = love.mouse.getPosition()
  local orig_cx, orig_cy = primative:get_center()
  primative:set_center(mx, my)
  
  -- make sure primative's bbox is still inside the polygonizer bbox
  local bbox = primative:get_bbox()
  if not self.bbox:contains(bbox) then
    primative:set_center(orig_cx, orig_cy)
  end
  
  self.is_current = false
end

function pgr:_init_animation()
  local minv, maxv = 200, 300
  
  local primatives = self.primatives:get_primatives()
  for i=1,#primatives do
    local p = primatives[i]
    local angle = 2 * math.pi * math.random()
    p.dirx, p.diry = math.cos(angle), math.sin(angle)
    p.speed = minv + math.random() * (maxv - minv)
  end
end

function pgr:_update_animation(dt)
  if self.ui_mode ~= UI_ANIMATE then return end
  
  local primatives = self.primatives:get_primatives()
  for i=1,#primatives do
    local p = primatives[i]
    local orig_x, orig_y = p:get_center()
    local tx, ty = p.dirx * p.speed * dt, p.diry * p.speed * dt
    p:translate(tx, ty)
    if not self.bbox:contains(p:get_bbox()) then
      p:set_center(orig_x, orig_y)
      
      -- find which wall object bounced off of
      local minx = math.min(math.abs(self.bbox.x - orig_x), 
                            math.abs(self.bbox.x + self.bbox.width - orig_x))
      local miny = math.min(math.abs(self.bbox.y - orig_y), 
                            math.abs(self.bbox.y + self.bbox.height - orig_y))
      if minx < miny then
        p.dirx = -p.dirx
      else
        p.diry = -p.diry
      end
    end
  end
  
  self.is_current = false
end

function pgr:update(dt)
  self:_update_primative_selection(dt)
  self:_update_animation(dt)

  if self.is_current then return end
  
  self:_polygonalize_surface()
  self:_flood_fill_surface()
  self:_draw_to_spritebatch()
  
  self.is_current = true
end

function pgr:_draw_selected_primative()
  local primative = self.selected_primative
  if not (primative and self.ui_mode == UI_SELECT) then return end
  
  primative:draw_outline()
  
end

function pgr:_draw_debug()
  lg.setColor(0, 0, 255, 255)
  self.bbox:draw()
  
  -- cell grid
  local cw, ch = self.cell_width, self.cell_height
  lg.setColor(0, 0, 0, 50)
  local x = self.bbox.x
  local yi = self.bbox.y
  local yf = self.bbox.y + self.bbox.height
  for i=1,self.cols-1 do
    x = x + cw
    lg.line(x, yi, x, yf)
  end
  
  local y = self.bbox.y
  local xi = self.bbox.x
  local xf = self.bbox.x + self.bbox.width
  for i=1,self.rows-1 do
    y = y + ch
    lg.line(xi, y, xf, y)
  end
  
  -- tile grid
  local tw, th = self.tile_width, self.tile_height
  lg.setColor(0, 0, 0, 30)
  local x = self.bbox.x
  local yi = self.bbox.y
  local yf = self.bbox.y + self.bbox.height
  for i=1,2*self.cols-1 do
    x = x + tw
    lg.line(x, yi, x, yf)
  end
  
  local y = self.bbox.y
  local xi = self.bbox.x
  local xf = self.bbox.x + self.bbox.width
  for i=1,2*self.rows-1 do
    y = y + tw
    lg.line(xi, y, xf, y)
  end
  
  self.primatives:draw()
  local primatives = self.primatives:get_primatives()
  for idx=1,#primatives do
    local cx, cy = primatives[idx]:get_center()
    local w, h = self.cell_width, self.cell_height
    local i, j, x, y = self:_get_cell_at_position(cx, cy)
    
    lg.setColor(0, 0, 255, 30)
    lg.rectangle("fill", x, y, w, h)
    
    -- seed cell
    local i, j = self:_get_primative_seed_cell(primatives[idx])
    local x, y = self:_get_cell_position(i, j)
    lg.setColor(255, 0, 0, 50)
    lg.rectangle("fill", x, y, w, h)
  end
  
  -- surface cells
  local w, h = self.cell_width, self.cell_height
  local cells = self.surface_cells
  lg.setColor(0, 255, 0, 100)
  for idx=1,#cells do
    local i, j = cells[idx].i, cells[idx].j
    local x, y = self:_get_cell_position(i, j)
    lg.rectangle("fill", x, y, w, h)
  end
  
  -- cell at mouse position
  local mx, my = love.mouse.getPosition()
  local w, h = self.cell_width, self.cell_height
  local i, j, x, y = self:_get_cell_at_position(mx, my)
  local case = self:_get_cell_marching_square_case(i, j)
  
  lg.setColor(0, 0, 255, 30)
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(255, 0, 0, 255)
  lg.print(case, x, y)
end

function pgr:_draw_interface_buttons()
  local buttons = self.interface_buttons
  local xpad, ypad = 7.5, 0
  lg.setFont(font_normal)
  
  for i=1,#buttons do
    lg.setColor(0, 0, 0, 150)
    if self.selected_interface_button == buttons[i] then
      lg.setColor(0, 0, 255, 255)
    end
    
    local btn = buttons[i]
    btn.bbox:draw()
    lg.print(btn.text, btn.bbox.x + xpad, btn.bbox.y)
  end
end

function pgr:_draw_interface_descriptions()
  local buttons = self.interface_buttons
  local x, y = buttons[1].bbox.x, buttons[1].bbox.y + 100
  lg.setColor(0, 0, 0, 255)
  local mode = self.ui_mode
  if     mode == UI_SELECT then
    lg.setFont(font_bold)
    lg.print("Object Selection:", x, y)
    lg.setFont(font_small)
    lg.print(
[[To select an object, hover over the object with
the mouse and press the left button

To remove an object, hover over the object with
the mouse and press the right button
               
To move an object, hold down the left mouse 
button and drag to the desired position

To change the radius of an object, select the 
object and press the up or down key on the 
keyboard to increase or decrease the radius]], x ,y + 30)
  elseif mode == UI_ANIMATE then
    lg.setFont(font_bold)
    lg.print("Animation:", x, y)
    lg.setFont(font_small)
    lg.print("There is nothing to do here but watch", x ,y + 30)
  elseif mode == UI_ADD_POINT then
    lg.setFont(font_bold)
    lg.print("Add a Point:", x, y)
    lg.setFont(font_small)
    lg.print("press and release the left mouse button", x,y + 30)
  elseif mode == UI_ADD_LINE then
    lg.setFont(font_bold)
    lg.print("Add a Line:", x, y)
    lg.setFont(font_small)
    lg.print("hold down the left mouse button,\ndrag the mouse, and release", x,y + 30)
  elseif mode == UI_ADD_RECTANGLE then
    lg.setFont(font_bold)
    lg.print("Add a Rectangle:", x, y)
    lg.setFont(font_small)
    lg.print("hold down the left mouse button,\ndrag the mouse, and release", x,y + 30)
  end
end

function pgr:_draw_interface()
  local ix, iy = SCR_WIDTH - 490, 20
  lg.setFont(font_bold)
  lg.setColor(0, 0, 0, 255)
  local str = "Interface Modes:"
  lg.print(str, ix, iy)
  
  self:_draw_interface_buttons()
  self:_draw_interface_descriptions()
  
end

function pgr:_draw_interface_primative_addition()
  if not (self.click_x and self.click_y) then return end
  
  if self.ui_mode == UI_ADD_LINE then
    lg.setColor(0, 0, 0, 255)
    lg.setPointSize(8)
    local mx, my =  love.mouse:getPosition()
    lg.point(mx, my)
    lg.point(self.click_x, self.click_y)
    lg.line(self.click_x, self.click_y, mx, my)
  end
  
  if self.ui_mode == UI_ADD_RECTANGLE then
    local x1, y1 = self.click_x, self.click_y
    local x2, y2 = love.mouse:getPosition()
    local x, y = math.min(x1, x2), math.min(y1, y2)
    local width, height = math.abs(x1 - x2), math.abs(y1 - y2)
    lg.setColor(0, 0, 0, 255)
    lg.rectangle("line", x, y, width, height)
  end
end

------------------------------------------------------------------------------
function pgr:draw()
  lg.setColor(0, 0, 0, 255)
  self.bbox:draw()

  lg.setColor(255, 255, 255, 255)
  lg.draw(self.spritebatch, 0, 0)
  
  self:_draw_selected_primative()
  self:_draw_interface()
  self:_draw_interface_primative_addition()

  if not self.debug then return end
  
  self:_draw_debug()
end

return pgr













