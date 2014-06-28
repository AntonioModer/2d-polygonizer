
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- polygonizer object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local pgr = {}
pgr.table = 'pgr'
pgr.debug = true
pgr.primatives = nil
pgr.bbox = nil

pgr.tile_width = 5
pgr.tile_height = 5
pgr.cell_width = 2 * pgr.tile_width
pgr.cell_height = 2 * pgr.tile_height
pgr.cols = nil
pgr.rows = nil

pgr.default_radius = 150
pgr.surface_threshold = 0.5

pgr.cell_inside_case = 16
pgr.cell_outside_case = 1

pgr.marked_cells = nil
pgr.cell_queue = nil
pgr.is_current = false

local pgr_mt = { __index = pgr }
function pgr:new(x, y, width, height)
  local pgr = setmetatable({}, pgr_mt)
  pgr.primatives = implicit_primative_set:new()
  pgr.marked_cells = {}
  pgr.cell_queue = {}
  pgr.neighbour_storage = {}
  for i=1,8 do
    pgr.neighbour_storage[i] = {i=nil, j=nil}
  end
  
  local cols = math.ceil(width / pgr.cell_width)
  local rows = math.ceil(height / pgr.cell_height)
  local width, height = cols * pgr.cell_width, rows * pgr.cell_height
  pgr.cols, pgr.rows = cols, rows
  
  pgr.bbox = bbox:new(x, y, width, height)
  
  return pgr
end

function pgr:keypressed(key)
end

function pgr:keyreleased(key)
end

function pgr:mousepressed(x, y, button)
end

function pgr:mousereleased(x, y, button)
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
  return cell
end

function pgr:_polygonalize_surface()
  local surface_cells = {}
  local neighbours = self.neighbour_storage
  local queue = self.cell_queue
  table.clear(queue)
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

  self.surface_cells = surface_cells

  self.is_current = true
end

------------------------------------------------------------------------------
function pgr:update(dt)
  if self.is_current then return end
  
  self:_polygonalize_surface()
end

------------------------------------------------------------------------------
function pgr:draw()
  if not self.debug then return end
  
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
  
  -- cell at mouse position
  local mx, my = love.mouse.getPosition()
  local w, h = self.cell_width, self.cell_height
  local i, j, x, y = self:_get_cell_at_position(mx, my)
  local case = self:_get_cell_marching_square_case(i, j)
  
  lg.setColor(0, 0, 255, 30)
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(0, 0, 0, 255)
  lg.print(case, x, y)
  
  -- surface cells
  local w, h = self.cell_width, self.cell_height
  local cells = self.surface_cells
  lg.setColor(0, 255, 0, 100)
  for idx=1,#cells do
    local i, j = cells[idx].i, cells[idx].j
    local x, y = self:_get_cell_position(i, j)
    lg.rectangle("fill", x, y, w, h)
  end
  
end

return pgr













