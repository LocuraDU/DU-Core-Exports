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

local utils = require("cpml/utils")
local widget_font = "Play"
local fuelTextCount = {}
local SVGfuelText = {}
local SVGfuelTextBool = {}
local fuelCounter = 1
local abs, floor, format, sqrt, clamp, sign= math.abs, math.floor, string.format, math.sqrt, utils.clamp, utils.sign

WidgetsPlusPlusCustom = {}
WidgetsPlusPlusCustom.__index = WidgetsPlusPlusCustom

function WidgetsPlusPlusCustom.new(core, unit, DB, antigrav, warpdrive, shield, switch, player)
    local self = setmetatable({}, WidgetsPlusPlusCustom)
    self.core = core
    self.unit = unit
    self.DB = DB
    self.antigrav = antigrav
    self.warpdrive = warpdrive
    self.shield = shield
    self.switch = switch
    self.name = "HUD++" -- name of the widget
    self.SVGSize = {x=1600,y=1000} -- size of the window to fit the svg, in pixels
    self.buttons = {} -- list of buttons to be implemented in widget
    self.width = DUSystem.getScreenWidth()
    self.height = DUSystem.getScreenHeight()
    self.pos = {x=self.width/2 -self.SVGSize.x/2, y=self.height/2 -self.SVGSize.y/2}
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

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return nil
end

--------------------
-- CUSTOM BUTTONS --
--------------------
--local button_function = function() system.print("Hello world!") end

--self.buttons = {
--                {button_text = "TEXT", button_function = button_function, class = nil, width = 0, height = 0, posX = 0, posY = 0},   -- class = "separator"   (for invisible background button)
--                }

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

----------------
-- WIDGET SVG --
----------------
function WidgetsPlusPlusCustom.SVG_Update(self)
--DUSystem.print('1')
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local SVGfinal = ""
    local SVGfixed = [[
        <clipPath id="clipcircle400">
        <rect x="0" y="300" width="1600" height="400" />
        </clipPath>
        
        
        <circle cx="800" cy="500" r="600" stroke-width="2" stroke="]]..WFC..[[" fill="none" clip-path="url(#clipcircle400)"/>
        
        <line id="bar1600" x1="235" y1="300" x2="214" y2= "300" stroke-width="2" stroke="]]..WFC..[["/>
        <use xlink:href="#bar1600" transform="rotate(180 800 500)"/>
        <line id="bar2600" x1="235" y1="700" x2="214" y2= "700" stroke-width="2" stroke="]]..WFC..[["/>
        <use xlink:href="#bar2600" transform="rotate(180 800 500)"/>
        <line x1="200" y1="500" x2="180" y2= "500" stroke-width="2" stroke="]]..WFC..[["/>
        <polygon id="triangle600" points="200 500, 201 505, 212 500, 201 495" stroke-width="0" fill="]]..WFC..[["/>
        <use xlink:href="#triangle600" transform="rotate(180 800 500)"/>
        
        <line x1="770" y1="500" x2="790" y2= "500" stroke-width="2" stroke="]]..WFC..[["/>
        <line x1="810" y1="500" x2="830" y2= "500" stroke-width="2" stroke="]]..WFC..[["/>
        <line x1="800" y1="470" x2="800" y2= "490" stroke-width="2" stroke="]]..WFC..[["/>
        <line x1="800" y1="510" x2="800" y2= "530" stroke-width="2" stroke="]]..WFC..[["/>
        
        <polygon points="800 897.5, 807 887.5, 793 887.5" stroke-width="0" fill="]]..WFC..[["/>
    ]]
--DUSystem.print('2')
    local indicatorColor = WFC
    if Engines == false then indicatorColor = "red" end
    local SVGrecindicator = [[
        <rect x="215" y="480" width="120" height="40" stroke="]]..indicatorColor..[[" fill="none"/>
        <rect x="1265" y="480" width="120" height="40" stroke="]]..indicatorColor..[[" fill="none"/>
    ]]
