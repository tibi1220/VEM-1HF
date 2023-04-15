local function round(num, numDecimalPlaces)
  return tonumber(string.format('%.' .. (numDecimalPlaces or 0) .. 'f', num))
end

local function prinTeX(num, unit, dec)
  if (dec or dec == 0) and dec ~= '' then
    num = round(num, dec)
  end
  tex.sprint([[\SI{]] .. num .. [[}{]] .. unit .. [[}]])
end

return function(t)
  local v = t.variables

  return {
    -- Simply print the specified value
    printVar = function(name)
      tex.sprint(v[name])
    end,

    -- Print the value with the help of the <siunitx> package
    printSIVar = function(name, unit, dec)
      prinTeX(v[name], unit, dec)
    end,

    printVec = function(vec)
      tex.sprint(v[vec.name][vec.index])
    end,
  }
end
