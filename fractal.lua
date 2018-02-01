local complex      = require("complex")
local common       = require("common")
local type         = type
local math         = math
local string       = string
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local logStatus    = common.logStatus
local fractal      = {}

local mtPlaneZ     = {}
mtPlaneZ.__type    = "fractal.z-plane"
mtPlaneZ.__index   = mtPlaneZ
local function newPlaneZ(w,h,minw,maxw,minh,maxh,clbrd,bBrdP)
  local imgW , imgH  = w   , h
  local minRe, maxRe = minw, maxw
  local minIm, maxIm = minh, maxh
  local imgCx, imgCy = (imgW / 2), (imgH / 2)
  local reFac = (maxRe-minRe)/(imgW) -- Re units per pixel
  local imFac = (maxIm-minIm)/(imgH) -- Im units per pixel
  local self, frcPalet, frcNames, conKeys, uZoom, brdCl, bbrdP = {}, {}, {}, {}, 1, clbrd, bBrdP
  local uniCr, uniCi = minRe + ((maxRe - minRe) / 2), minIm + ((maxIm - minIm) / 2)
  setmetatable(self,mtPlaneZ)
  function self:SetControlWX(wx)
    conKeys.dirU, conKeys.dirD = (wx["WXK_UP"]   or -1), (wx["WXK_DOWN"]  or -1)
    conKeys.dirL, conKeys.dirR = (wx["WXK_LEFT"] or -1), (wx["WXK_RIGHT"] or -1)
    conKeys.zooP, conKeys.zooM = (wx["wxEVT_LEFT_DOWN"] or -1), (wx["wxEVT_LEFT_DOWN"] or -1)
  end
  function self:GetKey(sKey) return conKeys[tostring(sKey)] end
  function self:SetArea(vminRe, vmaxRe, vminIm, vmaxIm)
    minRe, maxRe = (tonumber(vminRe) or 0), (tonumber(vmaxRe) or 0)
    minIm, maxIm = (tonumber(vminIm) or 0), (tonumber(vmaxIm) or 0)
    uniCr, uniCi = (minRe + (maxRe - minRe) / 2), (minIm + (maxIm - minIm) / 2)
    reFac = (maxRe - minRe) / (imgW) -- Re units per pixel
    imFac = (maxIm - minIm) / (imgH) -- Im units per pixel
  end
  function self:SetCenter(xCen,yCen,sMode)
    local xCen, yCen = tonumber(xCen), tonumber(yCen)
    if(not xCen) then logStatus("PlaneZ.SetCenter: X nan"); return end
    if(not yCen) then logStatus("PlaneZ.SetCenter: Y nan"); return end
    local sMode = tostring(sMode or "IMG")
    logStatus("PlaneZ.Center("..sMode.."): {"..xCen..","..yCen.."}")
    if(sMode == "IMG") then -- Use the win center in pixels
      if(xCen < 0 or xCen > imgW) then logStatus("PlaneZ.SetCenter: X outbound"); return end
      if(yCen < 0 or yCen > imgH) then logStatus("PlaneZ.SetCenter: Y outbound"); return end
      local dxP, dyP = (xCen - imgCx), (yCen - imgCy)
      local dxU, dyU = (reFac  * dxP), (imFac *  dyP)
      logStatus("PlaneZ.Center: DX = "..dxP.." >> "..dxU)
      logStatus("PlaneZ.Center: DY = "..dyP.." >> "..dyU)
      self:SetArea((minRe + dxU), (maxRe + dxU), (minIm + dyU), (maxIm + dyU))
    elseif(sMode == "POS") then -- Use the fractal center
      local disRe = (maxRe - minRe) / 2
      local disIm = (maxIm - minIm) / 2
      self:SetArea((xCen - disRe), (xCen + disRe), (yCen - disIm), (yCen + disIm))
    else logStatus("PlaneZ.SetCenter: Mode <"..sMode.."> missing")
    end
  end
  function self:MoveCenter(dX, dY)
    logStatus("PlaneZ.MoveCenter: {"..dX..","..dY.."}")
    self:SetCenter(imgCx + (tonumber(dX) or 0), imgCy + (tonumber(dY) or 0))
  end
  function self:Zoom(nZoom)
    local nZoom = tonumber(nZoom) or 0
    if(nZoom == 0) then logStatus("PlaneZ.Zoom("..tostring(nZoom).."): Skipped") return end
    local disRe = (maxRe - minRe) / 2
    local disIm = (maxIm - minIm) / 2
    local midRe = minRe + disRe
    local midIm = minIm + disIm
    if(nZoom > 0) then
      uZoom = uZoom * math.abs(nZoom)
      self:SetArea(midRe - disRe / nZoom, midRe + disRe / nZoom,
                   midIm - disIm / nZoom, midIm + disIm / nZoom)
    elseif(nZoom < 0) then
      self:SetArea(midRe + disRe * nZoom, midRe - disRe * nZoom,
                   midIm + disIm * nZoom, midIm - disIm * nZoom)
      uZoom = uZoom / math.abs(nZoom)
    end
  end

  function self:Register(...)
    local tArgs = {...}
    local sMode = tostring(tArgs[1] or "N/A")
    for iNdex = 2, #tArgs, 2 do
      local key = tArgs[iNdex]
      local foo = tArgs[iNdex + 1]
      if(key and foo) then
        if(type(key) ~= "string") then
          logStatus("PlaneZ.Register: Key not string <"..type(key)..">"); return end
        if(type(foo) ~= "function") then
          logStatus("PlaneZ.Register: Unable to register non-function under <"..key..">"); return end
        if    (sMode == "FUNCT") then frcNames[key] = foo
        elseif(sMode == "PALET") then frcPalet[key] = foo
        else logStatus("PlaneZ.Register: Mode <"..sMode.."> skipped for <"..tostring(tArgs[1]).."> !"); return end
      end
    end
  end

  function self:Draw(sName,sPalet,maxItr)
    local maxItr = (tonumber(maxItr) or 0); if(maxItr < 1) then
      logStatus("PlaneZ.Draw: Iteration depth #"..tostring(maxItr).." invalid"); return end
    local r, g, b, iDepth, isInside, nrmZ = 0, 0, 0, 0, true
    local sName, sPalet = tostring(sName), tostring(sPalet)
    local C, Z, R = complex.New(), complex.New(), {}
    logStatus("PlaneZ.Zoom: {"..uZoom.."}")
    logStatus("PlaneZ.Cent: {"..uniCr..","..uniCi.."}")
    logStatus("PlaneZ.Area: {"..minRe..","..maxRe..","..minIm..","..maxIm.."}")
    for y = 0, imgH do -- Row
      if(brdCl) then pncl(brdCl); line(0,y,imgW,y); updt() end
      C:setImag(minIm + y*imFac)
      for x = 0, imgW do -- Col
        if(brdCl and bbrdP) then updt() end
        C:setReal(minRe + x*reFac); Z:Set(C); isInside = true
        for n = 1, maxItr do
          nrmZ = Z:getNorm2()
          if(nrmZ > 4) then iDepth, isInside = n, false; break end
          if(not frcNames[sName]) then
            logStatus("PlaneZ.Draw: Invalid fractal name <"..sName.."> given"); return end
          frcNames[sName](Z, C, R) -- Call the fractal formula
        end; r, g, b = 0, 0, 0
        if(not isInside) then
          if(not frcPalet[sPalet]) then
            logStatus("PlaneZ.Draw: Invalid pallet <"..sPalet.."> given"); return end
          r, g, b = frcPalet[sPalet](Z, C, iDepth, x, y, R) -- Call the fractal coloring
        end
        pncl(colr(r, g, b)); pixl(x,y)
      end
      updt()
    end
  end
  return self
