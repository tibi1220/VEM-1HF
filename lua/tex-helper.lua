local PI = math.pi

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

    -- Direct formatted printing
    printSIDirect = function(num)
      prinTeX(num.value, num.unit, num.dec)
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

    printParametricF = function()
      local figure = v.parametric

      local p = figure.forces.p
      local F = figure.forces.F
      local M = figure.forces.M
      local free = figure.free
      local letters = { 'A', 'B', 'C', 'D' }

      tex.sprint [[\begin{bmatrix}]]
      for i = 0, 3 do
        for j = 1, 2 do
          local found = false
          for k = 1, 5 do
            if free[k] == i * 2 + j then
              found = true
            end
          end
          if found then
            tex.sprint [[ 0 \\ ]]
          else
            if j == 1 then
              tex.sprint([[F_{]] .. letters[i + 1] .. [[}\\]])
            else
              tex.sprint([[M_{]] .. letters[i + 1] .. [[}\\]])
            end
          end
        end
      end
      tex.sprint [[\end{bmatrix}]]

      tex.sprint [[+ \begin{bmatrix}]]
      for i = 1, 4 do
        if F == i then
          tex.sprint [[ -F_t \\ ]]
        else
          tex.sprint [[ 0 \\ ]]
        end
        if M == i then
          tex.sprint [[ M_t \\ ]]
        else
          tex.sprint [[ 0 \\ ]]
        end
      end
      tex.sprint [[\end{bmatrix}]]

      for i = 0, 2 do
        if p[i + 1] == 1 then
          tex.sprint(
            [[+ \begin{bmatrix}]]
              .. string.rep('0 \\\\', 2 * i)
              .. [[ -p_t (L/2) \\ -p_t (L^2/12) \\ -p_t (L/2) \\ p_t (L^2/12) ]]
              .. string.rep('\\\\ 0', 2 * (2 - i))
              .. [[\end{bmatrix}]]
          )
        end
      end
    end,

    printUkondDegMM = function()
      local free = v.parametric.free
      local U = v.Ucalc

      for k = 1, 5 do
        local i = free[k]
        local e = U[i][1]

        if i % 2 == 1 then
          if math.abs(e) <= 0.000001 then
            tex.print [[0 \, \mathrm{mm}]]
          else
            prinTeX(e * 1000, 'mm', '')
          end
        else
          if math.abs(e) <= 0.00000001 then
            tex.print [[0^\circ]]
          else
            prinTeX(e * 180 / PI, '\\degree', '')
          end
        end

        tex.sprint '\\\\'
      end
    end,

    printUcalcDegMM = function()
      local U = v.Ucalc

      for i = 1, 8 do
        local e = U[i][1]

        if i % 2 == 1 then
          if math.abs(e) <= 0.000001 then
            tex.print [[0 \, \mathrm{mm}]]
          else
            prinTeX(e * 1000, 'mm', '')
          end
        else
          if math.abs(e) <= 0.00000001 then
            tex.print [[0^\circ]]
          else
            prinTeX(e * 180 / PI, '\\degree', '')
          end
        end

        tex.sprint '\\\\'
      end
    end,

    -- Other matrix printing functions
    printK = function(mult)
      printMatrix(v.K, 1, mult)
    end,
    printKkond = function()
      printMatrix(v.Kkond)
    end,
    printKinv = function()
      printMatrix(v.Kinv)
    end,
    printUcalc = function()
      printMatrix(v.Ucalc)
    end,
    printUkond = function()
      printMatrix(v.Ukond)
    end,
    printF = function()
      printMatrix(v.F)
    end,
    printFkond = function()
      printMatrix(v.Fkond, 1, 1)
    end,
    printFcalc = function()
      printMatrix(v.Fcalc)
    end,
    printFreacc = function()
      printMatrix(v.Freacc, 1)
    end,
    xd = function()
      printMatrix(v.xcalc)
    end,
  }
end
