--DEFAULT ++ windows colors variables:
--------------------------------------
--params.Menu_Settings.TITTLE_COLOR.value
--params.Menu_Settings.TITTLE_COLOR_A.value
--params.Menu_Settings.TITTLE_TEXT_COLOR.value
--params.Menu_Settings.WINDOW_COLOR.value
--params.Menu_Settings.WINDOW_COLOR_A.value
--params.Menu_Settings.WINDOW_TEXT_COLOR.value
--params.Menu_Settings.BUTTON_COLOR.value
--params.Menu_Settings.BUTTON_BORDER_COLOR.value
--params.Menu_Settings.BUTTON_COLOR_A.value
--params.Menu_Settings.BUTTON_TEXT_COLOR.value
--params.Menu_Settings.WIDGET_TEXT_COLOR.value
--params.Menu_Settings.WIDGET_ANIM_COLOR.value
--params.Menu_Settings.WIDGET_FIXED_COLOR.value

--DEFAULT ++ updated variables:
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
--MasterMode = string ("CRUISE" / "TRAVEL" / "PARKING")
--closestPlanetIndex = num (planet index for Helios library)
--atmofueltank = JSON
--spacefueltank = JSON
--rocketfueltank = JSON
--fueltanks = table (all fueltanks JSON data)
--fueltanks_size = num (total number of fuel tanks)

--DEFAULT ++ keybind variables:
-------------------------------
--CLICK = bool
--CTRL = bool
--ALT = bool
--SHIFT = bool
--pitchInput = num (-1 / 0 / 1)
--rollInput = num (-1 / 0 / 1)
--yawInput = num (-1 / 0 / 1)
--brakeInput = num (-1 / 0 / 1)
--strafeInput = num (-1 / 0 / 1)
--upInput = num (-1 / 0 / 1)
--forwardInput = num (-1 / 0 / 1)
--boosterInput = num (-1 / 0 / 1)

local widget_font = "Play"
local utils = require("cpml/utils")
local floor, sqrt, format, asin, clamp = math.floor, math.sqrt, string.format, math.asin, utils.clamp
WidgetsPlusPlusCustom = {}
WidgetsPlusPlusCustom.__index = WidgetsPlusPlusCustom

