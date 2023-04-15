local getData = require 'lua.data'
local matrix = require 'lua.matrix'

return function(config)
  local M = getData(config.code)
  M.name = config.name
  M.neptun = config.neptun

  return M
end
