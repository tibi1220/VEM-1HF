local V = require 'lua.calc' { code = { 2, 1, 3, 2, 1 }, name = 1, neptun = 2 }
local matrix = require 'lua.matrix'

local det = matrix.determinant(V.Akond)

-- Function to pretty print a matrix with fixed element width
function prettyPrintMatrix(matrix, elementWidth)
  -- Iterate through each row in the matrix
  for i = 1, #matrix do
    -- Iterate through each element in the row
    for j = 1, #matrix[i] do
      -- Convert the element to string
      local elementStr = tostring(matrix[i][j])
      -- Calculate the number of spaces needed to pad the element string
      local padding = elementWidth - #elementStr
      -- Print the element string with padding
      io.write(elementStr)
      for k = 1, padding do
        io.write ' '
      end
      -- Add a tab separator after each element, except for the last element
      if j ~= #matrix[i] then
        io.write '\t'
      end
    end
    -- Print a newline character after each row
    print()
  end
end

print(V.F_1, V.F_2, V.F_3)
print(V.p_1, V.p_2, V.p_3)
print(0, V.M_2, V.M_3)
