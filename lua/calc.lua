local getData = require 'lua.data'
local matrix = require 'lua.matrix'

local PI = math.pi

local Kef = function(I, E, L)
  local M = {
    { 12, 6 * L, -12, 6 * L },
    { 6 * L, 4 * L ^ 2, -6 * L, 2 * L ^ 2 },
    { -12, -6 * L, 12, -6 * L },
    { 6 * L, 2 * L ^ 2, -6 * L, 4 * L ^ 2 },
  }

  for i = 1, 4 do
    for j = 1, 4 do
      M[i][j] = M[i][j] * I * E / L ^ 3
    end
  end

  return M
end

return function(config)
  local D = getData(config.code)
  D.name = config.name
  D.neptun = config.neptun

  local d = D.d
  local E = D.E

  local F_t = D.F_t
  local M_t = D.M_t
  local p_t = D.p_t

  local a = D.a
  local b = D.b
  local c = D.c

  local figure = D.parametric

  -- Beam diameters
  local d_1 = d
  local d_2 = 2 * d

  -- Beam elastic moduli
  local E_1 = 4 * E
  local E_2 = 4

  -- Beam areas
  local A_1 = d_1 ^ 2 * PI / 4
  local A_2 = d_2 ^ 2 * PI / 4

  -- Beam moments of inertia
  local I_1 = d_1 ^ 4 * PI / 64
  local I_2 = d_2 ^ 4 * PI / 64

  -- Params in matrix form
  local LMat = { a, b - a, c - b }
  local dMat = {}
  local EMat = {}
  local AMat = {}
  local IMat = {}

  for i = 1, 3 do
    dMat[i] = d * figure.beams[i]['value']
    EMat[i] = 4 * E * (1 / figure.beams[i]['value']) ^ 2
    AMat[i] = dMat[i] ^ 2 * PI / 4
    IMat[i] = dMat[i] ^ 4 * PI / 64
  end

  -- Elem - Csomopont
  local ecs = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
  }

  -- Elem DOF
  local eDOF = {
    { 1, 2, 3, 4 },
    { 3, 4, 5, 6 },
    { 5, 6, 7, 8 },
  }

  -- Elem merevsegi
  local Ke = {}
  for i = 1, 3 do
    Ke[i] = Kef(IMat[i], EMat[i], LMat[i])
  end

  -- Globalis merevsegi
  local K = matrix.zeros(8, 8)
  for i = 1, 3 do
    K = matrix.addMatrices(K, matrix.extMatrix(Ke[i], eDOF[i], 8))
  end

  local M = {
    d_1 = d_1,
    d_2 = d_2,
    E_1 = E_1,
    E_2 = E_2,
    A_1 = A_1,
    A_2 = A_2,
    I_1 = I_1,
    I_2 = I_2,

    LMat = LMat,
    dMat = dMat,
    EMat = EMat,
    AMat = AMat,
    IMat = IMat,

    ecs = ecs,
    eDOF = eDOF,

    Ke = Ke,
    K = K,
  }

  for k, v in pairs(M) do
    D[k] = v
  end
  return D
end
