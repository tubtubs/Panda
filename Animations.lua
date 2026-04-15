--Example code from PizzaSauceDemos (https://codeberg.org/Pizzahawaii/PizzaSauceDemos)
local J = PizzaSauce

--Helpers/Registered Types copied from demos
-- =============================================================================
-- "ballistic" type: Physics-based projectile trajectory
-- =============================================================================
--
-- Moves a frame along a parabolic arc using kinematic equations:
--   x(t) = x0 + vx * elapsed
--   y(t) = y0 + vy * elapsed - 0.5 * gravity * elapsed^2
--
-- The tween's `from` is the starting {x, y} position. The trajectory is
-- controlled by three extra parameters passed via the opts table:
--   vx      -- horizontal velocity (pixels/second)
--   vy      -- vertical velocity (pixels/second, positive = up)
--   gravity -- downward acceleration (pixels/second^2)
--
-- These are accessible inside the type handler at tween._opts because the
-- Tween constructor stores the full opts table there.
--
-- IMPORTANT: This type MUST use easing = "linear" because it calculates
-- position from raw elapsed time (t * duration). Any non-linear easing would
-- distort the physics -- e.g., inOutQuad would make particles start slow,
-- accelerate, then slow down, instead of following a natural parabola.
--
-- Example (raw Tween):
--   J:Tween(frame, {
--     type = "ballistic", from = {0, 100}, duration = 2.5, easing = "linear",
--     vx = 200, vy = 300, gravity = 350,
--   })
--
-- Example (convenience function):
--   J:Ballistic(frame, {0, 100}, 2.5, 200, 300, 350)

J:RegisterType("ballistic", {
  init = function(target, from, to, tween)
    local point, rel, relPoint, x, y = target:GetPoint(1)
    tween._point = point or "CENTER"
    tween._rel = rel
    tween._relPoint = relPoint or "CENTER"
    return from or { x or 0, y or 0 }
  end,
  apply = function(target, from, to, t, tween)
    local elapsed = t * tween._duration
    local x = from[1] + tween.vx * elapsed
    local y = from[2] + tween.vy * elapsed - 0.5 * tween.gravity * elapsed * elapsed
    target:ClearAllPoints()
    target:SetPoint(tween._point, tween._rel, tween._relPoint, x, y)
  end,
})

-- Forces linear easing since the physics math expects raw elapsed time.
J:RegisterHelper("Ballistic", function(self, target, from, duration, vx, vy, gravity, o)
  o = o or {}
  return self:Tween(target, {
    type = "ballistic", from = from, duration = duration, easing = "linear",
    vx = vx, vy = vy, gravity = gravity,
    delay = o.delay, onStart = o.onStart, onFinish = o.onFinish,
    onCancel = o.onCancel, defer = o.defer,
  })
end)

---- ** Blackhole ** ----
-- init -- 
-- Register the spiral type (global, persists for addon lifetime)
J:RegisterType("spiral", {
  init = function(target, from, to, tween)
    local point, rel, relPoint, x, y = target:GetPoint(1)
    tween._point = point or "CENTER"
    tween._rel = rel
    tween._relPoint = relPoint or "CENTER"
    return from or 0
  end,
  apply = function(target, from, to, t, tween)
    local r = tween.radius * (1 - t)
    local angle = tween.startAngle + tween.rotations * 2 * math.pi * t
    local x = tween.cx + math.cos(angle) * r
    local y = tween.cy + math.sin(angle) * r
    target:ClearAllPoints()
    target:SetPoint(tween._point, tween._rel, tween._relPoint, x, y)
  end,
})

J:RegisterHelper("Spiral", function(self, target, duration, cx, cy, radius, startAngle, rotations, easing, o)
  if type(easing) == "table" then o = easing; easing = nil end
  o = o or {}
  return self:Tween(target, {
    type = "spiral", from = 0, to = 1,
    duration = duration, easing = easing,
    cx = cx, cy = cy, radius = radius,
    startAngle = startAngle, rotations = rotations,
    delay = o.delay, onStart = o.onStart, onFinish = o.onFinish, onCancel = o.onCancel, defer = o.defer,
  })
end)

local NUM_PARTICLES = 60
local CENTER_X, CENTER_Y = 0, 100

-- Particle colors: purples, blues, and whites (accretion disk palette)
local holeColors = {
    {0.6, 0.3, 1},   -- purple
    {0.4, 0.2, 0.9}, -- dark purple
    {0.3, 0.5, 1},   -- blue
    {0.7, 0.5, 1},   -- lavender
    {0.8, 0, 1},        -- pink (hot inner particles)
    {0.8, 0.6, 1},   -- pink-purple
}

local particles = {}
local particles_txt = {}
for i = 1, NUM_PARTICLES do
    local pf = CreateFrame("Frame", nil, UIParent)
    local s = 2 + math.random() * 4
    pf:SetWidth(s)
    pf:SetHeight(s)
    pf:SetFrameStrata("HIGH")
    pf:SetPoint("CENTER", UIParent, "CENTER", CENTER_X, CENTER_Y)

    local tex = pf:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    local c = holeColors[math.mod(i - 1, table.getn(holeColors)) + 1]
    local vary = 0.8 + math.random() * 0.4
    tex:SetTexture(
        math.min(c[1] * vary, 1),
        math.min(c[2] * vary, 1),
        math.min(c[3] * vary, 1), 1)

    pf:Hide()
    particles[i] = pf
    particles_txt[i] = tex
end
-- Center "singularity" -- a dark circle
local singularity = CreateFrame("Frame", nil, UIParent)
singularity:SetWidth(12)
singularity:SetHeight(12)
singularity:SetFrameStrata("HIGH")
singularity:SetPoint("CENTER", UIParent, "CENTER", CENTER_X, CENTER_Y)
local singTex = singularity:CreateTexture(nil, "ARTWORK")
singTex:SetAllPoints()
singTex:SetTexture(0.05, 0.02, 0.1, 1)
singularity:Hide()

function Panda_BlackholeStart(targetFrame)
    --Panda_BlackholeStop()
    -- Move to target frame
    singularity:SetPoint("CENTER", targetFrame, "CENTER")
    --CENTER_X, CENTER_Y = targetFrame:GetCenter()
    CENTER_X = targetFrame:GetLeft()
    CENTER_Y = targetFrame:GetTop()
    for i = 1, NUM_PARTICLES do
        J:Stop(particles[i])
        local s = 2 + math.random() * 4
        particles[i]:SetWidth(s)
        particles[i]:SetHeight(s)
        particles[i]:ClearAllPoints()
        particles[i]:SetPoint("CENTER", targetFrame)
        local c = holeColors[math.mod(i - 1, table.getn(holeColors)) + 1]
        local vary = 0.8 + math.random() * 0.4
        tex = particles_txt[i]
        tex:SetTexture(
            math.min(c[1] * vary, 1),
            math.min(c[2] * vary, 1),
            math.min(c[3] * vary, 1), 1)
    end
    --CENTER_X = 
    --CENTER_Y =
    --J:Pulse(singularity, 1.2, 2.0, { loop = 0 })

    -- Show singularity with a subtle pulse
    --singularity:Show()

    -- Launch particles from random positions around the ring
    local anims = {}
    --DEFAULT_CHAT_FRAME:AddMessage(format("X: %s Y: %s", CENTER_X, CENTER_Y))

    for i = 1, NUM_PARTICLES do
        local pf = particles[i]
        local startAngle = math.random() * 2 * math.pi
        local radius = 10 + math.random() * 120
        local rotations = 1.5 + math.random() * 2.5
        --local dur = 2.0 + math.random() * 2.0
        local dur = 3.0
        --local delay = math.random() * 3.0
        local delay = math.random() * 0.25

        -- Position at starting point on the ring
        local sx = CENTER_X + math.cos(startAngle) * radius
        local sy = CENTER_Y + math.sin(startAngle) * radius
        pf:ClearAllPoints()
        pf:SetPoint("CENTER", targetFrame, "CENTER")
        table.insert(anims, J:Sequence({
            J:Delay(delay),
            J:Group({
                -- Spiral inward with acceleration (inQuad = gravitational pull feel)
                J:Tween(pf, {
                    type = "spiral", from = 0, to = 1,
                    target = targetFrame,
                    duration = dur, easing = "inQuad",
                    cx = 0, cy = 0,
                    radius = radius, startAngle = startAngle,
                    rotations = rotations,
                    onStart = function() pf:SetAlpha(1); pf:Show() end,
                }),
                -- Shrink as it approaches center
                J:Tween(pf, {
                    type = "size", from = {pf:GetWidth(), pf:GetHeight()}, to = {1, 1},
                    duration = dur, easing = "inQuad",
                }),
                -- Fade out near the end
                J:FadeTo(pf, 0, dur * 0.3, "inQuad", { delay = dur * 0.7 }),
            }),
        }))
    end

    J:Group(anims)
end

function Panda_BlackholeStop(targetFrame)
    J:Stop(anims)
    -- want to make them fall down a bit before hiding
    local fallingAnims = {}
  local gravity = 350
    for i = 1, NUM_PARTICLES do
        local dur =  math.random() * 0.3    
        pf = particles[i] 
        x = pf:GetLeft()
        y = pf:GetTop()
        tex = particles_txt[i]
        x , y = pf:GetCenter()

        tex:SetTexture(
            math.min(.92-(0.2*math.random())),
            math.min(.98-(0.1*math.random())),
            math.min(.44-(0.1*math.random())), 1)
        J:Sequence({
            --J:Ballistic(pf, { x, y }, 3, 0, 0, 300, {
            --onFinish = function() pf:Hide() end,
            --}),
            J:SlideOut(pf, "DOWN", 300, 0.5)
        })
    end
end

---- ** Shatter ** ---- 
-- init -- 
local GRID = 8
local NUM_FRAGMENTS = GRID * GRID
local ICON_SIZE = 64
local FRAG_SIZE = ICON_SIZE / GRID  -- 8px per fragment
local fragments = {}
local fragments_txt = {}

for row = 0, GRID - 1 do
    for col = 0, GRID - 1 do
        local idx = row * GRID + col + 1
        local ff = CreateFrame("Frame", nil, UIParent)
        ff:SetWidth(FRAG_SIZE)
        ff:SetHeight(FRAG_SIZE)
        ff:SetFrameStrata("HIGH")
        ff:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

        local ftex = ff:CreateTexture(nil, "ARTWORK")
        ftex:SetAllPoints()
        ftex:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt")
        -- Map this fragment to its portion of the icon (accounting for border crop)
        local uMin, uMax = 0.07, 0.93
        local uRange = uMax - uMin
        local left = uMin + (col / GRID) * uRange
        local right = uMin + ((col + 1) / GRID) * uRange
        local top = uMin + (row / GRID) * uRange
        local bot = uMin + ((row + 1) / GRID) * uRange
        ftex:SetTexCoord(left, right, top, bot)

        ff:Hide()
        fragments_txt[idx] = ftex
        fragments[idx] = ff
    end
end

function Panda_Shatter(targetFrame, targetIcon, text)
    for row = 0, GRID - 1 do
        for col = 0, GRID - 1 do
        local idx = row * GRID + col + 1
        ff = fragments[idx] 
        ff:SetWidth(FRAG_SIZE)
        ff:SetHeight(FRAG_SIZE)
        ff:SetFrameStrata("HIGH")
        ff:SetPoint("CENTER", targetFrame, "CENTER", 0, 0)
        local ftex = fragments_txt[idx]
        ftex:SetAllPoints()
        ftex:SetTexture(text)
        -- Map this fragment to its portion of the icon (accounting for border crop)
        local uMin, uMax = 0.07, 0.93
        local uRange = uMax - uMin
        local left = uMin + (col / GRID) * uRange
        local right = uMin + ((col + 1) / GRID) * uRange
        local top = uMin + (row / GRID) * uRange
        local bot = uMin + ((row + 1) / GRID) * uRange
        ftex:SetTexCoord(left, right, top, bot)

        ff:Hide()
        fragments[idx] = ff
        end
    end
    -- Pre-build fragment animations as direct Sequence children instead of
    -- launching from an onFinish callback. This avoids a timing issue where
    -- animations created inside callbacks on the very first run after reload
    -- don't start properly.
    local cx, cy = 0, 0 
    local fragmentAnims = {}

    for row = 0, GRID - 1 do
        for col = 0, GRID - 1 do
        local idx = row * GRID + col + 1
        local ff = fragments[idx]

        -- Position fragment at its grid location relative to icon center
        local fx = cx + (col - GRID / 2 + 0.5) * FRAG_SIZE
        local fy = cy + ((GRID - 1 - row) - GRID / 2 + 0.5) * FRAG_SIZE

        ff:ClearAllPoints()
        ff:SetPoint("CENTER", targetFrame, "CENTER")

        -- Velocity: outward from center with some randomness
        local dirX = (col - GRID / 2 + 0.5) * 30 + (math.random() - 0.5) * 60
        local dirY = ((GRID - 1 - row) - GRID / 2 + 0.5) * 30 + math.random() * 80
        local dur = 1.5 + math.random() * 0.5

        table.insert(fragmentAnims, J:Group({
            J:Ballistic(ff, {fx, fy}, dur, dirX, dirY, 250, {
            onStart = function() ff:SetAlpha(1); ff:Show() end,
            }),
            J:FadeTo(ff, 0, 0.4, "inQuad", { delay = dur - 0.4 }),
        }))
        end
    end

    -- One unified Sequence: fade in → hold → hide icon → explode fragments
    J:Sequence({
        J:Delay(3.0),
        J:Tween(targetFrame, {
            type = "alpha", from = 1, to = 0, duration = 0.05,
            onFinish = function() targetFrame:Hide() end,
        }),
        J:Group(fragmentAnims),
    })
end

function Panda_ShatterReset(targetIcon)
    J:Stop(targetIcon)
    --targetIcon:Hide()
    --targetIcon:SetAlpha(1)
    --targetIcon:ClearAllPoints()
    --targetIcon:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

    for i = 1, NUM_FRAGMENTS do
        J:Stop(fragments[i])
        fragments[i]:Hide()
        --fragments[i]:SetAlpha(1)
        fragments[i]:ClearAllPoints()
        fragments[i]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end