--DUSystem.print('2a')
    local SVGaltitude = [[
        <text x="275" y="500" font-size="20" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..format("%.0f", alt).."m"..[[</text>
    ]]
--DUSystem.print('2b')
    local throttleText = 0
    if MasterMode == "TRAVEL" then 
        throttleText = clamp(ThrottlePos,-100,100)
        throttleText = format("%.0f", throttleText*100).."/100"
    else 
        throttleText = clamp(ThrottlePos,-unitData.maxSpeedkph,unitData.maxSpeedkph)
        throttleText = format("%.0f", throttleText).."kph"
    end
--DUSystem.print('2c')
    local xyzSpeedText = format("%.0f", xyzSpeedKPH).."kph"
    if xyzSpeedKPH > 50000 then xyzSpeedText = "FTL" end
--DUSystem.print('2d')
    local throttleClipY = 0
    local tPos = 0
    if MasterMode == "TRAVEL" then --DUSystem.print('2da1')
        tPos = clamp(ThrottlePos,-1,1) --DUSystem.print('2da2 '..)
        throttleClipY = 700 - 400 * floor(abs(tPos)*100)/100 --DUSystem.print('2da3')
    else tPos = clamp(ThrottlePos,-unitData.maxSpeedkph,unitData.maxSpeedkph) --DUSystem.print('2db1')
        throttleClipY = 700 - 400 * abs(tPos)/unitData.maxSpeedkph --DUSystem.print('2db2')
    end
--DUSystem.print('2e')
    local currentThrust = 0
    if inspace == 0 then currentThrust = unitData.atmoThrust
    else currentThrust = unitData.spaceThrust
    end
--DUSystem.print('3')
    local forwardEnginesForce = Nav:maxForceForward()
    --local maxKPAlongAxis = self.core.getMaxKinematicsParametersAlongAxis('thrust analog longitudinal', {self.core.getConstructOrientationForward()})
    --if inspace == 1 then
    --    forwardEnginesForce = abs(tonumber(maxKPAlongAxis[3]))
    --else 
    --    forwardEnginesForce = abs(tonumber(maxKPAlongAxis[1]))
    --end
    local fBD, bBD = brakingCalculation()
    if fBD == nil then fBD = 0 
    elseif fBD < 1000 then
        fBD = format("%.0f", fBD).."m"
    elseif fBD > 1000 then 
        fBD = format("%.1f", fBD/1000).."km"
    elseif fBD > 50000 then 
        fBD = format("%.2f",fBD/200000).."su"
    end
    local brakeClipY = 200 * unitData.currentBrake/unitData.maxBrake
    local accelClipY = 500 - 200 * currentThrust/forwardEnginesForce
--DUSystem.print('4')
    local SVGspeedo = [[
        <clipPath id="clipthrottle">
        <rect x="800" y="]]..throttleClipY..[[" width="800" height="]].. 700 - throttleClipY..[[" />
        </clipPath>
        
        <clipPath id="clipbrake">
        <rect x="0" y="500" width="800" height="]]..brakeClipY..[[" />
        </clipPath>
        
        <clipPath id="clipaccel">
        <rect x="0" y="]]..accelClipY..[[" width="800" height="]].. 500 - accelClipY..[[" />
        </clipPath>
        
        <text x="1325" y="500" font-size="20" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..xyzSpeedText..[[</text>
        <text x="1425" y="500" font-size="15" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..throttleText..[[</text>
        
        <text x="170" y="500" font-size="15" text-anchor="end" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..format("%.0f", abs(zSpeedKPH))*sign(zSpeedKPH).."kph"..[[</text>
        
        <text x="1400" y="700" font-size="20" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..string.sub(MasterMode,1,1)..[[</text>
        <text x="1395" y="300" font-size="15" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..fBD..[[</text>
        
        <circle cx="800" cy="500" r="610" stroke-width="20" stroke="]]..WAC..[[" fill="none" stroke-opacity="]].. 0.25 ..[[" clip-path="url(#clipthrottle)"/>
        
        <circle cx="800" cy="500" r="610" stroke-width="20" stroke="]]..WAC..[[" fill="none" stroke-opacity="]].. 0.25 ..[[" clip-path="url(#clipbrake)"/>
        <text x="205" y="700" font-size="12" text-anchor="end" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..format("%.0f", unitData.currentBrake/1000).." / "..format("%.0f", unitData.maxBrake/1000).."kn"..[[</text>
    
        <circle cx="800" cy="500" r="610" stroke-width="20" stroke="]]..WAC..[[" fill="none" stroke-opacity="]].. 0.25 ..[[" clip-path="url(#clipaccel)"/>
        <text x="205" y="300" font-size="12" text-anchor="end" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[">]]..format("%.0f", currentThrust/1000).." / "..format("%.0f", forwardEnginesForce/1000).."kn"..[[</text>
    ]]
--DUSystem.print('5')
    local SVGbank = [[
        <clipPath id="clipbankcircle400">
        <rect x="0" y="300" width="1600" height="400"/>
        </clipPath>
        <circle cx="800" cy="500" r="400" stroke-width="5" stroke="]]..WFC..[[" fill="none" clip-path="url(#clipbankcircle400)"  transform="rotate(]]..Ay0..[[ 800 500)"/>
        <polygon id="triangle400" points="400 500, 402 505, 412 500, 402 495" stroke-width="0" fill="]]..WFC..[[" transform="rotate(]]..Ay0..[[ 800 500)"/>
        <use xlink:href="#triangle400" transform="rotate(180 800 500)"/>
        
        <line id="bankthick" x1="800" y1="97.5" x2="800" y2= "102.5" stroke-width="5" stroke="]]..WFC..[["/>
        <use xlink:href="#bankthick" transform="rotate(10 800 500)"/>
        <use xlink:href="#bankthick" transform="rotate(20 800 500)"/>
        <use xlink:href="#bankthick" transform="rotate(30 800 500)"/>
        
        <use xlink:href="#bankthick" transform="rotate(-10 800 500)"/>
        <use xlink:href="#bankthick" transform="rotate(-20 800 500)"/>
        <use xlink:href="#bankthick" transform="rotate(-30 800 500)"/>
        
        <polygon id="banktriangle" points="800 97.5, 807 87.5, 793 87.5" stroke-width="0" fill="]]..WFC..[[" transform="rotate(]]..Ay0..[[ 800 500)"/>
        <use xlink:href="#banktriangle" transform="rotate(180 800 500)"/>
        
        <line id="bankthin" x1="800" y1="100" x2="800" y2= "102.5" stroke-width="1" stroke="]]..WFC..[["/>
        <use xlink:href="#bankthin" transform="rotate(2.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(7.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(12.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(15 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(17.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(22.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(25 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(27.5 800 500)"/>

        <use xlink:href="#bankthin" transform="rotate(-2.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-7.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-12.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-15 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-17.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-22.5 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-25 800 500)"/>
        <use xlink:href="#bankthin" transform="rotate(-27.5 800 500)"/>
        
        <text x="800" y="70" font-size="12" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[" transform="rotate(]]..Ay0..[[ 800 500)" >]]..format("%.0f", abs(Ay0))*utils.sign(Ay0).."°"..[[</text>
    ]]
    
    local AHT = sign(Ax0) * abs(Ax0) / 90 * 400
--DUSystem.print('6')
    local SVGpitchbars = ""
    local i = 1
    local j = 800/18
    if alt < params.AutoPilot_Settings.stabilisationsAltitude.value then
        while (i<19) do
            if i*10 < Ax0 + 50 then
            SVGpitchbars = SVGpitchbars ..[[
            <line x1="0" y1="]].. 500 - i*j ..[[" x2="450" y2= "]].. 500 - i*j ..[[" stroke-width="]].. 2*(1-i/19) ..[[" fill="none"/>
            <text x="465" y="]].. 500 - i*j ..[[" font-size="12" text-anchor="middle"  alignment-baseline="middle" stroke-width="0" >]].. i*10 ..[[</text>
            <line x1="1600" y1="]].. 500 - i*j ..[[" x2="1150" y2= "]].. 500 - i*j ..[[" stroke-width="]].. 2*(1-i/19) ..[[" fill="none"/>
            <text x="1135" y="]].. 500 - i*j ..[[" font-size="12" text-anchor="middle" alignment-baseline="middle" stroke-width="0" >]].. i*10 ..[[</text>
            ]]
            end
            if i*-10 > Ax0 - 50 then
            SVGpitchbars = SVGpitchbars ..[[
            <line x1="1600" y1="]].. 500 + i*j ..[[" x2="1150" y2= "]].. 500 + i*j ..[[" stroke-width="]].. 2*(1-i/19) ..[[" fill="none"/>
            <text x="1135" y="]].. 500 + i*j ..[[" font-size="12" text-anchor="middle" alignment-baseline="middle" stroke-width="0" >]].. i*-10 ..[[</text>
            <line x1="0" y1="]].. 500 + i*j ..[[" x2="450" y2= "]].. 500 + i*j ..[[" stroke-width="]].. 2*(1-i/19) ..[[" fill="none"/>
            <text x="465" y="]].. 500 + i*j ..[[" font-size="12" text-anchor="middle"  alignment-baseline="middle" stroke-width="0" >]].. i*-10 ..[[</text>
            ]]
            end
            i = i+1
        end
        SVGpitchbars = SVGpitchbars..[[
            <line x1="0" y1="500" x2="450" y2= "500" stroke-width="3" fill="none"/>
            <text x="465" y="500" font-size="12" text-anchor="middle"  alignment-baseline="middle" stroke-width="0" >0</text>
            <line x1="1600" y1="500" x2="1150" y2= "500" stroke-width="3" fill="none"/>
            <text x="1135" y="500" font-size="12" text-anchor="middle"  alignment-baseline="middle" stroke-width="0" >0</text>
            <line x1="480" y1="500" x2="700" y2= "500" stroke-width="2" />
            <line x1="1120" y1="500" x2="900" y2= "500" stroke-width="2" />
        ]]
    end
    local SVGpitch = [[
        <clipPath id="clippitchcircle400">
        <circle cx="800" cy="500" r="400"/>
        </clipPath>
        
        <g clip-path="url(#clippitchcircle400)" stroke="]]..WFC..[[" font-family="]]..widget_font..[[" fill="]]..WFC..[[" stroke-opacity="]].. 0.25 ..[["  fill-opacity="]].. 0.5 ..[[">
             <g transform="rotate(]]..Ay0..[[ 800 500) translate(0 ]]..AHT..[[)">
        ]]..SVGpitchbars..[[
        </g></g>
        
        <text x="380" y="500" font-size="12" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[" transform="rotate(]]..Ay0..[[ 800 500)" >]]..format("%.0f", abs(Ax0))*utils.sign(Ax0).."°"..[[</text>
    ]]
--DUSystem.print('7')
    local cAV = DUConstruct.getAbsoluteVelocity()
    local cAVx, cAVy, cAVz = normalizeVec(xSpeedKPH * 0.27777777777, ySpeedKPH * 0.27777777777, zSpeedKPH * 0.27777777777)
    local velStrokeColor = WFC
    if xyzSpeedKPH < 5 then cAVx, cAVy, cAVz = 0,0,0 else if abs(Ax) > 45 or abs(Az) > 45 then velStrokeColor = "red" end end
    
    local SVGvelocity = [[
    <circle cx="]].. 800+cAVx*400 ..[[" cy="]].. 500+cAVz*-400 ..[[" r="10" stroke-width="1.5" stroke="]]..velStrokeColor..[[" fill="none"/>
    <line x1="800" y1="500" x2="]].. 800+cAVx*400 ..[[" y2= "]].. 500+cAVz*-400 ..[[" stroke-width="1" fill="none" stroke="]]..velStrokeColor..[["/>
    ]]
    
    local SVGfuel = ""
    local left = 0
    for i , v in ipairs(fuelTanksData) do
        
        if not fuelTextCount[i] then fuelTextCount[i] = 360 SVGfuelTextBool[i] = true SVGfuelText[i] = "LOADING" end
        fuelTextCount[i] = fuelTextCount[i]-1
        if fuelTextCount[i] < 0 then
            if SVGfuelTextBool[i] == false and tonumber(fuelTanksData[i].timeLeft)~= nil then 
                SVGfuelText[i] = format("%.0f", tonumber(fuelTanksData[i].timeLeft)/60) .. "min"
                SVGfuelTextBool[i] = true
            elseif SVGfuelTextBool[i] == true then 
                SVGfuelText[i] = format("%.0f", fuelTanksData[i].percentage) .. "/100"
                SVGfuelTextBool[i] = false
            end
            fuelTextCount[i] = 360
        end
--DUSystem.print('8')
        if string.sub(fuelTanksData[i].name,-1,-1) ~= "L" then
            SVGfuel = SVGfuel..[[
            <text x="1350" y="]].. 740+(i-1-left)*20 ..[[" font-size="12" text-anchor="end" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WFC..[[" >]]..string.sub(fuelTanksData[i].name,1,7):upper()..[[</text>
            
            <rect x="1360" y="]].. 732+(i-1-left)*20 ..[[" width="]].. 150*tonumber(fuelTanksData[i].percentage)/100 ..[[" height="15" stroke-width="1" fill="]]..WFC..[[" stroke="none" fill-opacity="]].. 0.25 ..[["/>
            <rect x="1360" y="]].. 732+(i-1-left)*20 ..[[" width="150" height="15" stroke-width="1" stroke="]]..WFC..[[" fill="none" />
            
            <text x="1445" y="]].. 740+(i-1-left)*20 ..[[" font-size="12" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[" >]]..SVGfuelText[i]..[[</text>
            ]]
        else
            SVGfuel = SVGfuel..[[
            <text x="245" y="]].. 740+(i-1)*20 ..[[" font-size="12" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WFC..[[" >]]..string.sub(fuelTanksData[i].name,1,7):upper()..[[</text>
            
            <rect x="90" y="]].. 732+(i-1)*20 ..[[" width="]].. 150*tonumber(fuelTanksData[i].percentage)/100 ..[[" height="15" stroke-width="1" fill="]]..WFC..[[" stroke="none" fill-opacity="]].. 0.25 ..[["/>
            <rect x="90" y="]].. 732+(i-1)*20 ..[[" width="150" height="15" stroke-width="1" stroke="]]..WFC..[[" fill="none" />
            
            <text x="175" y="]].. 740+(i-1)*20 ..[[" font-size="12" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="middle" stroke-width="0" fill="]]..WTC..[[" >]]..SVGfuelText[i]..[[</text>
            ]]
            left = left + 1
        end
    end
--DUSystem.print('9')
    SVGfinal = '<div><svg viewBox="0 0 '.. self.SVGSize.x ..' '.. self.SVGSize.y ..'">'..SVGrecindicator..SVGaltitude..SVGbank..SVGspeedo..SVGfixed..SVGpitch..SVGvelocity..SVGfuel..'</svg></div>'
    return SVGfinal
end
