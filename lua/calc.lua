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

local function getTheta(w)
  return {
    [0] = w[1],
    [1] = 2 * w[2],
    [2] = 3 * w[3],
    [3] = 4 * w[4],
  }
end

local function getMh(phi, I, E)
  return {
    [0] = -I * E * phi[1],
    [1] = -2 * I * E * phi[2],
  }
end

local function getM(theta, I, E)
  return {
    [0] = -I * E * theta[1],
    [1] = -2 * I * E * theta[2],
    [2] = -3 * I * E * theta[3],
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
  local E_v1 = 4 * E
  local E_v2 = 4

  -- Beam areas
  local A_1 = d_1 ^ 2 * PI / 4
  local A_2 = d_2 ^ 2 * PI / 4

  -- Beam moments of inertia
  local I_v1 = d_1 ^ 4 * PI / 64
  local I_v2 = d_2 ^ 4 * PI / 64

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

  -- Sziltan
  local F_1 = 0
  local F_2 = 0
  local F_3 = F_t
  local M_2 = M_t
  local M_3 = 0
  local p_1 = p_t
  local p_2 = p_t
  local p_3 = 0
  local l_1 = LMat[1]
  local l_2 = LMat[2]
  local l_3 = LMat[3]
  local I_1 = IMat[1]
  local I_2 = IMat[2]
  local I_3 = IMat[3]
  local E_1 = EMat[1]
  local E_2 = EMat[2]
  local E_3 = EMat[3]
  local rIE1 = 1 / I_1 / E_1
  local rIE2 = 1 / I_2 / E_2
  local rIE3 = 1 / I_3 / E_3

  local xParam = {
    { 'F_O' },
    { 'F_A' },
    { 'F_B' },
    { 'F_C' },
    { 'M_C' },
    { 'C_{11}' },
    { 'C_{12}' },
    { 'C_{21}' },
    { 'C_{22}' },
    { 'C_{31}' },
    { 'C_{32}' },
  }

  local A = {
    { 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 }, -- 3
    { a ^ 3 / 6, 0, 0, 0, 0, a, 1, 0, 0, 0, 0 }, -- 4
    { 0, 0, 0, -b ^ 3 / 6 + b ^ 2 * c / 2, b ^ 2 / 2, 0, 0, 0, 0, b, 1 }, -- 5
    { 0, 0, 0, -c ^ 3 / 6 + c ^ 3 / 2, c ^ 2 / 2, 0, 0, 0, 0, c, 1 }, -- 6
    { 0, 0, 0, -c ^ 2 / 2 + c ^ 2, c, 0, 0, 0, 0, 1, 0 }, -- 7
    { 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 }, -- 1
    { 0, a, b, c, 1, 0, 0, 0, 0, 0, 0 }, -- 2
    {
      rIE1 * a ^ 2 / 2 - rIE2 * a ^ 2 / 2,
      rIE2 * (a ^ 2 - a ^ 2 / 2),
      0,
      0,
      0,
      rIE1,
      0,
      -rIE2,
      0,
      0,
      0,
    }, -- 8
    {
      -rIE2 * b ^ 2 / 2,
      rIE2 * (b * a - b ^ 2 / 2),
      0,
      rIE3 * (-b ^ 2 / 2 + b * c),
      rIE3 * b,
      0,
      0,
      -rIE2,
      0,
      rIE3,
      0,
    }, -- 9
    {
      rIE1 * a ^ 3 / 6 - rIE2 * a ^ 3 / 6,
      rIE2 * (a ^ 3 / 2 - a ^ 3 / 6),
      0,
      0,
      0,
      a * rIE1,
      rIE1,
      -a * rIE2,
      -rIE2,
      0,
      0,
    }, -- 10
    {
      -rIE2 * b ^ 3 / 6,
      rIE2 * (b ^ 2 * a / 2 - b ^ 3 / 6),
      0,
      rIE3 * (b ^ 2 * c / 2 - b ^ 3 / 6),
      rIE3 * b ^ 2 / 2,
      0,
      0,
      -rIE2 * b,
      -rIE2,
      rIE3 * b,
      rIE3,
    }, -- 11
  }

  local bVec = {
    { 0 }, -- 3
    { F_1 * a ^ 3 / 6 + p_1 * a ^ 4 / 24 }, -- 4
    { p_3 * (b ^ 4 / 24 - b ^ 3 * c / 6 - b ^ 2 * c ^ 2 / 4) }, -- 5
    { p_3 * (c ^ 4 / 24 - c ^ 4 / 6 - c ^ 4 / 4) }, -- 6
    { p_3 * (c ^ 3 / 6 - c ^ 3 / 2 - c ^ 3 / 2) }, -- 7
    { F_1 + F_2 + F_3 + p_1 * l_1 + p_2 * l_2 + p_3 * l_3 }, -- 1
    {
      -M_2
        - M_3
        + a * F_2
        + b * F_3
        + p_1 * l_1 * l_1 / 2
        + p_2 * l_2 * (l_1 + l_2 / 2)
        + p_3 * l_3 * (l_1 + l_2 + l_3 / 3),
    }, -- 2
    {
      rIE1 * (F_1 * a ^ 2 / 2 + p_1 * a ^ 3 / 6)
        + rIE2
          * (-a ^ 3 * p_2 / 6 + a ^ 2 / 2 * (-F_1 - F_2 - p_1 * l_1 + p_2 * a) + a * (F_2 * a - M_2 + (p_1 * l_1 * a - p_2 * a ^ 2) / 2)),
    }, -- 8
    {
      rIE3 * (b ^ 3 * p_3 / 6 - b ^ 2 * c * p_3 / 2 - b * c ^ 2 * p_3 / 2)
        + rIE2
          * (-b ^ 3 * p_2 / 6 + b ^ 2 / 2 * (-F_1 - F_2 - p_1 * l_1 + p_2 * a) + b * (F_2 * a - M_2 + (p_1 * l_1 * a - p_2 * a ^ 2) / 2)),
    }, -- 9
    {
      rIE1 * (F_1 * a ^ 3 / 6 + a ^ 4 * p_1 / 24)
        + rIE2
          * (-a ^ 4 * p_2 / 24 + a ^ 3 * (-F_1 - F_2 - p_1 * l_1 + p_2 * a) / 6 + a ^ 2 * (F_2 * a / 2 - M_2 / 2 + (p_1 * l_1 * a - p_2 * a ^ 2) / 4)),
    }, -- 10
    {
      rIE3 * (b ^ 4 / 24 * p_3 - b ^ 3 * c / 6 * p_3 - b ^ 2 * c ^ 2 / 4 * p_3)
        + rIE2
          * (-b ^ 4 * p_2 / 24 + b ^ 3 * (-F_1 - F_2 - p_1 * l_1 + p_2 * a) / 6 + b ^ 2 * (F_2 * a / 2 - M_2 / 2 + (p_1 * l_1 * a - p_2 * a ^ 2) / 4)),
    }, -- 11
  }

  -- Delete eqs: 3, 5
  -- Delete variables: 1 3
  local free = { 2, 4, 5, 6, 7, 8, 9, 10, 11 }

  local Akond = matrix.subMatrix(A, free)
  local xParamkond = matrix.subVector(xParam, free)
  local bkond = matrix.subVector(bVec, free)

  local Ai = matrix.inversion(Akond)

  local xkond = matrix.multiplyMatrices(Ai, bkond)

  local xcalc = matrix.extVector(xkond, free, 11)

  local F_O = xcalc[1][1]
  local F_A = xcalc[2][1]
  local F_B = xcalc[3][1]
  local F_C = xcalc[4][1]
  local M_C = xcalc[5][1]
  local C_11 = xcalc[6][1]
  local C_12 = xcalc[7][1]
  local C_21 = xcalc[8][1]
  local C_22 = xcalc[9][1]
  local C_31 = xcalc[10][1]
  local C_32 = xcalc[11][1]

  local wMat = {
    {
      [4] = rIE1 * (-p_1 / 24),
      [3] = rIE1 * (F_O - F_1) / 6,
      [2] = 0,
      [1] = rIE1 * C_11,
      [0] = rIE1 * C_12,
    },
    {
      [4] = rIE2 * (-p_2 / 24),
      [3] = rIE2 * (-F_1 + F_O - F_2 + F_A - p_1 * l_1 + p_2 * a) / 6,
      [2] = rIE2
        * ((F_2 * a - F_A * a - M_2) / 2 + (p_1 * l_1 * a - p_2 * a ^ 2) / 4),
      [1] = rIE2 * C_21,
      [0] = rIE2 * C_22,
    },
    {
      [4] = rIE3 * (-p_3 / 24),
      [3] = rIE3 * (-F_C / 6 + c * p_3 / 6),
      [2] = rIE3 * (M_C / 2 + F_C * c / 2 + c ^ 2 * p_3 / 4),
      [1] = rIE1 * C_31,
      [0] = rIE1 * C_32,
    },
  }

  local thetaMat = {}
  local MMat = {}
  for i = 1, 3 do
    thetaMat[i] = getTheta(wMat[i])
    MMat[i] = getM(thetaMat[i], IMat[i], EMat[i])
  end

  local M = {
    d_1 = d_1,
    d_2 = d_2,
    E_1 = E_v1,
    E_2 = E_v2,
    A_1 = A_1,
    A_2 = A_2,
    I_1 = I_v1,
    I_2 = I_v2,

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

    -- Sziltan
    xParam = xParam,
    A = A,
    bVec = bVec,
    xParamkond = xParamkond,
    xkond = xkond,
    bkond = bkond,
    Ai = Ai,
    Akond = Akond,
    xcalc = xcalc,

    wMat = wMat,
    thetaMat = thetaMat,
    MMat = MMat,
  }

  for k, v in pairs(M) do
    D[k] = v
  end
  return D
end