end

local mtTreeY = {}
      mtTreeY.__type  = "fractal.ytree"
      mtTreeY.__index = mtTreeY
local function newTreeY(iMax, clDraw)
  local draw = clDraw
  local self = {Lev = 0, Max = (tonumber(iMax) or 0)}
  if(self.Max <= 0) then return logStatus("YTree depth invalid <"..tostring(self.Max)..">") end
  setmetatable(self, mtTreeY)
  function self:Allocate(tBranch)
    if(not  tBranch.Lev) then tBranch.Lev = self.Lev end
    if(tBranch.Lev == 0) then tBranch.Max = self.Max end
    if(tBranch.Lev < self.Max) then
      tBranch["<"] = {Lev = (tBranch.Lev + 1)}
      tBranch[">"] = {Lev = (tBranch.Lev + 1)}
      self:Allocate(tBranch["<"])
      self:Allocate(tBranch[">"])
    end
  end
  function self:Draw(tBranch, oX, oY, dX, dY, fW, nW)
    if(not draw) then return end
    if(fW and nW) then fW(nW) end
    if(tBranch.Lev < self.Max) then
      pncl(draw); line(oX, oY, oX, oY+dY)
      line(oX, oY+dY, oX-dX, oY+dY+dY); self:Draw(tBranch["<"], oX-dX, oY+dY+dY, dX/2, dY/2, fW, nW)
      line(oX, oY+dY, oX+dX, oY+dY+dY); self:Draw(tBranch[">"], oX+dX, oY+dY+dY, dX/2, dY/2, fW, nW)
    end
  end
  return self
end

function fractal.New(sType, ...)
  local sType = "fractal."..tostring(sType or "")
  if(sType == mtPlaneZ.__type) then return newPlaneZ(...) end
  if(sType == mtTreeY.__type) then return newTreeY(...) end
end

return fractal
