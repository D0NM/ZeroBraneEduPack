require("wx")
require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")
local com = require("common")

io.stdout:setvbuf("no")

local logStatus = com.logStatus
local  W,  H = 400, 400
local dX, dY = 1,1
local xySize = 3
local greyLevel  = 200
local minX, maxX = -20, 20
local minY, maxY = -20, 20
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clOrg = colr(col.getColorBlueRGB())
local clRel = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clMgn = colr(col.getColorMagenRGB())

local function drawCoordinateSystem(w, h, dx, dy, mx, my)
  local xe, ye = 0, 0
  for x = 0, mx, dx do
    local xp = intX:Convert( x):getValue()
    local xm = intX:Convert(-x):getValue()
    if(x == 0) then xe = xp
    else  pncl(clGry); line(xp, 0, xp, h); line(xm, 0, xm, h) end
  end
  for y = 0, my, dx do
    local yp = intY:Convert( y):getValue()
    local ym = intY:Convert(-y):getValue()
    if(y == 0) then ye = yp
    else  pncl(clGry); line(0, yp, w, yp); line(0, ym, w, ym) end
  end; pncl(clBlk)
  line(xe, 0, xe, h); line(0, ye, w, ye)
end

local function drawComplex(C, Cl)
  local x = intX:Convert(C:getReal()):getValue()
  local y = intY:Convert(C:getImag()):getValue()
  pncl(Cl); rect(x-xySize,y-xySize,2*xySize+1,2*xySize+1)
end

local function drawComplexLine(S, E, Cl)
  local x1 = intX:Convert(S:getReal()):getValue()
  local y1 = intY:Convert(S:getImag()):getValue()
  local x2 = intX:Convert(E:getReal()):getValue()
  local y2 = intY:Convert(E:getImag()):getValue()
  pncl(Cl); line(x1, y1, x2, y2)
end

cmp.Draw("xy", drawComplex)
cmp.Draw("ab", drawComplexLine)

logStatus("Create a primary line to project on using the left mouse button (BLUE)")
logStatus("Create a point to project on the line using the right mouse button (RED)")
logStatus("By clicking on the chart the point selected will be drawn")
logStatus("On the coordinate system the OX and OY axises are drawn in black")
logStatus("The distance between every grey line on X is: "..tostring(dX))
logStatus("The distance between every grey line on Y is: "..tostring(dY))
logStatus("Press escape to clear all rays and refresh the coordinate system")

open("Complex point projection demo")
size(W,H)
zero(0, 0)
updt(false) -- disable auto updates

drawCoordinateSystem(W, H, dX, dY, maxX, maxY)

cRay1, cPnt, drw = {}, cmp.New(), false

while true do
  wait(0.2)
  local key = char()
  local lx, ly = clck('ld')
  local rx, ry = clck('rd')
  if(lx and ly and #cRay1 < 2) then -- Reverse the interval conversion polarity
    lx = intX:Convert(lx,true):getValue() -- It helps by converting x,y from positive integers to the interval above
    ly = intY:Convert(ly,true):getValue() 
    local C = cmp.New(lx, ly)
    cRay1[#cRay1+1] = C; C:Draw("xy", clOrg)
    if(#cRay1 == 2) then cRay1[1]:Draw("ab", cRay1[2], clOrg); drw = true end
  elseif(drw and rx and ry) then -- Reverse the interval and convert x, y image position to a complex
    rx = intX:Convert(rx,true):getValue() 
    ry = intY:Convert(ry,true):getValue(); cPnt:Set(rx, ry)
    local XX = cPnt:getProj(cRay1[1], cRay1[2])
    XX:Draw("xy", clMgn); cPnt:Draw("xy", clRel); cPnt:Draw("ab", XX, clMgn)
    local bSegm = XX:isAmong(cRay1[1], cRay1[2], 1e-10)
    logStatus("The complex projection "..tostring(XX).." is "..(bSegm and "ON" or "OFF").." the line"); drw = false
  end
  if(key == 27) then -- The user hits esc
    wipe(); drw = true -- Wipe all the drawing and redraw the coordinate system
    cRay1[1], cRay1[2] = nil, nil; collectgarbage()
    drawCoordinateSystem(W, H, dX, dY, maxX, maxY)
  end
  updt()
end

wait();