function WidgetsPlusPlusCustom.new(core, unit, DB, antigrav, warpdrive, shield, switch)
    local self = setmetatable({}, WidgetsPlusPlusCustom)
    self.core = core
    self.unit = unit
    self.DB = DB
    self.antigrav = antigrav
    self.warpdrive = warpdrive
    self.shield = shield
    self.switch = switch
    
    self.stopDist = 1
    
    self.buttons = {} -- list of buttons to be implemented in widget
    self.name = "TRAVELER++" -- name of the widget
    self.SVGSize = {x=500,y=200} -- size of the window to fit the svg, in pixels
    self.pos = {x=500, y=500}
    self.class = "widgets"  --class = "widgets" (only svg)/ class = "widgetnopadding" (default++ widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
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

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end

local function cross(x, y, z, vx, vy, vz)
    return y*vz - z*vy, z*vx - x*vz, x*vy - y*vx
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function getAARo(ox, oy, oz, nx, ny, nz, px, py, pz)
    ox, oy, oz = normalizeVec(ox, oy, oz)
    nx, ny, nz = normalizeVec(nx, ny, nz)
    local ax, ay, az = cross(ox, oy, oz, nx, ny, nz)
    local axisLen = vectorLen(ax, ay, az)
    local angle = 0
    ax, ay, az = normalizeVec(ax, ay, az)
    if axisLen > 0.000001
    then
        angle = asin(clamp(axisLen, 0, 1))
    else
        ax, ay, az = px, py, pz
    end
    if dotVec(ox, oy, oz, nx, ny, nz) < 0
    then
        angle = math.pi - angle
    end
    return ax, ay, az, angle
end

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    --DUSystem.print("test flush")
    if params.Travel_Planner.lockedDestination.value ~= nil and type(params.Travel_Planner.lockedDestination.value) == "table" then
        
        local cWP = DUConstruct.getWorldPosition()
        local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
        local lD = params.Travel_Planner.lockedDestination.value
        local lDx, lDy, lDz = lD[1] - cWPx, lD[2] - cWPy, lD[3] - cWPz
        local cWAV = DUConstruct.getWorldVelocity()
        local cWAVx, cWAVy, cWAVz = cWAV[1], cWAV[2], cWAV[3]
        local speed = vectorLen(cWAVx, cWAVy, cWAVz)
        cWAVx, cWAVy, cWAVz = normalizeVec(cWAVx, cWAVy, cWAVz)
        
        local axx, axy, axz, an = 0,0,0,0
        if speed > 2000 / 3.6 then
            axx, axy, axz, an = getAARo(cWAVx+cWOFx*2, cWAVy+cWOFy*2, cWAVz+cWOFz*2, lDx, lDy, lDz, 0, 0, 1)
            
        else 
            axx, axy, axz, an = getAARo(cWOFx, cWOFy, cWOFz, lDx, lDy, lDz, 0, 0, 1)
        end
        local otAVx = axx * an
        local otAVy = axy * an
        local otAVz = axz * an
        
        local fBD, bBD = brakingCalculation()
        local longdist = (vectorLen(lDx, lDy, lDz) - fBD - (self.stopDist*200000))*3.6
        local longitudinalSpeed = longdist > 1000 and longdist or 0 --and an < 0.1 
        local lateralSpeed = 0
        local verticalSpeed = 0
        
        if pitchInput ~= 0 or 
        rollInput ~= 0 or 
        yawInput ~= 0 or 
        brakeInput ~= 0 or 
        strafeInput ~= 0 or 
        upInput ~= 0 or 
        forwardInput ~= 0 then
            params.Travel_Planner.lockedDestination.value = nil
            DUSystem.print("TRAVELER++: Construct alignement aborted")
            return nil
        end
        --DUSystem.print(longitudinalSpeed.." / "..lateralSpeed.." / "..verticalSpeed.." / "..otAVx.." / "..otAVy.." / "..otAVz)
        return longitudinalSpeed, lateralSpeed, verticalSpeed, otAVx, otAVy, otAVz
    else
        return nil
    end
end

--------------------
-- CUSTOM BUTTONS --
--------------------
--local button_function = function() system.print("Hello world!") end



local function SecondsToClock(seconds)
  local seconds = tonumber(seconds)
  if seconds <= 0 or floor(seconds/3600) > 24 then
    return "00:00:00"
  else
    local hours = format("%02.f", floor(seconds/3600))
    local mins = format("%02.f", floor(seconds/60 - (hours*60)))
    local secs = format("%02.f", floor(seconds - hours*3600 - mins *60))
    return hours..":"..mins..":"..secs
  end
end
----------------
-- WIDGET SVG --
----------------
function WidgetsPlusPlusCustom.SVG_Update(self)
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local s = 0
    local distance = 0
    local estimatedTime = "00:00:00"
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]

    if params.Travel_Planner.Destination.value ~= nil and #params.Travel_Planner.Destination.value == 3 then
        local bf = function() return function()
                            if mouseWheel == 0 then
                                    DUSystem.print("Travel engaged, press any key to abort!")
                                    params.Travel_Planner.lockedDestination.value = params.Travel_Planner.Destination.value
                                    --params.KeyBind_Params.flightMode.value = "CRUISE" 
                                    --Nav:setMasterMode("CRUISE") system.print("Cruise mode set")
                            elseif mouseWheel > 0 then
                                if self.stopDist >= 1 then
                                    self.stopDist = clamp(self.stopDist+0.1,0.01,25)
                                else
                                    self.stopDist = clamp(self.stopDist+0.01,0.01,25)
                                end
                            elseif mouseWheel < 0 then
                                if self.stopDist > 1 then
                                    self.stopDist = clamp(self.stopDist-0.1,0.01,25)
                                else
                                    self.stopDist = clamp(self.stopDist-0.01,0.01,25)
                                end
                            end
                            windowsShow()
                    end end
        local ptpd = params.Travel_Planner.Destination.value
        distance = vectorLen(ptpd[1]-cWPx,ptpd[2]-cWPy,ptpd[3]-cWPz)
        s = distance /(xyzSpeedKPH*0.27777777777)
        s = type(s) == "number" and tostring(s) ~= "inf" and s or 0
        estimatedTime = SecondsToClock(s)
        local btText = "START TRAVEL (stop at: "..self.stopDist.."su)"
        self.buttons = {
            {btText, bf(), {name = "traveler++ start", class = nil, width = 275, height = 25, posX = 0, posY = 120}},   -- class = "separator"   (for invisible background button)
            }
    else
        self.buttons = {
                {"", nil, {name = "traveler++ start", class = "separator", width = 0, height = 0, posX = 0, posY = 0}},   -- class = "separator"   (for invisible background button)
                }
    end

    if distance > 50000 then distance = tostring(floor((distance / 200000)*100)/100).." SU"
    else distance = tostring(floor((distance/1000)*100)/100).." KM"
    end

    local fBD, bBD = brakingCalculation()
    local fBDtext = ""
    if fBD == nil then fBDtext = "error" end
    if fBD < 1000 then
        fBDtext = format("%.0f", fBD).."m"
    else
        fBDtext = format("%.1f", fBD/1000).."km"
    end
    if fBD > 50000 then 
        fBDtext = format("%.2f",fBD/200000).."su"
    end

    local SVG = [[
        <text x="0" y="45" font-size="20" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]]..distance..[[</text> 
        <text x="0" y="72" font-size="30" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]]..estimatedTime..[[</text> 
        <text x="0" y="95" font-size="20" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]].."Braking distance: ".. fBDtext ..[[</text> 
    ]]
    
    SVG = '<div><svg viewBox="0 0 '.. self.SVGSize.x ..' '.. self.SVGSize.y ..'">'..SVG..'</svg></div>'
    return SVG
end
