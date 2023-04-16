local M = {}

-- This function creates a 2D matrix (list of lists) filled with zeros.
-- @param rows (number) The number of rows in the matrix.
-- @param cols (number) The number of columns in the matrix.
-- @return matrix (table) The created matrix filled with zeros.
local function zeros(rows, cols)
  local matrix = {}

  for i = 1, rows do
    matrix[i] = {}
    for j = 1, cols do
      matrix[i][j] = 0
    end
  end

  return matrix
end

-- Creates a sub-matrix from a given matrix, based on the specified rows.
-- @param Mx (table) The input matrix to extract the sub-matrix from.
-- @param rows (table) A table containing the row indices to include in the sub-matrix.
-- @return mx (table) The sub-matrix created from the specified rows.
M.subMatrix = function(Mx, rows)
  local n = #rows
  local mx = zeros(n, n)

  for i = 1, n do
    for j = 1, n do
      mx[i][j] = Mx[rows[i]][rows[j]]
    end
  end

  return mx
end

-- Extends a given sub-matrix to create a larger matrix with specified rows and size.
-- @param mx (table) The sub-matrix to extend.
-- @param rows (table) A table containing the row indices in the original sub-matrix.
-- @param size (number) The size of the new matrix to create.
-- @return Mx (table) The extended matrix with specified rows and size.
M.extMatrix = function(mx, rows, size)
  local n = #rows
  local Mx = zeros(size, size)

  for i = 1, n do
    for j = 1, n do
      Mx[rows[i]][rows[j]] = mx[i][j]
    end
  end

  return Mx
end

-- Creates a sub-vector from a given vector (1-column matrix), based on the specified rows.
-- @param Vec (table) The input vector to extract the sub-vector from.
-- @param rows (table) A table containing the row indices to include in the sub-vector.
-- @return vec (table) The sub-vector created from the specified rows.
M.subVector = function(Vec, rows)
  local n = #rows
  local vec = zeros(n, 1)

  for i = 1, n do
    vec[i][1] = Vec[rows[i]][1]
  end

  return vec
end

-- Extends a given sub-vector to create a larger vector with specified rows and size.
-- @param vec (table) The sub-vector to extend.
-- @param rows (table) A table containing the row indices in the original sub-vector.
-- @param size (number) The size of the new vector to create.
-- @return Vec (table) The extended vector with specified rows and size.
M.extVector = function(vec, rows, size)
  local n = #rows
  local Vec = zeros(size, 1)

  for i = 1, n do
    Vec[rows[i]][1] = vec[i][1]
  end

  return Vec
end

-- Function to add two matrices
-- @param matrix1 table: The first matrix represented as a 2D array
-- @param matrix2 table: The second matrix represented as a 2D array
-- @return table: The sum of the two matrices as a new matrix
M.addMatrices = function(matrix1, matrix2)
  local rows = #matrix1
  local cols = #matrix1[1]
  local result = {}

  -- Check if the matrices have the same dimensions
  if rows ~= #matrix2 or cols ~= #matrix2[1] then
    error 'Matrix dimensions must be the same for addition'
  end

  -- Iterate through each element in the matrices and add them
  for i = 1, rows do
    result[i] = {}
    for j = 1, cols do
      result[i][j] = matrix1[i][j] + matrix2[i][j]
    end
  end

  return result
end

-- Function to invert a square matrix
-- @param matrix table: The input matrix represented as a square 2D array
-- @return table: The inverted matrix as a new matrix
M.invertMatrix = function(matrix)
  local n = #matrix
  local result = {}

  -- Check if the matrix is square
  if n ~= #matrix[1] then
    error 'Input matrix must be square for inversion'
  end

  -- Create an identity matrix of the same size as the input matrix
  local identity = {}
  for i = 1, n do
    identity[i] = {}
    for j = 1, n do
      identity[i][j] = i == j and 1 or 0
    end
  end

  -- Perform Gaussian elimination to obtain the inverse
  for j = 1, n do
    for i = 1, n do
      if i == j then
        local div = matrix[i][j]
        for k = 1, n do
          matrix[i][k] = matrix[i][k] / div
          identity[i][k] = identity[i][k] / div
        end
      else
        local factor = matrix[i][j] / matrix[j][j]
        for k = 1, n do
          matrix[i][k] = matrix[i][k] - factor * matrix[j][k]
          identity[i][k] = identity[i][k] - factor * identity[j][k]
        end
      end
    end
  end

  -- Copy the inverted matrix from the identity matrix
  for i = 1, n do
    result[i] = {}
    for j = 1, n do
      result[i][j] = identity[i][j]
    end
  end

  return result
