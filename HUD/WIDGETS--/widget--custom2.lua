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
--MM = string ("CRUISE" / "TRAVEL" / "PLATFORM" / "DRONE")
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
--pitchInput    = num (-1 / 0 / 1)
--rollInput     = num (-1 / 0 / 1)
--yawInput      = num (-1 / 0 / 1)
--brakeInput    = num (-1 / 0 / 1)
--strafeInput   = num (-1 / 0 / 1)
--upInput       = num (-1 / 0 / 1)
--forwardInput  = num (-1 / 0 / 1)
--boosterInput  = num (-1 / 0 / 1)

utils = require("cpml/utils")

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
    self.title = nil
    self.name = "AR DAMAGE REPORT--" -- name of the widget
    self.SVGSize = {x=self.width,y=self.height} -- size of the window to fit the svg, in pixels
    self.pos = {x=0, y=0}
    self.class = "widgets"  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = false  --allow widget to be dragged
    self.fixed = true  --prevent widget from going over others
    
    self.showFullHp = false
    self.elementsId = {}
    self.elementsLocalPos = {}
    self:loadElements()
    return self
end

function WidgetsPlusPlusCustom.getSize(self) --returns the svg size
    return self.SVGSize
end

function WidgetsPlusPlusCustom.getName(self) --returns the widget name
    return self.name
end

function WidgetsPlusPlusCustom.getTitle(self) --returns the widget name
    return self.title
end

function WidgetsPlusPlusCustom.getPos(self) --returns the widget pos
    return self.pos
end

function WidgetsPlusPlusCustom.getButtons(self) --returns buttons list
    return self.buttons
end

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return nil
end

function WidgetsPlusPlusCustom.loadElements(self)
    self.elementsId = self.core.getElementIdList()
    for i, v in ipairs(self.elementsId) do
        self.elementsLocalPos[i] = self.core.getElementPositionById(v)
    end
end


