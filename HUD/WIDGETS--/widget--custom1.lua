--DEFAULT-- windows colors variables:
--------------------------------------
--P.MS.TITLE_COLOR.value
--P.MS.TITLE_COLOR_A.value
--P.MS.TITLE_TEXT_COLOR.value
--P.MS.WN_COLOR.value
--P.MS.WN_COLOR_A.value
--P.MS.WN_TEXT_COLOR.value
--P.MS.BUTTON_COLOR.value
--P.MS.BUTTON_BORDER_COLOR.value
--P.MS.BUTTON_COLOR_A.value
--P.MS.BUTTON_TEXT_COLOR.value
--P.MS.WIDGET_TEXT_COLOR.value
--P.MS.WIDGET_ANIM_COLOR.value
--P.MS.WIDGET_FIXED_COLOR.value

--DEFAULT-- updated variables:
-------------------------------
--currentTime = num
--inspace = 0 in atmo 1 in space
--xSpeedKPH = num kmph
--ySpeedKPH = num kmph
--zSpeedKPH = num kmph
--xyzSpeedKPH = num kmph
--Az = drift rot angle in deg
--Ax = drift pitch angle in deg
--Ax0 = pitch angle in deg
--Ay0 = roll angle in deg
--ThrottlePos = num
--MM = string ("CRUISE" / "TRAVEL" / "PARKING" / "DRONE")
--closestPlanetIndex = num (planet index for Helios library)
--atmofueltank = JSON
--spacefueltank = JSON
--rocketfueltank = JSON
--fueltanks = table (all fueltanks JSON data)
--fueltanks_size = num (total number of fuel tanks)

--DEFAULT-- keybind variables:
-------------------------------
--CLICK = bool
--CTRL = bool
--ALT = bool
--SHIFT = bool
--mwCLICK = bool
--GEAR = bool
--pitchInput = num (-1 / 0 / 1)
--rollInput = num (-1 / 0 / 1)
--yawInput = num (-1 / 0 / 1)
--brakeInput = num (-1 / 0 / 1)
--strafeInput = num (-1 / 0 / 1)
--upInput = num (-1 / 0 / 1)
--forwardInput = num (-1 / 0 / 1)
--boosterInput = num (-1 / 0 / 1)
local delay = 0
local widget_font = "Play"
local utils = require("cpml/utils")
local BookmarksPOI = require "autoconf.custom.WIDGETS--.BookmarksPOI"
local BookmarksCustoms = require "autoconf.custom.WIDGETS--.BookmarksCustoms"

local interactablePOIS = {}
local otherPOIS = {}
local ind = 0
for k, planet in pairs(Helios) do
    ind = ind + 1
    interactablePOIS[ind] = planet
end

