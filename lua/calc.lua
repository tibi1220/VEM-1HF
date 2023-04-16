local getData = require 'lua.data'
local matrix = require 'lua.matrix'

local PI = math.pi

local function Kef(I, E, L)
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

local function getV(L, a, Ue)
  N = {
    [0] = {
      1 - 3 * a ^ 2 / L ^ 2 - 2 * a ^ 3 / L ^ 3,
      -a - 2 * a ^ 2 / L - a ^ 3 / L ^ 2,
      3 * a ^ 2 / L ^ 2 + 2 * a ^ 3 / L ^ 3,
      -a ^ 2 / L - a ^ 3 / L ^ 2,
    },
    [1] = {
      6 * a / L ^ 2 + 6 * a ^ 2 / L ^ 3,
      1 + 4 * a / L + 3 * a ^ 2 / L ^ 2,
      -6 * a / L ^ 2 - 6 * a ^ 2 / L ^ 3,
      2 * a / L + 3 * a ^ 2 / L ^ 2,
    },
    [2] = {
      -3 / L ^ 2 - 6 * a / L ^ 3,
      -2 / L - 3 * a / L ^ 2,
      3 / L ^ 2 + 6 * a / L ^ 3,
      -1 / L - 3 * a / L ^ 2,
    },
    [3] = {
      2 / L ^ 3,
      1 / L ^ 2,
      -2 / L ^ 3,
      1 / L ^ 2,
    },
  }

  local polinomial = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 }

  for i = 0, 3 do
    for j = 1, 4 do
      polinomial[i] = polinomial[i] + Ue[j][1] * N[i][j]
    end
  end

  return polinomial
end

local function getPhi(v)
  return {
    [0] = v[1],
    [1] = 2 * v[2],
    [2] = 3 * v[3],
  }
end

local function getMh(phi, I, E)
  return {
    [0] = -I * E * phi[1],
    [1] = -2 * I * E * phi[2],
  }
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

  -- Globalis erok
  local F = matrix.zeros(8, 1)
  local t
  -- Add F
  t = figure.forces.F * 2 - 1
  F[t][1] = -F_t * D.code[5]

  -- Add M
  t = figure.forces.M * 2
  F[t][1] = M_t

  -- Add p
  for i = 1, 3 do
    t = figure.forces.p[i]
    local q = t * p_t * LMat[i] / 2

    F[i * 2 - 1][1] = F[i * 2 - 1][1] + q
    F[i * 2 + 0][1] = F[i * 2 + 0][1] + q * LMat[i] / 6
    F[i * 2 + 1][1] = F[i * 2 + 1][1] + q
    F[i * 2 + 2][1] = F[i * 2 + 2][1] - q * LMat[i] / 6
  end

  -- Globalis elmozdulas
  local U = matrix.zeros(8, 1)

  -- Szabad szabadsagi fokok
  local szabadDOF = figure.free

  -- Kondenzalt merevsegi
  local Kkond = matrix.subMatrix(K, szabadDOF)

  -- Kondenzalt ero
  local Fkond = matrix.subVector(F, szabadDOF)

  local inverted =
    matrix.invertMatrix(matrix.addMatrices(Kkond, matrix.zeros(5, 5)))

  -- Kondenzalt elmozdulas
  local Ukond = matrix.multiplyMatrices(inverted, Fkond)

  -- Szamitott elmozdulas
  local Ucalc = matrix.extVector(Ukond, szabadDOF, 8)

  -- Szamitott ero
  local Fcalc = matrix.zeros(8, 1)
  local Freacc = matrix.zeros(8, 1)

  for i = 1, 8 do
    for j = 1, 8 do
      Fcalc[i][1] = Fcalc[i][1] + K[j][i] * Ucalc[j][1]
    end

    Freacc[i][1] = Fcalc[i][1] - F[i][1]
  end

  -- Elem elmozdulas
  local Ue = {}
  local Fe = {}
  local vMat = {}
  local phiMat = {}
  local MhMat = {}

  for i = 1, 3 do
    Ue[i] = matrix.subVector(Ucalc, eDOF[i])
    Fe[i] = matrix.zeros(4, 1)
    vMat[i] = getV(LMat[i], ({ 0, a, b })[i], Ue[i])
    phiMat[i] = getPhi(vMat[i])
    MhMat[i] = getMh(phiMat[i], IMat[i], EMat[i])

    for j = 1, 4 do
      for k = 1, 4 do
        Fe[i][j][1] = Fe[i][j][1] + Ke[i][j][k] * Ue[i][k][1]
      end
    end
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
    Fe = Fe,
    Ue = Ue,

    K = K,
    F = F,
    U = U,

    Kkond = Kkond,
    Fkond = Fkond,
    Ukond = Ukond,

    Fcalc = Fcalc,
    Ucalc = Ucalc,
    Kinv = inverted,

    Freacc = Freacc,

    vMat = vMat,
    phiMat = phiMat,
    MhMat = MhMat,
  }

  for k, v in pairs(M) do
    D[k] = v
  end
  return D
end
