require("turtle")
local common   = require("common")
local complex  = require("complex")
local chartmap = require("chartmap")
local signals  = require("signals")

local ws = 50                -- Signal frequency
local fs = 2500              -- Sampling rate
local et = 1/10              -- End time (seconds)
local es = et * fs           -- Total samples
local pr = 1 / fs            -- Time per sample
local w = (2 * math.pi * ws) -- Signal angular frequency
local s, t, i = {}, {}, 1    -- Arry containing samples and time
for d = 0, et, pr do
  t[i] = d
  s[i] = math.sin(w * t[i])
  i = i + 1
end

local W, H = 1000, 600
local intX  = chartmap.New("interval","WinX", 0, et, 0, W)
local intY  = chartmap.New("interval","WinY", -1, 1, H, 0)

local crSys = chartmap.New("coordsys"):setInterval(intX, intY):setBorder()
      crSys:setSize():setColor():setDelta(et / 10, 0.1)

open("Sine plotter")
size(W, H); zero(0, 0)
updt(false) -- disable auto updates

crSys:Draw(true, false, true)
crSys:drawGraph(t, s)


wait()
