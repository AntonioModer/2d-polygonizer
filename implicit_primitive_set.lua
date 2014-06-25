
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- implicit_primative_set object
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local ips = {}
ips.table = 'ips'
ips.debug = true
ips.primatives = nil

local ips_mt = { __index = ips }
function ips:new()
  local ips = setmetatable({}, ips_mt)
  ips.primatives = {}
  
  return ips
end

function ips:add_primative(ip)
  self.primatives[#self.primatives + 1] = ip
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