for i, poi in ipairs(BookmarksPOI) do
    if poi.bodyId ~= 0 then
        otherPOIS[#otherPOIS+1] = poi
    else
        ind = ind + 1
        interactablePOIS[ind] = poi
    end
end
for i, poi in ipairs(BookmarksCustoms) do
    if poi.bodyId ~= 0 then
        otherPOIS[#otherPOIS+1] = poi
    else
        ind = ind + 1
        interactablePOIS[ind] = poi
    end
end

ind = ind + 1
interactablePOIS[ind] = {id = 999, center = {0,0,0}, name = {"Safe Zone"}, radius = 100000, type = {"SZ"}}

ind = ind + 1
interactablePOIS[ind] = {id = 9999, center = {0,0,0}, name = {"Closest Safe Zone"}, radius = 100000, type = {"SZ"}}


local entriesTotNum = ind

local moon_distance = 20  -- SU
moon_distance = moon_distance * 200 * 1000

WidgetsPlusPlusCustom = {}
WidgetsPlusPlusCustom.__index = WidgetsPlusPlusCustom

function WidgetsPlusPlusCustom.new(core, unit, DB, antigrav, warpdrive, shield, switch, player, telemeter)
    local self = setmetatable({}, WidgetsPlusPlusCustom)
    self.core = core
    self.unit = unit
    self.DB = DB
    self.antigrav = antigrav
    self.warpdrive = warpdrive
    self.shield = shield
    self.switch = switch
    self.player = player
    self.telemeter = telemeter
    
    self.buttons = {} -- list of buttons to be implemented in widget
    
    self.width = DUSystem.getScreenWidth()
    self.height = DUSystem.getScreenHeight()
    self.vFov = DUSystem.getCameraVerticalFov()
    self.hFov = DUSystem.getCameraHorizontalFov()
    self.name = 'SOLAR SYSTEM--' -- name of the widget
    self.SVGSize = {x=self.width,y=self.height} -- size of the window to fit the svg, in pixels
    self.pos = {x=0, y=0}
    self.class = 'widgets'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = false  --allow widget to be dragged
    self.fixed = true  --prevent widget from going over others
    self.title = nil
    self.scale = 1
    return self
end

function WidgetsPlusPlusCustom.getSize(self) --returns the svg size
    return self.SVGSize
end

function WidgetsPlusPlusCustom.getScale(self) --returns the svg Scale
    return self.scale
end

function WidgetsPlusPlusCustom.getName(self) --returns the widget name
    return self.name
end

function WidgetsPlusPlusCustom.getTitle(self) --returns the widget name
    return self.title
end

function WidgetsPlusPlusCustom.getPos(self) --returns the widget name
    return self.pos
end

function WidgetsPlusPlusCustom.getButtons(self) --returns buttons list
    return self.buttons
end

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return nil
end

--function WidgetsPlusPlusCustom.loadData(self)
--    self.modeOn = Data:getData("DM_droneMode") ~= nil and Data:getData("DM_droneMode") or false
--end
--
--function WidgetsPlusPlusCustom.saveData(self)
--    if Data then
--        Data:setData("DM_droneMode",self.modeOn)
--    end
--end

--function WidgetsPlusPlusCustom.onActionStart(self, action) -- uncomment to receive pressed key
--    --DUSystem.print(action)
--end

-- function WidgetsPlusPlusCustom.onActionStop(self, action) -- uncomment to receive released key
--      --DUSystem.print(action)
-- end

-- function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive pressed key
--      --DUSystem.print(action)
-- end

----------------
-- WIDGET SVG --
----------------
local sqrt, tan, rad, atan, format, clamp, concat = math.sqrt, math.tan, math.rad, math.atan, string.format, utils.clamp, table.concat

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end


local function intersectVecSphere(posx,posy,posz, dirx,diry,dirz, centerx,centery,centerz, radius)
    local t = 200000000
    if vectorLen(posx-centerx,posy-centery,posz-centerz) < radius then
        posx,posy,posz = posx+dirx*t,posy+diry*t,posz+dirz*t
        dirx,diry,dirz = -dirx,-diry,-dirz
    end
    local offsetx,offsetxy,offsetxz = posx-centerx,posy-centery,posz-centerz --ray.position - sphere.position
    local b = dotVec(offsetx,offsetxy,offsetxz,dirx,diry,dirz) --offset:dot(ray.direction)
    local c = dotVec(offsetx,offsetxy,offsetxz,offsetx,offsetxy,offsetxz) - radius * radius --offset:dot(offset) - sphere.radius * sphere.radius
    if c > 0 and b > 0 then
        return false
    end
    local discr = b * b - c
    if discr < 0 then
        return false
    end
    t = -b - sqrt(discr)
    t = t < 0 and 0 or t
    return {posx+dirx*t,posy+diry*t,posz+dirz*t}, t--ray.position + ray.direction * t, t
end


function WidgetsPlusPlusCustom.SVG_Update(self)
    delay = delay + 1 <= 60 and delay + 1 or 60
    if delay >= 60 then
        local WTC = P.MS.wTC.value --WIDGET_TEXT_COLOR
        local BBC = P.MS.BBC.value --BUTTON_BORDER_COLOR
        local BC = P.MS.BC.value --BUTTON_COLOR
        local WC = P.MS.WC.value --WN_COLOR
        local AC = P.MS.wAC.value --WIDGET_ANIM_COLOR
        local FC = P.MS.WFC.value --WIDGET_FIXED_COLOR
    
        local deg2px = self.height / self.vFov
        local near = 0.1
        local far = 100000000.0
        local aspectRatio = self.height / self.width
        local tanFov = 1.0 / tan(rad(self.vFov) * 0.5)
        local field = -far / (far - near)
        local af = aspectRatio*tanFov
        local nq = near*field
        local camWP = DUSystem.getCameraWorldPos()
        local camWPx, camWPy, camWPz = camWP[1], camWP[2], camWP[3]
        local camWF = DUSystem.getCameraWorldForward()
        local camWFx, camWFy, camWFz = camWF[1], camWF[2], camWF[3]
        local camWR = DUSystem.getCameraWorldRight()
        local camWRx, camWRy, camWRz = camWR[1], camWR[2], camWR[3]
        local camWU = DUSystem.getCameraWorldUp()
        local camWUx, camWUy, camWUz = camWU[1], camWU[2], camWU[3]
    
        local cWP = DUConstruct.getWorldPosition()
        local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
        local cWOU = DUConstruct.getWorldOrientationUp()
        local cWOUx, cWOUy, cWOUz = cWOU[1], cWOU[2], cWOU[3]
        local cWOF = DUConstruct.getWorldOrientationForward()
        local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3]
        local cWOR = DUConstruct.getWorldOrientationRight()
        local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3]
        local cAV = DUConstruct.getWorldVelocity ()
        local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
        local velMag = sqrt(cAVx^2+cAVy^2+cAVz^2)
    
        local posX, posY, posZ = 0, 0, 0
        local vx, vy, vz = 0, 0, 0
        local sx, sy, sz = 0, 0, 0
        local sPX, sPY = 0, 0
        local dist = 0
        local pCx, pCy, pCz = 0, 0, 0
        local posX, posY, posZ = 0, 0, 0
        local pName = ""
        local pRadius = 0
        local pIndex = closestPlanetIndex
        local big = 20
        local little = 14
        local dist_str = ""
        local SVGind = 0
    
        local FIVS = intersectVecSphere(cWPx, cWPy, cWPz, cWOFx, cWOFy, cWOFz, 13856549.3576,7386341.6738,-258459.8925, 18000000) --::pos{0,0,13856549.3576,7386341.6738,-258459.8925} --forward safe zone
        local szcnx, szcny, szcnz = normalizeVec(cWPx-13856549.3576, cWPy-7386341.6738, cWPz+258459.8925)
        --DUSystem.print('CIVS')
        local CIVS = {0,0,0}
        local dist2SZcenter = vectorLen(cWPx-13856549.3576, cWPy-7386341.6738, cWPz+258459.8925)
        if dist2SZcenter < 18000000 then --DUSystem.print('inside')
            local szcnx, szcny, szcnz = normalizeVec(cWPx-13856549.3576, cWPy-7386341.6738, cWPz-258459.8925)
            CIVS = intersectVecSphere(cWPx, cWPy, cWPz, szcnx, szcny, szcnz, 13856549.3576,7386341.6738,-258459.8925, 18000000) -- closest safe zone inside
        else --DUSystem.print('outside')
            local szcnx, szcny, szcnz = normalizeVec(13856549.3576-cWPx, 7386341.6738-cWPy, -258459.8925-cWPz)
            CIVS = intersectVecSphere(cWPx, cWPy, cWPz, szcnx, szcny, szcnz, 13856549.3576,7386341.6738,-258459.8925, 18000000) -- closest safe zone outside
        end
    
        if 1==0 then --P.TP.Destination.value ~= nil and #P.TP.Destination.value == 3 then
            interactablePOIS[entriesTotNum+1] = {center = P.TP.Destination.value, name = {'Destination'}, radius = 1000, type = {'Destination'}}
        else
            interactablePOIS[entriesTotNum+1] = {center = {0,0,0}, name = {" "}, radius = 0, type = {''}}
        end
    
        local function projection2D()
            vx = posX * camWRx + posY * camWRy + posZ * camWRz
            vy = posX * camWFx + posY * camWFy + posZ * camWFz
            vz = posX * camWUx + posY * camWUy + posZ * camWUz
            sx = (af * vx)/vy
            sy = ( -tanFov * vz)/vy
            sz = ( -field * vy + nq)/vy
            sPX, sPY = (sx+1)*self.width*0.5, (sy+1)*self.height*0.5 -- screen pos X Y
            dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
        end
        
        local SVG = {}
        SVGind = SVGind + 1
        SVG[SVGind] = format('<svg style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >', self.width, self.height)
        if ALT == true then
            SVGind = SVGind + 1
            SVG[SVGind] = format('<circle cx="%.1f" cy="%.1f" r="4" stroke="white" stroke-width="2" fill="black" fill-opacity="0.2"/>', self.width/2, self.height/2)  -- Overlay alignment circle
        end
        
        posX = cWOFx*1000000000000 - camWPx
        posY = cWOFy*1000000000000 - camWPy
        posZ = cWOFz*1000000000000 - camWPz
        projection2D()
        SVGind = SVGind + 1
        SVG[SVGind] = format('<text x="%.2f" y="%.2f" font-size="20" text-anchor="middle" font-family="%s" alignment-baseline="middle" fill="%s">╬</text>', sPX, sPY, widget_font, FC)
        
        if velMag > 5 then
            posX = (cAVx)*1000000000000 - camWPx
            posY = (cAVy)*1000000000000 - camWPy
            posZ = (cAVz)*1000000000000 - camWPz
            projection2D()
        end
        SVGind = SVGind + 1
        SVG[SVGind] = format('<text x="%.2f" y="%.2f" font-size="20" text-anchor="middle" font-family="%s" alignment-baseline="middle" fill="%s">┼</text>', sPX, sPY, widget_font, AC)
        
        self.buttons = {}
        for i, entry in ipairs(interactablePOIS) do
            if entry.id == 999 then
                if FIVS == false then
                    goto skip
                else
                    interactablePOIS[i].center = FIVS
                    --DUSystem.print(IVS[1].."/"..IVS[2].."/"..IVS[3].."/"..ivsD)
                end
            elseif entry.id == 9999 then
                if CIVS == false then
                    goto skip
                else
                    interactablePOIS[i].center = CIVS
                    --DUSystem.print(IVS[1].."/"..IVS[2].."/"..IVS[3].."/"..ivsD)
                end
            end
            
            if interactablePOIS[i].center ~= nil and #interactablePOIS[i].center == 3 then
                pCx, pCy, pCz = interactablePOIS[i].center[1], interactablePOIS[i].center[2], interactablePOIS[i].center[3]
            elseif interactablePOIS[i].pos ~= nil and string.sub(interactablePOIS[i].pos,1,6) == '::pos{' then
                pCx, pCy, pCz = convertToWorldCoordinates(interactablePOIS[i].pos)
            end
            pName = entry.name[1]
            pRadius = entry.radius ~= nil and entry.radius or 500
    
            posX = pCx - camWPx
            posY = pCy - camWPy
            posZ = pCz - camWPz
            projection2D()
            
            local destName = pName
            local destPos = {pCx, pCy, pCz}
            local bf = function() return function()
                                    DUSystem.print('Detination locked on: '..destName)
                                    DUSystem.setWaypoint('::pos{0,0,'..pCx..','..pCy..','..pCz..'}')
                                    --P.TP.Destination.value = destPos
                                    windowsShow()
                                    end end
            self.buttons[i] = {"", nil, {name = interactablePOIS[i].name[1], class = 'separator', width = 1, height = 1, posX = -1, posY = -1}}
    
            if sz < 1 and sPX > 0 and sPX < self.width and sPY > 0  and sPY < self.height and (dist > pRadius*5 and entry.type[1] ~= 'SZ' or entry.type[1] == 'SZ' and inspace == 1) then
                local size = entry.type[1] ~= 'SZ' and atan(pRadius/2, dist) * (self.width / tan(rad(self.hFov * 0.5))) or 25
                SVGind = SVGind + 1
                SVG[SVGind] = format('<circle cx=%.2f cy=%.2f r=%.2f stroke=%s stroke-width=%.f fill=%s fill-opacity="0.2"/>', sPX, sPY, size, BBC, 2, WC)
    
                local bsize = size>50 and size or 50
                self.buttons[i][3].width = bsize
                self.buttons[i][3].height = bsize
                self.buttons[i][3].posX = sPX-bsize/2
                self.buttons[i][3].posY = sPY-bsize/2
                self.buttons[i][2] = bf()
    
                if (entry.type[1] == 'Moon' or entry.type[1] == 'Asteroid') and  dist > moon_distance then
                else
                    if dist >= 200000 then
                        dist_str = format('%.2f SU', dist / 200000)
                    elseif dist >= 1000 then
                        dist_str = format('%.1f km', dist / 1000)
                    else
                        dist_str = format('%.1f m', dist)
                    end
                    
                    local offsety = 0
                    local offsetx = 0
                    if entry.type[1] == 'Destination' or pName == 'Sicari' then offsety = -70 end
                    if entry.type[1] == 'SZ' then offsetx = size + 70 offsety = -35 end
                    local fop = 1
                    if alt < 150000 then fop = 0.5 end
                    
                    SVGind = SVGind + 1
                    SVG[SVGind] = format('<text x="%.2f" y="%.2f" style="fill:%s; text-anchor: middle; font-family: Play; fill-opacity:%.1f">', sPX+offsetx, sPY+offsety, WTC, fop)
                                ..format('<tspan x="%.2f" dy="%.2f" style="font-size: %.1f; fill-opacity:%.1f">%s</tspan>', sPX+offsetx, size + big, big, fop, pName)
                                ..format('<tspan x="%.2f" dy="%.2f" style="font-size: %.1f; fill-opacity:%.1f">%s</tspan>', sPX+offsetx, little, little, fop, dist_str)
                                ..'</text>'
                end
            end
            ::skip::
        end
        for i, entry in ipairs(otherPOIS) do
            pCx, pCy, pCz = convertToWorldCoordinates(entry.pos)
            pName = entry.name[1]
            pRadius = 50
    
            posX = pCx - camWPx
            posY = pCy - camWPy
            posZ = pCz - camWPz
            projection2D()
            local fop = 1
    
            if sz < 1 and sPX > 0 and sPX < self.width and sPY > 0  and sPY < self.height and dist < 400000 and pIndex == entry.bodyId then
                local size = atan(pRadius/2, dist) * (self.width / tan(rad(self.hFov * 0.5)))
                if dist > Helios[pIndex].radius/2 then fop = 0.5 end
                if dist > 500 then
                SVGind = SVGind + 1
                SVG[SVGind] = format('<circle cx=%.2f cy=%.2f r=%.2f stroke=%s stroke-width=%.f fill=%s fill-opacity="0.2"/>', sPX, sPY , size, BBC, 2, WC)
                            ..format('<text x="%.2f" y="%.2f" style="fill:%s; stroke-width:none; text-anchor:middle; font-family:Play; fill-opacity:%.1f;">',sPX, sPY,WTC,fop)
                            ..format('<tspan x="%.2f" dy="%.2f" font-size="%.1f">%s</tspan>', sPX, clamp((1 / dist) * size * 500000, 12, 25), clamp((1 / dist) * size * 500000, 12, 25), pName)
                            ..format('<tspan x="%.2f" dy="%.2f" font-size="%.1f">%.1fkm</tspan></text>',sPX, clamp((1 / dist) * size * 250000, 8, 12), clamp((1 / dist) * size * 250000, 8, 12), dist / 1000)
                end
            end
        end
        SVGind = SVGind + 1
        SVG[SVGind] = '</svg>'
        return concat(SVG)
    end
    return ""
end
