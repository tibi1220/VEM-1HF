local function round(num, numDecimalPlaces)
  return tonumber(string.format('%.' .. (numDecimalPlaces or 0) .. 'f', num))
end

local function prinTeX(num, unit, dec)
  if (dec or dec == 0) and dec ~= '' then
    num = round(num, dec)
  end
  tex.sprint([[\SI{]] .. num .. [[}{]] .. unit .. [[}]])
end

local function printMatrix(matrix, th, mult)
  local cols = #matrix
  local rows = #matrix[1]
  th = th or 1e-16
  mult = mult or 1

  for i = 1, cols do
    for j = 1, rows do
      local num = matrix[i][j]

      if math.abs(num) < th then
        tex.sprint(0)
      else
        prinTeX(num * mult, '', '')
      end

      if j == rows then
        tex.sprint '\\\\'
      else
        tex.sprint '&'
      end
    end
  end
end

return function(t)
  local v = t.variables

  return {
    -- Direct printing
    printDirect = function(var)
      tex.sprint(var)
    end,

    -- Simply print the specified value
    printVar = function(name)
      tex.sprint(v[name])
    end,

    -- Print the value with the help of the <siunitx> package
    printSIVar = function(num)
      prinTeX(v[num.name], num.unit, num.dec)
    end,

    -- Print 1D table value without formatting
    printVec = function(vec)
      tex.sprint(v[vec.name][vec.index])
    end,

    -- Print all Ke matrices
    fullKei = function()
      for i = 1, 3 do
        tex.sprint(
          [[\rmat{K}_]] .. i .. [[&=\left[\begin{array}{*{4}{X{28mm}}}]]
        )
        printMatrix(v.Ke[i], 1)
        tex.sprint [[\end{array}\right] \mathrm{SI}]]
        if i == 3 then
          tex.sprint [[\text{.}]]
        else
          tex.sprint [[\text{,}\\]]
        end
      end
    end,

    printDOFMatrix = function()
      tex.sprint(
        [[ \begin{array}{r c c} ]]
          .. [[ & \textcolor{gray}{\left(\begin{array}{*{4}{x{5mm}}} $v_1$ & $\varphi_1$ & $v_2$ & $\varphi_2$ \end{array}\right)} \\[2mm] ]]
          .. [[ \rmat{DOF} \; =  & \left[\begin{array}{*{4}{x{5mm}}} ]]
      )
      for i = 1, 3 do
        for j = 1, 4 do
          tex.sprint(v.eDOF[i][j])

          if j == 4 then
            tex.sprint '\\\\'
          else
            tex.sprint '&'
          end
        end
      end
      tex.sprint [[ \end{array}\right] & \textcolor{gray}{
    \begin{pmatrix}
      1 \\ 2 \\ 3
    \end{pmatrix}
  }. \end{array} ]]
    end,

    -- Other matrix printing functions
    printK = function(mult)
      printMatrix(v.K, 1, mult)
    end,
  }
end