end

-- Function to multiply two matrices
-- @param matrix1 table: The first matrix represented as a 2D array
-- @param matrix2 table: The second matrix represented as a 2D array
-- @return table: The product of the two matrices as a new matrix
M.multiplyMatrices = function(matrix1, matrix2)
  local rows1 = #matrix1
  local cols1 = #matrix1[1]
  local rows2 = #matrix2
  local cols2 = #matrix2[1]
  local result = {}

  -- Check if the number of columns in the first matrix
  -- is equal to the number of rows in the second matrix
  if cols1 ~= rows2 then
    error 'Number of columns in matrix1 must be equal to number of rows in matrix2 for multiplication'
  end

  -- Initialize the result matrix with zeros
  for i = 1, rows1 do
    result[i] = {}
    for j = 1, cols2 do
      result[i][j] = 0
    end
  end

  -- Perform matrix multiplication
  for i = 1, rows1 do
    for j = 1, cols2 do
      for k = 1, cols1 do
        result[i][j] = result[i][j] + matrix1[i][k] * matrix2[k][j]
      end
    end
  end

  return result
end

-- Helper function to calculate the sign of a cofactor
local function cofactorSign(i)
  return i % 2 == 0 and -1 or 1
end

-- Helper function to get the submatrix of a matrix by removing a row and column
local function submatrix(matrix, row, col)
  local sub = {}
  for i = 1, #matrix do
    if i ~= row then
      local rowValues = {}
      for j = 1, #matrix[i] do
        if j ~= col then
          table.insert(rowValues, matrix[i][j])
        end
      end
      table.insert(sub, rowValues)
    end
  end
  return sub
end

M.determinant = function(matrix)
  -- Get the number of rows and columns in the matrix
  local numRows = #matrix
  local numCols = #matrix[1]

  -- Check if the matrix is square
  if numRows ~= numCols then
    print 'Error: Matrix is not square'
    return nil
  end

  -- Base case: 2x2 matrix
  if numRows == 2 and numCols == 2 then
    return matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]
  end

  -- Initialize determinant value
  local det = 0

  -- Laplace expansion
  for i = 1, numRows do
    local cofactor = matrix[1][i]
      * cofactorSign(i)
      * M.determinant(submatrix(matrix, 1, i))
    det = det + cofactor
  end

  return det
end

-- Function to multiply a matrix with a scalar
M.multiplyMatrixWithScalar = function(matrix, scalar)
  -- Create a new matrix to store the result
  local result = {}

  -- Iterate through each row in the matrix
  for i = 1, #matrix do
    local row = {}
    -- Iterate through each element in the row
    for j = 1, #matrix[i] do
      -- Multiply the element with the scalar
      local product = matrix[i][j] * scalar
      -- Add the product to the row
      table.insert(row, product)
    end
    -- Add the row to the result matrix
    table.insert(result, row)
  end

  -- Return the result matrix
  return result
end

local function matrixMinor(m, i, j)
  local minor = {}
  local n = #m
  local row, col = 1, 1

  for k = 1, n do
    if k ~= i then
      col = 1
      minor[row] = {}
      for l = 1, n do
        if l ~= j then
          minor[row][col] = m[k][l]
          col = col + 1
        end
      end
      row = row + 1
    end
  end

  return minor
end

local function matrixDeterminant(m)
  local n = #m
  if n == 1 then
    return m[1][1]
  end

  local det = 0
  for j = 1, n do
    local sign = ((1 + j) % 2 == 0) and 1 or -1
    local minor = matrixMinor(m, 1, j)
    det = det + sign * m[1][j] * matrixDeterminant(minor)
  end

  return det
end

M.inversion = function(m)
  -- Calculate the determinant of the matrix
  local det = matrixDeterminant(m)
  if det == 0 then
    error 'Matrix is singular and cannot be inverted'
  end

  local n = #m
  local adj = {}

  -- Calculate the adjugate matrix
  for i = 1, n do
    adj[i] = {}
    for j = 1, n do
      local sign = ((i + j) % 2 == 0) and 1 or -1
      adj[i][j] = sign * matrixDeterminant(matrixMinor(m, i, j))
    end
  end

  -- Calculate the inverse of the matrix
  local inv = {}
  for i = 1, n do
    inv[i] = {}
    for j = 1, n do
      inv[i][j] = adj[j][i] / det
    end
  end

  return inv
end

M.zeros = zeros

return M
