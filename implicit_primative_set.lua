
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- implicit_primative_set object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local POINT = "ip"
local LINE = "il"
local RECTANGLE = "ir"

local ips = {}
ips.table = 'ips'
ips.debug = true
ips.primatives = nil
ips.ricci_blend = 2

local ips_mt = { __index = ips }
function ips:new()
  local ips = setmetatable({}, ips_mt)
  ips.primatives = {}
  
  return ips
end

function ips:add_primative(ip)
  self.primatives[#self.primatives + 1] = ip
end

function ips:remove_primative(primative)
  for i=1,#self.primatives do
    if self.primatives[i] == primative then
      table.remove(self.primatives, i)
    end
  end
end

function ips:set_ricci_blend(k)
  self.ricci_blend = k
end

function ips:get_field_value(x, y)
  local k = self.ricci_blend
  local f = 0
  for i=1,#self.primatives do
    if k == 1 then
      f = f + self.primatives[i]:get_field_value(x, y)
    else
      f = f + self.primatives[i]:get_field_value(x, y)^k
    end
  end
  
  if k ~= 1 then
    f = f^(1/k)
  end
  
  if f > 1 then 
    f = 1
  elseif f < 0 then 
    f = 0
  end
  
  return f
end

function ips:get_primatives()
  return self.primatives
end

function ips:get_primative_at_position(x, y)
  local ip
  for i=1,#self.primatives do
    local p = self.primatives[i]
    if     p.table == POINT then
      local dx, dy = x - p.x, y - p.y
      local lensqr = dx*dx + dy*dy
      if lensqr < p.radius * p.radius then
        ip = p
        break
      end
    elseif p.table == LINE then
      local f = p:get_field_value(x, y)
      if f ~= 0 then
        ip = p
        break
      end
    elseif p.table == RECTANGLE then
      local f = p:get_field_value(x, y)
      if f ~= 0 then
        ip = p
        break
      end
    end
  end
  
  return ip
end

------------------------------------------------------------------------------
function ips:update(dt)
end

------------------------------------------------------------------------------
function ips:draw()
  if not self.debug then return end  

  for i=1,#self.primatives do
    self.primatives[i]:draw()
  end
end

return ips




