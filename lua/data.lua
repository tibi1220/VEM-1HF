local data = {
  figure = {
    {
      code = 1,
      thin = { b = 'o', e = 'a', d = 1, E = 4 },
      thick = { b = 'a', e = 'c', d = 2, E = 1 },
      F_t = 'b',
      M_t = 'a',
      p_t = { b = 'o', e = 'b', s = 1, l = 'l' },
      connections = {
        { l = 'a', o = 's', dof = 1 },
        { l = 'c', o = 'e', dof = 3 },
      },
      beams = {
        { number = 1, value = 1 },
        { number = 2, value = 2 },
        { number = 3, value = 2 },
      },
      forces = {
        F = 3,
        M = 2,
        p = { 1, 1, 0 },
      },
      free = { 1, 2, 4, 5, 6 },
      notFree = { 3, 7, 8 },
    },
    {
      code = 2,
      thin = { b = 'b', e = 'c', d = 1, E = 4 },
      thick = { b = 'o', e = 'b', d = 2, E = 1 },
      F_t = 'o',
      M_t = 'b',
      p_t = { b = 'a', e = 'c', s = 2, l = 'l' },
      connections = {
        { l = 'a', o = 's', dof = 1 },
        { l = 'c', o = 'e', dof = 3 },
      },
      beams = {
        { number = 1, value = 2 },
        { number = 2, value = 2 },
        { number = 3, value = 1 },
      },
      forces = {
        F = 1,
        M = 3,
        p = { 0, 1, 1 },
      },
      free = { 1, 2, 4, 5, 6 },
      notFree = { 3, 7, 8 },
    },
    {
      code = 3,
      thin = { b = 'o', e = 'b', d = 1, E = 4 },
      thick = { b = 'b', e = 'c', d = 2, E = 1 },
      F_t = 'b',
      M_t = 'a',
      p_t = { b = 'a', e = 'c', s = 1, l = 'r' },
      connections = {
        { l = 'o', o = 's', dof = 2 },
        { l = 'a', o = 's', dof = 1 },
        { l = 'c', o = 's', dof = 1 },
      },
      beams = {
        { number = 1, value = 1 },
        { number = 2, value = 1 },
        { number = 3, value = 2 },
      },
      forces = {
        F = 3,
        M = 2,
        p = { 0, 1, 1 },
      },
      free = { 2, 4, 5, 6, 8 },
      notFree = { 1, 3, 7 },
    },
    {
      code = 4,
      thin = { b = 'a', e = 'c', d = 1, E = 4 },
      thick = { b = 'o', e = 'a', d = 2, E = 1 },
      F_t = 'a',
      M_t = 'b',
      p_t = { b = 'o', e = 'b', s = 2, l = 'l', a = { 1, 1, 0 } },
      connections = {
        { l = 'o', o = 's', dof = 2 },
        { l = 'b', o = 's', dof = 1 },
        { l = 'c', o = 's', dof = 1 },
      },
      beams = {
        { number = 1, value = 2 },
        { number = 2, value = 1 },
        { number = 3, value = 1 },
      },
      forces = {
        F = 2,
        M = 3,
        p = { 1, 1, 0 },
      },
      free = { 2, 3, 4, 6, 8 },
      notFree = { 1, 5, 7 },
    },
  },

  -- B
  E = { 50, 40, 30, 20 }, -- GPa
  d = { 23, 27, 31, 35 }, -- mm

  -- C
  a = { 220, 230, 430, 330, 370, 290, 350, 270 }, -- mm
  b = { 540, 460, 550, 440, 580, 540, 710, 530 }, -- mm
  c = { 730, 610, 890, 680, 780, 810, 890, 830 }, -- mm

  -- D
  p_t = { 2500, -2500, 3000, -3000, 3500, -3500, -4000, 4000 }, -- N/m
  F_t = { 4, -3, 2, -1, 1, -2, 3, -4 }, -- kN
  M_t = { 0.6, -0.75, 0.9, -1.1, 1.2, -0.7, 0.85, -0.6 }, -- kNm
}

return function(code)
  return {
    -- A
    setupFigure = function(self)
      local i = code[1]
      local f = data.figure[i]
      self.figure = {
        code = code[1],
        thin = {
          b = self[f.thin.b], -- begin
          e = self[f.thin.e], -- end
          d = self.d * f.thin.d, -- diameter
          E = self.E * f.thin.E, -- elastic modulus
        },
        thick = {
          b = self[f.thick.b],
          e = self[f.thick.e],
          d = self.d * f.thick.d,
          E = self.E * f.thick.E,
        },
        F_t = self[f.F_t], -- location
        M_t = self[f.M_t], -- location
        p_t = {
          b = self[f.p_t.b], -- begin
          e = self[f.p_t.e], -- end
        },
        connections = {},
      }

      for key, value in pairs(f.connections) do
        self.figure.connections[key] = {
          l = self[value.l], -- location
          o = self[value.o], -- orientation s(outh), e(ast)
          dof = self[value.dof], -- type
        }
      end
    end,

    parametric = data.figure[code[1]],

    -- B
    E = data.E[code[2]] * 1e9,
    d = data.d[code[2]] / 1000,

    -- C
    a = data.a[code[3]] / 1000,
    b = data.b[code[3]] / 1000,
    c = data.c[code[3]] / 1000,
    o = 0, -- origin

    -- D
    p_t = data.p_t[code[4]],
    F_t = data.F_t[code[4]] * 1000,
    M_t = data.M_t[code[4]] * 1000,

    -- Code information
    code = code,
  }
end
