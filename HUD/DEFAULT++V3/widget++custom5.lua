local widget_font = "Play"
local utils = require("cpml/utils")
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
    self.name = 'TARGET VECTOR++' -- name of the widget
    self.SVGSize = {x=self.width,y=self.height} -- size of the window to fit the svg, in pixels
    self.pos = {x=0, y=0}
    self.class = 'widgets'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default++ widget style)
    self.draggable = false  --allow widget to be dragged
    self.fixed = true  --prevent widget from going over others
    self.tittle = nil
    return self
end

function WidgetsPlusPlusCustom.getSize(self) --returns the svg size
    return self.SVGSize
end

function WidgetsPlusPlusCustom.getName(self) --returns the widget name
    return self.name
end

function WidgetsPlusPlusCustom.getTittle(self) --returns the widget name
    return self.tittle
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
--end
--function WidgetsPlusPlusCustom.saveData(self)
--end
--function WidgetsPlusPlusCustom.onActionStart(self, action)
--     --DUSystem.print(action)
--end
--function WidgetsPlusPlusCustom.onActionStop(self, action) -- uncomment to receive released key
--     --DUSystem.print(action)
--end
--function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive pressed key
--     --DUSystem.print(action)
--end

----------------
-- WIDGET SVG --
----------------
local sqrt, rad, atan, format, clamp, concat = math.sqrt, math.rad, math.atan, string.format, utils.clamp, table.concat

--local function dotVec(x1,y1,z1,x2,y2,z2)
--    return x1*x2 + y1*y2 + z1*z2
--end
--
local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end
--
--local function vectorLen(x,y,z)
--    return sqrt(x * x + y * y + z * z)
--end


function WidgetsPlusPlusCustom.SVG_Update(self)
    --DUSystem.print("1")
    local deg2px = self.height / self.vFov
    local near = 0.1
    local far = 100000000.0
    local aspectRatio = self.height / self.width
    local tanFov = 1.0 / math.tan(rad(self.vFov) * 0.5)
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
    --DUSystem.print("2")
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local cWOUP = DUConstruct.getWorldOrientationUp()
    local cWOF = DUConstruct.getWorldOrientationForward()
    local cWOR = DUConstruct.getWorldOrientationRight()
    local cWOUPx, cWOUPy, cWOUPz = cWOUP[1], cWOUP[2], cWOUP[3] --getConstructWorldOrientationUp
    local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3] --getConstructWorldOrientationForward
    local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3] --getConstructWorldOrientationRight
    --DUSystem.print("3")
    local function l2W(ox,oy,oz)
        local x = ox * cWORx + oy * cWOFx + oz * cWOUPx + cWPx
        local y = ox * cWORy + oy * cWOFy + oz * cWOUPy + cWPy
        local z = ox * cWORz + oy * cWOFz + oz * cWOUPz + cWPz
        return x,y,z
    end
    
    local vx, vy, vz = 0, 0, 0
    local sx, sy, sz = 0, 0, 0
    local sPX, sPY = 0, 0
    local dist = 0
    
    local SVGind = 0
    --DUSystem.print("4")
    local function projection2D(posX, posY, posZ)
        posX = posX - camWPx
        posY = posY - camWPy
        posZ = posZ - camWPz
        vx = posX * camWRx + posY * camWRy + posZ * camWRz
        vy = posX * camWFx + posY * camWFy + posZ * camWFz
        vz = posX * camWUx + posY * camWUy + posZ * camWUz
        sx = (af * vx)/vy
        sy = ( -tanFov * vz)/vy
        sz = ( -field * vy + nq)/vy
        sPX, sPY = (sx+1)*self.width*0.5, (sy+1)*self.height*0.5 -- screen pos X Y
        dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
        return sPX, sPY
    end
    --DUSystem.print("5")
    local SVG = {}
    SVGind = SVGind + 1
    SVG[SVGind] = format('<svg style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >', self.width, self.height)
    --DUSystem.print("6")
    local startPosX, startPosY = projection2D(cWPx, cWPy, cWPz)
    SVGind = SVGind + 1
    SVG[SVGind] = format('<text x="%.2f" y="%.2f" font-size="50" text-anchor="middle" font-family="Play" alignment-baseline="middle" stroke-width="0" fill="red">O</text> ', startPosX, startPosY)
    local tsx, tsy, tsz = normalizeVec(TS[1], TS[2], TS[3]) 
    tsx, tsy, tsz = l2W(tsx, tsy, tsz)
    local endPosX, endPosY = projection2D(tsx, tsy, tsz)
    endPosX = tostring(endPosX) ~= "-nan(ind)" and endPosX or startPosX
    endPosY = tostring(endPosY) ~= "-nan(ind)" and endPosY or startPosY
    --DUSystem.print(endPosX.." / "..endPosY)
    SVGind = SVGind + 1
    SVG[SVGind] = format('<line x1="%.2f" y1="%.2f" x2="%.2f" y2= "%.2f" stroke="red" stroke-width="3"/>', startPosX, startPosY, endPosX, endPosY)
    --DUSystem.print("9")
    SVGind = SVGind + 1
    SVG[SVGind] = '</svg>'
    return concat(SVG)
    --return ''
end