local function round(num, numDecimalPlaces) -- http://lua-users.org/wiki/SimpleRound
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end            
local function hexToRGB(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end
local function RGBToHex(r,g,b)
    r,g,b = round(r),round(g),round(b)
    return string.format("#%02x%02x%02x",r,g,b)
end
local function lerp(a,b,t)
    return a + (b - a) * t
end
local function colorGradient(a,b,t) --Returns gradiant T of a and b hex color
    local ar, ag, ab = hexToRGB(a)
    local br, bg, bb = hexToRGB(b)
    return RGBToHex(lerp(ar,br,t), lerp(ag,bg,t), lerp(ab,bb,t))
end


--------------------
-- CUSTOM BUTTONS --
--------------------
--[[
local button_function = function() system.print("Hello world!") end
self.buttons = {
                {button_text = "TEXT", button_function = button_function, class = nil, width = 0, height = 0, posX = 0, posY = 0},   -- class = "separator"   (for invisible background button)
                }
]]

----------------
-- WIDGET SVG --
----------------
local sqrt, tan, rad, format, concat = math.sqrt, math.tan, math.rad, string.format, table.concat

function WidgetsPlusPlusCustom.SVG_Update(self)
    local debug = false --turn on/off debug printing
    if debug then DUSystem.print("section: 0") end
    local sw = self.width
    local sh = self.height
    local vFov = self.vFov
    local near = 0.1
    local far = 100000000.0
    local aspectRatio = sh/sw
    local tanFov = 1.0/tan(rad(vFov)*0.5)
    local field = -far/(far-near)
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

    if debug then DUSystem.print("section: 10") end
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local cWOU = DUConstruct.getWorldOrientationUp()
    local cWOUx, cWOUy, cWOUz = cWOU[1], cWOU[2], cWOU[3]
    local cWOF = DUConstruct.getWorldOrientationForward()
    local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3]
    local cWOR = DUConstruct.getWorldOrientationRight()
    local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3]
    local mPP = self.player.getPosition()
    local mPPx, mPPy = mPP[1], mPP[2]

    if debug then DUSystem.print("section: 20") end
    local posX, posY, posZ = 0, 0, 0
    local vx, vy, vz = 0, 0, 0
    local sx, sy, sz = 0, 0, 0
    local sPX, sPY = 0,0
    local dist = 0

    if debug then DUSystem.print("section: 30") end
    local function projection2D()
        -- matrix resolution
        vx = posX * camWRx + posY * camWRy + posZ * camWRz
        vy = posX * camWFx + posY * camWFy + posZ * camWFz
        vz = posX * camWUx + posY * camWUy + posZ * camWUz
        -- 2D projection
        sx = (af * vx)/vy
        sy = ( -tanFov * vz)/vy
        sz = ( -field * vy + nq)/vy
        sPX, sPY = (sx+1)*sw*0.5, (sy+1)*sh*0.5 -- screen pos X Y
        dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
    end

    if debug then DUSystem.print("section: 40") end
    local x = 0
    local y = 0
    local z = 0
    local vxyz = {}
    local vx = 0
    local vy = 0
    local vz = 0
    local textHeight = 0
    local elementsPos = {}

    if debug then DUSystem.print("section: 50") end
    for i, v in ipairs(self.elementsLocalPos) do
        vxyz = v
        vx,vy,vz = vxyz[1], vxyz[2], vxyz[3]+ textHeight
        x = vx * cWORx + vy * cWOFx + vz * cWOUx + cWPx
        y = vx * cWORy + vy * cWOFy + vz * cWOUy + cWPy
        z = vx * cWORz + vy * cWOFz + vz * cWOUz + cWPz
        elementsPos[i] = {x=x,y=y,z=z}
    end

    if debug then DUSystem.print("section: 60") end
    local SVG = [[<style>
                svg {
                }
                </style><div>
                <svg viewBox="0 0 ]].. sw ..[[ ]].. sh ..[[" style="
                    position:absolute;
                    top:0px;
                    left:0px;
                    filter: drop-shadow(1px 1px 0px black) drop-shadow(0px 0px 3px black);
                ">]]
                

    --Markers
    ----------
    if debug then DUSystem.print("section: 80") end
    local t = ""
    local style = "labelWhite"
    local fs = 50
    local svgT = {}
    local ind = 0
    local n1, n2, n3 = 0, 0, 0

    if debug then DUSystem.print("section: 90") end
    for i, v in ipairs(elementsPos) do
        --if debug then DUSystem.print("section: 91") end
        posX = v.x - camWPx
        posY = v.y - camWPy
        posZ = v.z - camWPz
        projection2D()
        if sz < 1 and sPX > 0 and sPX < sw and sPY > 0  and sPY < sh then
            --if debug then DUSystem.print("section: 92") end

            -- set local variables --
            local id = self.elementsId[i]
            local itemId = self.core.getElementItemIdById(id)
            local maxHP = self.core.getElementMaxHitPointsById(id); maxHP = maxHP > 0 and maxHP or 0
            local HP = self.core.getElementHitPointsById(id); HP = HP > 0 and HP or 0


            -- lives left --
            life = ""
            maxLives = self.core.getElementMaxRestorationsById(id)
            lives = self.core.getElementRestorationsById(id)
            if lives < maxLives then
                life = ' ['..lives..'/'..maxLives..']'
            end
            coreUnit = itemId == 1417952990 or itemId == 1418170469 or itemId == 183890525 or itemId == 183890713 and 1 or 0

            if HP < maxHP or self.showFullHp == true or (lives == 0 and coreUnit == 0) then
                local item = DUSystem.getItem(itemId)
                --DUSystem.print(Data:serialize(item))
                local name = item.locDisplayNameWithSize

                local color = colorGradient("#FF4400","#FFFF44",HP/maxHP)
                if HP >= maxHP then color = "#FFFFFF" -- max health
                elseif HP <= 0 then color = "#BB0000" end -- dead

                --local distAdjustment = utils.clamp(maxHP/10000,0,2)
                --local sF = 0.7 + ((1 / (dist-distAdjustment)) * 4)-- * (fs + maxHP / 1000)) --scaleFactor
                local sF = 0.7 + ((1 / dist) * (4 + utils.clamp(maxHP/1000,0,6)))-- * (fs + maxHP / 1000)) --scaleFactor

                -- name and pointer
                ind = ind +1
                svgT[ind] = [[
                    <circle style="opacity:0.8;fill:none;stroke:]]..color..[[;stroke-width:]]..(1*sF)..[[;stroke-miterlimit:]]..(1*sF)..[[;" cx="]]..sPX..[[" cy="]]..sPY..[[" r="]]..(10*sF)..[[" />
                    <polyline style="opacity:0.8;fill:none;stroke:]]..color..[[;stroke-width:]]..(1*sF)..[[;stroke-miterlimit:]]..(1*sF)..[[;" points="]]..sPX-(10*sF)..[[,]]..sPY-(10*sF)..[[ ]]..sPX-(20*sF)..[[,]]..sPY-(20*sF)..[[ ]]..sPX-(50*sF)..[[,]]..sPY-(20*sF)..[["/>
                    <text text-anchor="end" alignment-baseline="bottom" x="]]..sPX-(25*sF)..[[" y="]]..sPY-(22*sF)..[[" style="font-size:]]..11*sF..[[px;fill:]]..color..[[">]]..name..life..[[</text>
                ]]

                -- health indicator
                if HP > 0 then
                    local E=HP/maxHP*359.99
                    local F=1
                    if E<180 then F=0 end
                    ind = ind +1
                    svgT[ind] = [[
                        <path style="opacity:0.8;fill:none;stroke:]]..color..[[;stroke-width:]]..(3*sF)..[[;stroke-miterlimit:1;" d="M ]]..sPX+(7*sF)*math.cos((0-90)*math.pi/180)..[[ ]]..sPY+(7*sF)*math.sin((0-90)*math.pi/180)..[[ A ]]..(7*sF)..[[ ]]..(7*sF)..[[ 0 ]]..F..[[ 1 ]]..sPX+(7*sF)*math.cos((E-90)*math.pi/180)..[[ ]]..sPY+(7*sF)*math.sin((E-90)*math.pi/180)..[["/>
                    ]]
                else
                    ind = ind +1
                    svgT[ind] = [[
                        <polyline style="opacity:0.8;fill:none;stroke:]]..color..[[;stroke-width:]]..(3*sF)..[[;stroke-miterlimit:1;" points="]]..sPX-(6*sF)..[[,]]..sPY-(6*sF)..[[ ]]..sPX+(6*sF)..[[,]]..sPY+(6*sF)..[["/>
                        <polyline style="opacity:0.8;fill:none;stroke:]]..color..[[;stroke-width:]]..(3*sF)..[[;stroke-miterlimit:1;" points="]]..sPX+(6*sF)..[[,]]..sPY-(6*sF)..[[ ]]..sPX-(6*sF)..[[,]]..sPY+(6*sF)..[["/>
                    ]]
                end
            end


        end
    end
    --if debug then DUSystem.print("section: 100") end
    SVG = SVG .. concat(svgT)

    --SVG = SVG..'<rect x="1" y="1" width="'.. sw-1 ..'" height="'.. sh-1 ..'" style="fill:none;stroke:red;stroke-width:2"'
    --DUSystem.print("svg="..SVG)

    if debug then DUSystem.print("section: end") end
    return SVG..'</svg></div>'

end
