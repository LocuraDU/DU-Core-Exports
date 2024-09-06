local utils = require("cpml/utils")
local abs, floor, format, sub, acos, sqrt, cos, sin, deg, ceil, clamp = math.abs, math.floor, string.format, string.sub, math.acos, math.sqrt, math.cos, math.sin, math.deg, math.ceil, utils.clamp
local widget_font = "Play"

local spacePOIS = {}
local customPOIS = {}
for i, poi in pairs(Helios) do
    spacePOIS[#spacePOIS+1] = poi
end
for i, poi in ipairs(BookmarksPOI) do
    if poi.bodyId == 0 then
        spacePOIS[#spacePOIS+1] = poi
    else
        customPOIS[#customPOIS+1] = poi
    end
end
for i, poi in ipairs(BookmarksCustoms) do
    if poi.bodyId == 0 then
        spacePOIS[#spacePOIS+1] = poi
    else
        customPOIS[#customPOIS+1] = poi
    end
end


WidgetsPlusPlus = {}
WidgetsPlusPlus.__index = WidgetsPlusPlus

function WidgetsPlusPlus.new(core, unit, DB, antigrav, warpdrive, shield, switch, player)
    local self = setmetatable({}, WidgetsPlusPlus)
    self.core = core
    self.unit = unit
    self.antigrav = (antigrav ~= nil) and antigrav or nil
    self.warpdrive = (warpdrive ~= nil) and warpdrive or nil
    return self
end

local function convertToWorldCoordinates(posString)
    local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local posPattern = '::pos{' .. num .. ',' .. num .. ',' .. num .. ',' .. num ..  ',' .. num .. '}'
    local systemId, bodyId, latitude, longitude, altitude = string.match(posString,posPattern)
    
    systemId = tonumber(systemId)
    bodyId = tonumber(bodyId)
    latitude = tonumber(latitude)
    longitude = tonumber(longitude)
    altitude = tonumber(altitude)
    
    if tonumber(bodyId) == 0 then
        return latitude,longitude,altitude
    end
    
    latitude = 0.0174532925199 * math.max(math.min(latitude, 90), -90)
    longitude = 0.0174532925199 * (longitude % 360)
    
    local center, radius = Helios[bodyId].center, Helios[bodyId].radius
    local xproj = cos(latitude)
    local px, py, pz = center[1]+(tonumber(radius)+altitude)*xproj*cos(longitude),
                        center[2]+(tonumber(radius)+altitude)*xproj*sin(longitude),
                        center[3]+(tonumber(radius)+altitude)*sin(latitude)
    return px, py, pz
end

local function getClosestPointToLine(lp1x, lp1y, lp1z, lp2x, lp2y, lp2z, px, py, pz) -- lp1 = line point A / lp2 = line point B / p = point to compare
    local alpha = ((px-lp1x)*(lp2x-lp1x) + (py-lp1y)*(lp2y-lp1y) + (pz-lp1z)*(lp2z-lp1z)) / ((lp2x-lp1x)*(lp2x-lp1x) + (lp2y-lp1y)*(lp2y-lp1y) + (lp2z-lp1z)*(lp2z-lp1z))
    local cptlx, cptly, cptlz = lp1x + alpha*(lp2x-lp1x), lp1y + alpha*(lp2y-lp1y), lp1z + alpha*(lp2z-lp1z)
    local dist = sqrt((cptlx-px)^2 + (cptly-py)^2 + (cptlz-pz)^2)
    return cptlx, cptly, cptlz, dist
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end

local function cross(x, y, z, vx, vy, vz)
    return y*vz - z*vy, z*vx - x*vz, x*vy - y*vx
end

local function vectorLen2(x,y,z)
    return x * x + y * y + z * z
end

local function project_on_plane(x, y, z, pnx, pny, pnz)
    local dot = dotVec(x, y, z, pnx, pny, pnz)
    local len2 = vectorLen2(pnx, pny, pnz)
    return (x - pnx*dot)/len2, (y - pny*dot)/len2, (z - pnz*dot)/len2
end

local function rotateVec(vx, vy, vz, phi, ax, ay, az)
    local l = sqrt(ax*ax + ay*ay + az*az)
    local ux, uy, uz = ax/l, ay/l, az/l
    local c, s = cos(phi), sin(phi)
    local m1x, m1y, m1z = (c + ux * ux * (1-c)), (ux * uy * (1-c) - uz * s), (ux * uz * (1-c) + uy * s)
    local m2x, m2y, m2z = (uy * ux * (1-c) + uz * s), (c + uy * uy * (1-c)), (uy * uz * (1-c) - ux * s)
    local m3x, m3y, m3z = (uz * ux * (1-c) - uy * s), (uz * uy * (1-c) + ux * s), (c + uz * uz * (1-c))
    return m1x*vx+m1y*vy+m1z*vz, m2x*vx+m2y*vy+m2z*vz, m3x*vx+m3y*vy+m3z*vz
end

local function getConstructRotation(x, y, z) --UPDATED
    if x == nil then x, y, z = -1,0,0 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CUx, CUy, CUz = cWOUPx, cWOUPy, cWOUPz
    local cx, cy, cz = cross(x, y, z, CUx, CUy, CUz)
    local rAx, rAy, rAz =  normalizeVec(cx, cy, cz)
    local ConstructRot = acos(clamp(dotVec(rAx, rAy, rAz, CRx, CRy, CRz), -1, 1)) * 57.2957795130
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CUx, CUy, CUz) > 0 then ConstructRot = -ConstructRot end --system.print("rot: "..ConstructRot)
    return ConstructRot
end
----------------
-- SPEEDO HUD --
----------------
function WidgetsPlusPlus.Speedometer_Update(self)
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local WC = params.Menu_Settings.WINDOW_COLOR.value
    local WCA = params.Menu_Settings.WINDOW_COLOR_A.value
    local ThrottleMult = 0
    local arrow_gov_rot = 0

    if params.KeyBind_Params.flightMode.value ~= "PARKING" then
        if MasterMode == "TRAVEL" or MasterMode == "SPORT" then ThrottleMult = 200
        elseif MasterMode == "CRUISE" then ThrottleMult = 0.1 
        end
    else ThrottleMult = 0 end
    local arrow_throttle_rot = abs(ThrottlePos*ThrottleMult)
    local text_speedz = format("%.0f",zSpeedKPH)
    local text_speedxyz_unit = "KM/H" 
    local HUD_text_speed0 = "" 
    local HUD_text_speed1 = ""
    local HUD_text_speed2 = ""
    local HUD_text_speed3 = ""
    local HUD_text_speed4 = ""
    local HUD_text_speed5 = ""
    local HUD_text_speed6 = ""
    local HUD_text_speed7 = ""
    local HUD_text_speed8 = ""
    local HUD_text_speed9 = ""
    local HUD_text_speed10 = ""
    local arrow_speed_rot = 0
    local text_speedxyz = ""

    if xyzSpeedKPH <= 2000 then 
        text_speedxyz_unit = "KM/H" 
        HUD_text_speed0 = "0" 
        HUD_text_speed1 = "200"
        HUD_text_speed2 = "400"
        HUD_text_speed3 = "600"
        HUD_text_speed4 = "800"
        HUD_text_speed5 = "1000"
        HUD_text_speed6 = "1.2k"
        HUD_text_speed7 = "1.4k"
        HUD_text_speed8 = "1.6k"
        HUD_text_speed9 = "1.8k"
        HUD_text_speed10 = "2k"
        arrow_speed_rot = xyzSpeedKPH/10 
        text_speedxyz = format("%.0f",xyzSpeedKPH)
        if arrow_throttle_rot > 200 then arrow_throttle_rot = 200 end
        if MasterMode == "CRUISE" then arrow_gov_rot = arrow_throttle_rot end
    elseif xyzSpeedKPH > 2000 then
        text_speedxyz_unit = "SU/H"
        HUD_text_speed0 = "0" 
        HUD_text_speed1 = "20"
        HUD_text_speed2 = "40"
        HUD_text_speed3 = "60"
        HUD_text_speed4 = "80"
        HUD_text_speed5 = "100"
        HUD_text_speed6 = "120"
        HUD_text_speed7 = "140"
        HUD_text_speed8 = "160"
        HUD_text_speed9 = "180"
        HUD_text_speed10 = "200"
        arrow_speed_rot = xyzSpeedKPH/200
        text_speedxyz = format("%.0f",xyzSpeedKPH/200)
        if MasterMode == "CRUISE" then 
            arrow_throttle_rot = arrow_throttle_rot / 20 
            arrow_gov_rot = arrow_throttle_rot 
        end
    end

    if ThrottlePos == 0 and abs(xyzSpeedKPH) < 5 then text_speedxyz = 0 text_speedz = 0 end

    local Ring_Color = WFC
    if brakeInput ~= 0 or Engines == false or autoBrake == true then Ring_Color = "red" end

    local FMText = sub(MasterMode,1,1)
    if ThrottlePos < 0 then FMText = "-"..FMText end

    local svgStyle = [[
        <style>
            .incrementText {font-size:8px; font-family:]]..widget_font..[[; alignment-baseline:baseline; stroke-width:0; fill:]]..WFC..[[}
        </style>
    ]]

    local SpeedoSVG_Outring = [[
        <circle cx="100" cy="100" r="99" stroke-width="1.5" stroke="]]..Ring_Color..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
    ]]
    local SpeedoSVG_Inring = [[
        <clipPath id="circle70">
        <rect x="1" y="1" width="300" height="110" />
        </clipPath>
        <clipPath id="circle35">
        <rect x="1" y="1" width="300" height="105" />
        </clipPath>
        
            <circle cx="100" cy="100" r="4" stroke-width="0" fill="]]..WFC..[["/>
            <circle cx="100" cy="100" r="70" stroke-width="1" fill="none" stroke="]]..WFC..[[" clip-path="url(#circle70)" />
            <circle cx="100" cy="100" r="35" stroke-width="1" fill="none" stroke="]]..WFC..[[" clip-path="url(#circle35)" />
    ]]
    local SpeedoSVG_RingBars = [[
            <line id="speedbarlong" x1="30" y1="100" x2="20" y2="100" stroke-width="1" fill="none" stroke="]]..WFC..[[" transform="rotate(-10 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(10 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(20 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(30 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(40 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(50 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(60 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(70 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(80 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(90 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(100 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(110 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(120 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(130 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(140 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(150 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(160 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(170 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(180 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(190 100 100)"/>
            <use xlink:href="#speedbarlong" transform="rotate(200 100 100)"/>
        
            <line id="speedbarshort" x1="30" y1="100" x2="25" y2="100" stroke-width="1" fill="none" stroke="]]..WFC..[[" transform="rotate(-10 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(5 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(15 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(25 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(35 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(45 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(55 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(65 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(75 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(85 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(95 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(105 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(115 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(125 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(135 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(145 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(155 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(165 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(175 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(185 100 100)"/>
            <use xlink:href="#speedbarshort" transform="rotate(195 100 100)"/>
        ]]
    local SpeedoSVG_Limitbars = [[
            <line id="line20d" x1="100" y1="100" x2="23" y2="100" stroke-width="1.5" fill="none" stroke="]]..WFC..[[" transform="rotate(-10 100 100)"/>
            <use xlink:href="#line20d" transform="rotate(200 100 100)"/>
            
            <line id="throttlebar" x1="65" y1="100" x2="70" y2="100" stroke-width="1" fill="none" stroke="]]..WFC..[[" transform="rotate(-10 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(20 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(40 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(60 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(80 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(100 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(120 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(140 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(160 100 100)"/>
            <use xlink:href="#throttlebar" transform="rotate(180 100 100)"/>
        ]]
    local SpeedoSVG_Incremnttext = [[
            <text x="19" y="108" class="incrementText" text-anchor="end">]]..HUD_text_speed0..[[</text>
            <text x="19" y="80" class="incrementText" text-anchor="end">]]..HUD_text_speed1..[[</text>
            <text x="29" y="53" class="incrementText" text-anchor="end">]]..HUD_text_speed2..[[</text>
            <text x="47" y="32" class="incrementText" text-anchor="end">]]..HUD_text_speed3..[[</text>
            <text x="71" y="15" class="incrementText" text-anchor="end">]]..HUD_text_speed4..[[</text>
            <text x="100" y="8" class="incrementText" text-anchor="middle">]]..HUD_text_speed5..[[</text>
            <text x="127" y="15" class="incrementText" text-anchor="start">]]..HUD_text_speed6..[[</text>
            <text x="152" y="32" class="incrementText" text-anchor="start">]]..HUD_text_speed7..[[</text>
            <text x="170" y="53" class="incrementText" text-anchor="start">]]..HUD_text_speed8..[[</text>
            <text x="180" y="80" class="incrementText" text-anchor="start">]]..HUD_text_speed9..[[</text>
            <text x="180" y="108" class="incrementText" text-anchor="start">]]..HUD_text_speed10..[[</text>
        
            <text x="130" y="140" font-size="15" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WFC..[[" >]]..text_speedxyz_unit..[[</text>
            <text x="114" y="165" font-size="12" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WFC..[[" >km/h</text>  
        ]]
    local SpeedoSVG_Arrows = [[
            <polygon points="30 100, 65 96, 65 104" stroke-width="0" fill="]]..WAC..[[" transform="rotate(]]..-10+arrow_speed_rot..[[ 100 100)"/>
            <polygon points="30 100, 24 96, 24 104" stroke-width="0" fill="]]..WAC..[[" transform="rotate(]]..-10+arrow_gov_rot..[[ 100 100)"/>
        
            <line x1="96" y1="100" x2="65" y2="100" fill="none" stroke-width="2" stroke="]]..WAC..[[" transform="rotate(]]..-10+arrow_throttle_rot..[[ 100 100)"/>
        ]]
    local fBD, bBD = brakingCalculation()
    if fBD == nil then fBD = 0 
    elseif fBD < 1000 then
        fBD = format("%.0f",fBD).."m"
    elseif fBD > 1000 then 
        fBD = format("%.0f",fBD/1000).."km"
    elseif fBD > 50000 then 
        fBD = format("%.2f",fBD/200000).."su"
    end
    local SpeedoSVG_Animatedtext = [[
            <text x="100" y="110" font-size="18" text-anchor="middle" font-family="]]..widget_font..[[" fill="]]..WTC..[[" alignment-baseline="baseline" >]]..FMText..[[</text>
            <text x="126" y="140" font-size="30" text-anchor="end" font-family="]]..widget_font..[[" fill="]]..WTC..[[" alignment-baseline="baseline" >]]..text_speedxyz..[[</text>
            <text x="111" y="165" font-size="25" text-anchor="end" font-family="]]..widget_font..[[" fill="]]..WTC..[[" alignment-baseline="baseline" >]]..text_speedz..[[</text>
            <text x="115" y="182" font-size="15" text-anchor="end" font-family="]]..widget_font..[[" fill="]]..WTC..[[" alignment-baseline="baseline" >]]..fBD..[[</text>
        </svg>
    </div> 
    ]]
    local SpeedoSVG = '<div><svg viewBox="0 0 200 200">'..svgStyle..SpeedoSVG_Outring..SpeedoSVG_Inring..SpeedoSVG_RingBars..SpeedoSVG_Limitbars..SpeedoSVG_Incremnttext..SpeedoSVG_Arrows..SpeedoSVG_Animatedtext..'</svg></div>'
    return SpeedoSVG
end

----------------
-- GYRO  HUD --
----------------
function WidgetsPlusPlus.Gyroscope_Update(self)
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local WC = params.Menu_Settings.WINDOW_COLOR.value
    local WCA = params.Menu_Settings.WINDOW_COLOR_A.value
    local arrow_drifty_rot = 0
    local arrow_driftz_rot = 0
    
    if abs(ySpeedKPH) > 5 then
    arrow_drifty_rot = Az
    end
    
    if abs(zSpeedKPH) > 10 then
    arrow_driftz_rot = Ax
    end
    
    local arrow_roll_rot = -1*Ay0
    local text_arrow_roll = format("%.0f",arrow_roll_rot)
    local text_arrow_pitch = format("%.0f",arrow_driftz_rot)
    local text_arrow_drift = format("%.0f",arrow_drifty_rot)
    
    local Ring_Color = WFC
    if abs(arrow_driftz_rot) > 30 or abs(arrow_drifty_rot) > 45 or Engines == false then Ring_Color = "red" end
    
    local GyroSVG_Outring = [[
            <circle cx="100" cy="100" r="99" stroke-width="1.5" stroke="]]..Ring_Color..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
    ]]
    
    local GyroSVG_Inring = [[
            <circle cx="100" cy="100" r="4" stroke-width="0" fill="]]..WFC..[["/>
            <circle cx="100" cy="100" r="67" stroke-width="1" fill="none" stroke="]]..WFC..[["/>
            <circle cx="100" cy="100" r="35" stroke-width="1" fill="none" stroke="]]..WFC..[["/>
    ]]
    
    local GyroSVG_Bars = [[
            <line id="driftybar" x1="33" y1="100" x2="28" y2="100" stroke-width="1" fill="none" stroke="]]..WFC..[[" transform="rotate(-90 100 100)"/> 
            <use xlink:href="#driftybar" transform="rotate(10 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(20 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(30 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(40 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(50 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(60 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(70 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(80 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(90 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(100 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(110 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(120 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(130 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(140 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(150 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(160 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(170 100 100)"/>
            <use xlink:href="#driftybar" transform="rotate(180 100 100)"/>
        
            <line id="driftzbar" x1="38" y1="100" x2="33" y2="100" stroke-width="1" fill="none" stroke="]]..WFC..[[" transform="rotate(90 100 100)"/> 
            <use xlink:href="#driftzbar" transform="rotate(10 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(20 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(30 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(40 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(50 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(60 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(70 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(80 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(90 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(100 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(110 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(120 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(130 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(140 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(150 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(160 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(170 100 100)"/>
            <use xlink:href="#driftzbar" transform="rotate(180 100 100)"/>
        
            <line x1="1729" y1="100" x2="1800" y2="100" stroke-width="1" fill="none" transform="rotate(0 100 100)"/>     
    ]]
    
    local GyroSVG_Arrows = [[
        <clipPath id="rollcircle">
        <rect x="0" y="96" width="150" height="8" />
        </clipPath>
            <line x1="100" y1="33" x2="100" y2="65" fill="none" stroke-width="0.5" stroke="]]..WFC..[["/>
            <line x1="65" y1="100" x2="33" y2="100" fill="none" stroke-width="0.5" stroke="]]..WFC..[["/>
            
            <line x1="100" y1="38" x2="100" y2="65" fill="none" stroke-width="2" stroke="]]..WAC..[[" transform="rotate(]].. 0+arrow_drifty_rot..[[ 100 100)"/>     
            <polygon points="100 33, 104 38, 96 38" stroke-width="0" fill="]]..WAC..[[" transform="rotate(]].. 0+arrow_drifty_rot..[[ 100 100)"/>
    
            <line x1="65" y1="100" x2="38" y2="100" fill="none" stroke-width="2" stroke="]]..WAC..[[" transform="rotate(]]..Ax0+arrow_driftz_rot..[[ 100 100)"/>     
            <polygon points="33 100, 38 104, 38 96" stroke-width="0" fill="]]..WAC..[[" transform="rotate(]]..Ax0+arrow_driftz_rot..[[ 100 100)"/>
            
            
            <line x1="65" y1="100" x2="33" y2="100" fill="none" stroke-width="2" stroke="]]..WAC..[[" transform="rotate(]].. Ax0..[[ 100 100)"/>     
            
            <line x1="66" y1="100" x2="134" y2="100" fill="none" stroke-width="2" stroke="]]..WAC..[[" transform="rotate(]].. 0+arrow_roll_rot..[[ 100 100)"/>     
            <circle cx="100" cy="100" r="35" stroke-width="2" fill="none" stroke="]]..WAC..[[" clip-path="url(#rollcircle)" transform="rotate(]].. 0+arrow_roll_rot..[[ 100 100)"/> 
    ]]
    
    local GyroSVG_Animatedtext = [[
            <text x="137" y="95" font-size="10" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">]]..text_arrow_roll..[[°</text>  
            <text x="34" y="95" font-size="10" text-anchor="end" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">]]..text_arrow_pitch..[[°</text>  
            <text x="98" y="15" font-size="10" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">]]..text_arrow_drift..[[°</text>  
    ]]
    
    local GyroSVG = '<div><svg viewBox="0 0 200 200">'..GyroSVG_Outring..GyroSVG_Inring..GyroSVG_Bars..GyroSVG_Arrows..GyroSVG_Animatedtext..'</svg></div>'
    return GyroSVG
end

----------------
-- FUEL HUD   --
----------------
local fuelTextCounter = {}
local fuelTextBool = {}
local fuelText = {}
function WidgetsPlusPlus.Fueltanks_Update(self,i)
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local WC = params.Menu_Settings.WINDOW_COLOR.value
    local WCA = params.Menu_Settings.WINDOW_COLOR_A.value
    FuelWindowSize = 66
    local Ring_Color = WFC
    local fueltanks_rot = 0
    local FTDi = fuelTanksData[i]
    
    if FTDi.percentage ~= nil then 
    fueltanks_rot = tonumber(FTDi.percentage)*2
        if FTDi.percentage < 10 or Engines == false then Ring_Color = "red"
        elseif FTDi.percentage < 25 then Ring_Color = "orange"
        else Ring_Color = WFC
        end
    end
    
    if not fuelTextCounter[i] then fuelTextCounter[i] = 0 fuelTextBool[i] = false fuelText[i] = "LOADING" end
    fuelTextCounter[i] = fuelTextCounter[i] + 1
    if fuelTextCounter[i] > 360 then
        if fuelTextBool[i] == true and tonumber(FTDi.timeLeft) ~= nil then 
            fuelText[i] = format("%.0f",tonumber(FTDi.timeLeft)/60) .. "min"
            fuelTextBool[i] = false
        else fuelText[i] = sub (FTDi.name,1,7):upper()
            fuelTextBool[i] = true
        end
        fuelTextCounter[i] = 0
    end
    
    
    local FuelSVG_Outring = [[
        <circle cx="33" cy="33" r="31" stroke="]]..Ring_Color..[[" stroke-width="2" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
    ]]
    
    local FuelSVG_Bars = [[
        <line id="fueltankbar" x1="5" y1="33" x2="10" y2="33" stroke-width="1.5" stroke="]]..WFC..[[" transform="rotate(-10 33 33)"/> 
        <use xlink:href="#fueltankbar" transform="rotate(20 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(40 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(60 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(80 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(100 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(120 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(140 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(160 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(180 33 33)"/>
        <use xlink:href="#fueltankbar" transform="rotate(200 33 33)"/>
        <circle cx="33" cy="33" r="2" stroke-width="0" fill="]]..WFC..[["/>
        <text x="33" y="42" font-size="9" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]]..fuelText[i]..[[</text> 
    ]]
    
    local FuelSVG_Arrow = [[
    <line x1="30" y1="33" x2="8" y2="33" fill="none" stroke-width="2" stroke="]]..WAC..[[" transform="rotate(]]..-10+fueltanks_rot..[[ 33 33)"/>
    ]]
    
    local FuelTanksSVG = '<div><svg viewBox="0 0 66 66">'..FuelSVG_Outring..FuelSVG_Bars..FuelSVG_Arrow..'</svg></div>'
    return FuelTanksSVG
end

--------------------
-- INFO HUD   --
--------------------
-- UNIT string: "{\"acceleration\":0.0,\"airDensity\":0.97397923469543457,\"airResistance\":0.0,\"atmoThrust\":0.0,
--\"controlData\":{\"axisData\":[{\"commandType\":3,\"commandValue\":0.0,\"speed\":0.0},{\"commandType\":3,
--\"commandValue\":0.0,\"speed\":0.0},{\"commandType\":3,\"commandValue\":0.0,\"speed\":0.0}],\"currentMasterMode\":0,
--\"masterModeData\":[{\"name\":\"Travel Mode\"},{\"name\":\"Cruise Control\"}]},\"controlMasterModeId\":0,\"elementId\":\"35758759\",
--\"helperId\":\"cockpit\",\"name\":\"Hovercraft seat controller [13]\",\"showHasBrokenFuelTank\":false,\"showOutOfFuel\":false,
--\"showOverload\":false,\"showScriptError\":false,\"showSlowDown\":false,\"spaceThrust\":0.0,\"speed\":0.0,\"type\":\"cockpit\"}\n"

--WARP string: "{\"buttonMsg\":\"CANNOT WARP\",\"cellCount\":\"0 / 0\",\"destination\":\"Unknown\",\"distance\":0,\"elementId\":\"26712674\",
--\"errorMsg\":\"NO WARP CONTAINER\",\"helperId\":\"warpdrive\",\"name\":\"Warp drive l [137]\",\"showError\":true,\"type\":\"warpdrive\"}\n"

--AGG string: "{\"antiGPower\":0.0,\"antiGravityField\":0.0,\"baseAltitude\":1000.0,\"helperId\":\"antigravity_generator\",
--\"name\":\"Anti-gravity generator s [115]\",\"showError\":true,\"type\":\"antigravity_generator\"}\n"

function WidgetsPlusPlus.Info_Update(self)
    local cM = DUConstruct.getMass()
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local WC = params.Menu_Settings.WINDOW_COLOR.value
    local WCA = params.Menu_Settings.WINDOW_COLOR_A.value
    local fontSize = 15
    local lineSpace = 25
    info_window_height = 0

    local fBD, bBD = brakingCalculation()
    if fBD == nil then fBD = 0 
    elseif fBD < 1000 then
        fBD = format("%.0f",fBD).."m"
    elseif fBD > 1000 then 
        fBD = format("%.0f",fBD/1000).."km"
    elseif fBD > 50000 then 
        fBD = format("%.2f",fBD/200000).."su"
    end

    if bBD == nil then bBD = 0
    elseif bBD < 1000 then
        bBD = format("%.0f",bBD).."m"
    elseif bBD > 1000 then 
        bBD = format("%.0f",bBD/1000).."km"
    elseif bBD > 50000 then 
        bBD = format("%.2f",bBD/200000).."su"
    end

    local InfoUnitSVG = [[
                <tspan x="5" text-anchor="start" fill="]]..WFC..[[">]]..'W.POS: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]].. format("%.0f",currentWorldPos.x) ..":"..format("%.0f",currentWorldPos.y) ..":"..format("%.0f",currentWorldPos.z) ..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'CLOSEST PLANET: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..currentPlanetName..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'ALTITUDE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.1f",alt/1000).."km"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'FLIGHT MODE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..MasterMode .." MODE"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'OPTIMAL ORBITAL SPEED: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.0f",math.sqrt(currentPlanetGM / (alt + currentPlanetRadius))*3.6).."kmph"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'MAX SPEED: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.0f",unitData.maxSpeedkph).."kph"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'ECO MODE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(params.Engines_Settings.ecoMode.value):upper() ..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'ACCELERATION: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.4f",unitData.acceleration/10).."g"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'MAX BRAKE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.0f",unitData.maxBrake/1000).."kn"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'FORWARD BRAKE DISTANCE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..fBD..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'BACKWARD BRAKE DISTANCE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..bBD..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'ATMO TRHUST: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.0f",unitData.atmoThrust/1000).."kn"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'SPACE TRHUST: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.0f",unitData.spaceThrust/1000).."kn"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'CONSTRUCT WEIGHT: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.2f",cM/1000).."tons"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'OVERLOAD: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(unitData.unitOverLoad):upper() ..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'FPS: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.0f",fps).."fps"..[[</tspan>
            ]]
    info_window_height = 15 * 30

    local InfoAGGSVG = ""
    if self.antigrav ~= nil then 
        InfoAGGSVG = [[
                <tspan x="5" dy="]]..lineSpace*2 ..[[" text-anchor="start" fill="]]..WFC..[[">]]..'ANTIGRAVITY STATE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(aggData.State):upper()..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'POWER: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(aggData.Power):upper()..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'FIELD: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(aggData.Field):upper()..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'CURRENT ALTITUDE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(aggData.Altitude):upper().."m"..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'SETUP ALTITUDE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(params.Engines_Settings.aggAltitude.value):upper().."m"..[[</tspan>
            ]]
        info_window_height = info_window_height + 6 * 30
    end

    local InfoWarpSVG = ""
    if self.warpdrive ~= nil then
        InfoWarpSVG = [[
                <tspan x="5" dy="]]..lineSpace*2 ..[[" text-anchor="start" fill="]]..WFC..[[">]]..'WARP INFO: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(warpData.Info):upper()..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'CELLS COUNT: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(warpData.Cells):upper()..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'DESTINATION: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..tostring(warpData.Destination):upper()..[[</tspan>
                <tspan x="5" dy="]]..lineSpace..[[" text-anchor="start" fill="]]..WFC..[[">]]..'DISTANCE: '..[[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]..format("%.1f",warpData.Distance/200000).." su"..[[</tspan>
            ]]
        info_window_height = info_window_height + 5 * 30
    end

    local InfoSVG = '<div><svg viewBox="0 0 309 '..info_window_height..'"><text x="5" y="20" font-size="'..fontSize..'" font-family="'..widget_font..'">'..InfoUnitSVG..InfoAGGSVG..InfoWarpSVG..'</text></svg></div>'
    
    return InfoSVG
end

    --------------------
    --   MAP   HUD    --
    --------------------
function WidgetsPlusPlus.Map_Update(self)
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local WC = params.Menu_Settings.WINDOW_COLOR.value
    local WCA = params.Menu_Settings.WINDOW_COLOR_A.value
    local MapSVG_Outring = [[
        <circle cx="100" cy="100" r="98.5" stroke-width="]].. 1.5/params.Widget_Map.window_scale ..[[" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
    ]]

    local MapSVG_Planet = ""
    local MapSVG_Planets = ""
    local MapSVG_Construct = ""
    local MapSVG_LocalBookmarks = ""
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local pCx, pCy, pCz = 0, 0, 0
    local sizeScale = 1

    if (inspace == 1 and alt > currentPlanetAtmoAltitude + 100000) or (inspace == 1 and alt == 0) then
        local cx, cy = cWPx/100000000*90, cWPy/100000000*90
        MapSVG_Construct = [[
            <circle cx="]].. 100 + cx..[[" cy="]].. 100 + cy..[[" r="1" stroke-width="0" fill="red"/>
        ]]


        for i, v in ipairs (spacePOIS) do
            if v.type[1] ~= "Moon" and v.type[1] ~= "Asteroid" then
                if spacePOIS[i].center ~= nil and #spacePOIS[i].center == 3 then
                    pCx, pCy, pCz = spacePOIS[i].center[1], spacePOIS[i].center[2], spacePOIS[i].center[3]
                    sizeScale = 1
                elseif spacePOIS[i].pos ~= nil and string.sub(spacePOIS[i].pos,1,6) == "::pos{" then
                    pCx, pCy, pCz = convertToWorldCoordinates(spacePOIS[i].pos)
                    sizeScale = 0.7
                end

                local px, py = pCx/100000000*90,pCy/100000000*90
                local pname = spacePOIS[i].name[1]
                local pdist = format(" (%.1fSU)",vectorLen(cWPx-pCx,cWPy-pCy,cWPz-pCz)/1000/200)
                local textOffset = 5.5
                if pname == "Sicari" or pname == "Ion" or pname == "Thades" then textOffset = -6 end
                MapSVG_Planets = MapSVG_Planets ..[[
                    <circle cx="]].. 100 + px..[[" cy="]].. 100 + py ..[[" r="]].. 1.5*sizeScale ..[[" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WTC..[["/>
                    <text x="]].. 100 + px..[[" y="]].. 100 + py + textOffset ..[[" font-size="]].. 5*sizeScale ..[[" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">
                        <tspan x="]].. 100 + px..[[" >]]..pname ..[[</tspan>
                        <tspan x="]].. 100 + px..[[" dy="]].. 3*sizeScale ..[[" font-size="]].. 3*sizeScale ..[[">]]..pdist..[[</tspan>
                    </text>
                ]]
            end
        end

        if params.Travel_Planner.Destination.value ~= nil and #params.Travel_Planner.Destination.value == 3 then
                local Dx, Dy, Dz = params.Travel_Planner.Destination.value[1], params.Travel_Planner.Destination.value[2], params.Travel_Planner.Destination.value[3]
                local px, py = Dx/100000000*90, Dy/100000000*90
                local pname = "Destination"
                local pdist = format(" (%.1fSU)",vectorLen(cWPx-Dx,cWPy-Dy,cWPz-Dz)/1000/200)
                local textOffset = 3.5
                MapSVG_Planets = MapSVG_Planets ..[[
                    <circle cx="]].. 100 + px..[[" cy="]].. 100 + py ..[[" r="]].. 1 ..[[" stroke-width="0.1" stroke="red" fill="red"/>
                    <text x="]].. 115 + px..[[" y="]].. 100 + py ..[[" font-size="4" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="red">
                        <tspan x="]].. 115 + px..[[" >]]..pname ..[[</tspan>
                        <tspan x="]].. 115 + px..[[" dy="3" font-size="3">]]..pdist..[[</tspan>
                    </text>
                ]]
        end

        MapSVG_Planet = [[
                <text x="1" y="8" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="hanging" stroke-width="0" fill="]]..WTC..[[">
                    <tspan font-size="10" >SPACE</tspan>
                </text>
                <circle cx="100" cy="100" r="80" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
                <circle cx="100" cy="100" r="60" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
                <circle cx="100" cy="100" r="40" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
                <circle cx="100" cy="100" r="20" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
        ]]
        
        local SFx, SFy, SFz = 13856701.7693, 7386301.6554, -258251.0307
        cx, cy = SFx/100000000*90, SFy/100000000*90
        MapSVG_Planets = MapSVG_Planets ..[[
                    <circle cx="]].. 100 + cx..[[" cy="]].. 100 + cy ..[[" r="]].. 20 ..[[" stroke-width="0.05" stroke="red" stroke-dasharray="4" stroke-opacity="0.7" fill="none"/>]]
    else
        local cPR = currentPlanetRadius
        local cPCx, cPCy, cPCz = currentPlanetCenter[1], currentPlanetCenter[2], currentPlanetCenter[3]
        local planet_scale = (-alt / (cPR/4)) + 1
        planet_scale = clamp(planet_scale,0.5,1)
        local atmo_map_scale = tonumber(params.Widget_Map.atmo_map_scale.value)
        MapSVG_Planet = [[
                <text x="1" y="8" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="hanging" stroke-width="0" fill="]]..WTC..[[">
                    <tspan font-size="10" >]]..currentPlanetName..[[</tspan>
                    <tspan font-size="7" >]].."(x"..atmo_map_scale..")"..[[</tspan>
                </text>
                <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="]].. 1/params.Widget_Map.window_scale ..[[" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 85*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 70*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 50*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 27*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="0.1" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 85*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 70*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 50*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 27*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
                <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="0.1" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        ]]

        --((cPC+cPR*vec3(0,0,1))-cWP)
        --DUSystem.print("a")
        local rot = getConstructRotation(cPCx-cWPx, cPCy-cWPy, cPCz+cPR-cWPz)
        --DUSystem.print("b")
        MapSVG_Construct = [[
            <polygon points="100 95, 97.5 105, 102.5 105" stroke-width="0" fill="]]..WAC..[[" transform="rotate(]]..rot..[[ 100 100)"/>
        ]]
        
        for i, v in ipairs(customPOIS) do
            local posx, posy, posz = convertToWorldCoordinates(v.pos)
            local MarkerDistance = vectorLen(posx-cWPx,posy-cWPy,posz-cWPz)
            if MarkerDistance < cPR/atmo_map_scale then
                if v.pos ~= nil  then
                    local M3Dx, M3Dy, M3Dz = (posx-cPCx)/(cPR/atmo_map_scale)*90*planet_scale, (posy-cPCy)/(cPR/atmo_map_scale)*90*planet_scale, (posz-cPCz)/(cPR/atmo_map_scale)*90*planet_scale
                    local VUx, VUy, VUz = normalizeVec(cPCx-cWPx, cPCy-cWPy, cPCz-cWPz)
                    local popx, popy, popz = project_on_plane(VUx, VUy, VUz, 0, 0, 1)
                    local rvx, rvy, rvz = rotateVec(popx, popy, popz, math.rad(-90), 0, 0, 1)
                    local VEx, VEy, VEz = normalizeVec(rvx, rvy, rvz)
                    local crx, cry, crz = cross(VUx, VUy, VUz, VEx, VEy, VEz)
                    local VNx, VNy, VNz = normalizeVec(crx, cry, crz)
                    local reso = DULibrary.systemResolution3({VEx, VEy, VEz},{VNx, VNy, VNz},{VUx, VUy, VUz},{M3Dx, M3Dy, M3Dz})
                    posx, posy, posz = reso[1], reso[2], reso[3]
                    MapSVG_LocalBookmarks = MapSVG_LocalBookmarks..[[
                            <circle cx="]].. 100 + posx..[[" cy="]].. 100 + posy ..[[" r="]].. 1.5 ..[[" stroke-width="0" fill="]]..WTC..[["/>
                            <text x="]].. 100 + posx..[[" y="]].. 100 + posy + 5.5  ..[[" font-size="5" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">
                                <tspan x="]].. 100 + posx..[[" >]]..v.name[1] ..[[</tspan>
                                <tspan x="]].. 100 + posx..[[" dy="3" font-size="3">]].." ("..floor(MarkerDistance/100)/10 .."km)"..[[</tspan>
                            </text>
                            ]]
                end
            end
        end
    end

    MapSVG = '<div><svg viewBox="0 0 200 200">'..MapSVG_Outring..MapSVG_Planet..MapSVG_Planets..MapSVG_LocalBookmarks..MapSVG_Construct..'</svg></div>'
    return MapSVG
end

--------------------
-- TRAVEL PLANNER --
--------------------
function WidgetsPlusPlus.Planner_Update(self)
    local bookmarks = {}
    local ind = 1
    local markers = {}
    for k, planet in pairs(Helios) do
        if planet.type[1] ~= "Moon" and planet.type[1] ~= "Asteroid" then
            markers[ind] = {name = planet.name, center = planet.center, warp = true, iconPath = planet.iconPath, showName = true}
            ind = ind + 1
        end
    end
    for i, poi in ipairs(BookmarksPOI) do
        if poi.warp ~= nil and poi.warp == true then
            local x, y, z = convertToWorldCoordinates(poi.pos)
            markers[ind] = {name = poi.name, center = {x,y,z}, warp = true, symbol = poi.symbol, showName = true}
            ind = ind + 1
        end
    end
    for i, poi in ipairs(BookmarksCustoms) do
        if poi.bodyId == 0 then
            local x, y, z = convertToWorldCoordinates(poi.pos)
            markers[ind] = {name = poi.name, center = {x,y,z}, warp = poi.warp ~= nil and poi.warp or false, symbol = poi.symbol, showName = true}
            ind = ind + 1
        end
        bookmarks[#bookmarks+1] = {name = poi.name, pos = poi.pos}
    end
    for i, aster in ipairs(asteroids) do
        local x, y, z = convertToWorldCoordinates(aster)
        markers[ind] = {name = {"Asteroid "..i}, center = {x,y,z}, warp = false, symbol = "☭", showName = false}
        ind = ind + 1
    end

    local mapcenter = 800
    local plasvg = [[<circle cx="]].. mapcenter..[[" cy="500" r="400" stroke-width="0.05" stroke="]]..params.Menu_Settings.WIDGET_FIXED_COLOR.value..[[" fill="]]..params.Menu_Settings.WINDOW_COLOR.value..[[" fill-opacity="]]..params.Menu_Settings.WINDOW_COLOR_A.value/2 ..[["/>
                    <circle cx="]].. mapcenter..[[" cy="500" r="300" stroke-width="0.05" stroke="]]..params.Menu_Settings.WIDGET_FIXED_COLOR.value..[[" fill="]]..params.Menu_Settings.WINDOW_COLOR.value..[[" fill-opacity="]]..params.Menu_Settings.WINDOW_COLOR_A.value/2 ..[["/>
                    <circle cx="]].. mapcenter..[[" cy="500" r="200" stroke-width="0.05" stroke="]]..params.Menu_Settings.WIDGET_FIXED_COLOR.value..[[" fill="]]..params.Menu_Settings.WINDOW_COLOR.value..[[" fill-opacity="]]..params.Menu_Settings.WINDOW_COLOR_A.value/2 ..[["/>
                    <circle cx="]].. mapcenter..[[" cy="500" r="100" stroke-width="0.05" stroke="]]..params.Menu_Settings.WIDGET_FIXED_COLOR.value..[[" fill="]]..params.Menu_Settings.WINDOW_COLOR.value..[[" fill-opacity="]]..params.Menu_Settings.WINDOW_COLOR_A.value/2 ..[["/>
                    ]]

    local bt = {}
    local color = ""
    local fs = 12
    local textOffset = 10
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    ind = 1

    for i, marker in ipairs(markers) do
            textOffset = -15
            local plname = markers[i].name[1]
            local PCx, PCy, PCz = markers[i].center[1],markers[i].center[2],markers[i].center[3]

            local bf = function() return function()
                local redraw = false
                if params.Travel_Planner.selected.name ~= markers[i].name[1] then redraw = true end
                local dist = vectorLen(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
                params.Travel_Planner.selected = {name = markers[i].name[1], dist = dist, warp = markers[i].warp, pos = {markers[i].center[1],markers[i].center[2],markers[i].center[3]}}
                DUSystem.setWaypoint("::pos{0,0,"..params.Travel_Planner.selected.pos[1]..","..params.Travel_Planner.selected.pos[2]..","..params.Travel_Planner.selected.pos[3].."}")
                if redraw == true  then windowsShow() APW_builder() if warpdrive then warpdrive.showWidget() end end
            end end

            local bpx, bpy = PCx/100000000*400, PCy/100000000*400
            local html = ""
            local apb = {}
            if marker.iconPath ~= nil then
                html = '<img src="'..markers[i].iconPath..'" style="width:48px;height:48px;opacity:0.75">' 
                apb = WindowLib:buttonsNew(html, bf(), {class = "mapPlanet", name = markers[i].name[1],width = 50, height = 50, posX = mapcenter - 25 + bpx, posY = 500 - 25 + bpy})
                textOffset = 40
            elseif marker.symbol ~= nil then
                html = marker.symbol
                apb = WindowLib:buttonsNew(html, bf(), {class = "mapMarker", name = markers[i].name[1],width = 25, height = 25, posX = mapcenter - 12.5 + bpx, posY = 500 - 12.5 + bpy}) --class= "separator", 
            end

            bt[ind] = apb
            ind = ind + 1

            if marker.warp == true then 
                color = params.Menu_Settings.WIDGET_FIXED_COLOR.value
                fs = 15
            else 
                color = params.Menu_Settings.WIDGET_ANIM_COLOR.value
                textOffset = -12
                fs = 12
            end
            if plname == "Sicari" or plname == "Ion" or plname == "Thades" then textOffset = -30 end
            if marker.showName == true then
                plasvg = plasvg ..[[
                                <text x="]].. mapcenter + bpx..[[" y="]].. 500 + bpy + textOffset  ..[[" font-size="]]..fs..[[" text-anchor="middle" font-family="Play" alignment-baseline="baseline" fill="]]..color..[[">
                                <tspan x="]].. mapcenter + bpx..[[" >]]..plname ..[[</tspan>
                                </text>
                            ]]
            end
    end

    if params.Travel_Planner.warp.warp1Stop ~= nil then
        local bf = function() return function()
            DUSystem.setWaypoint("::pos{0,0,"..params.Travel_Planner.warp.warp1Stop[1]..","..params.Travel_Planner.warp.warp1Stop[2]..","..params.Travel_Planner.warp.warp1Stop[3].."}")
        end end
        local bpx, bpy = params.Travel_Planner.warp.warp1Stop[1]/100000000*400, params.Travel_Planner.warp.warp1Stop[2]/100000000*400
        bt[ind] = WindowLib:buttonsNew("➀", bf(), {class = "mapMarker", name = "wwp1",width = 25, height = 25, posX = mapcenter - 12.5 + bpx, posY = 500 - 12.5 + bpy})
        ind = ind + 1
    end
    if params.Travel_Planner.warp.warp2Stop ~= nil then
        local bf = function() return function()
            DUSystem.setWaypoint("::pos{0,0,"..params.Travel_Planner.warp.warp2Stop[1]..","..params.Travel_Planner.warp.warp2Stop[2]..","..params.Travel_Planner.warp.warp2Stop[3].."}")
        end end
        local bpx, bpy = params.Travel_Planner.warp.warp2Stop[1]/100000000*400, params.Travel_Planner.warp.warp2Stop[2]/100000000*400
        bt[ind] = WindowLib:buttonsNew("➁", bf(), {class = "mapMarker", name = "wwp2",width = 25, height = 25, posX = mapcenter - 12.5 + bpx, posY = 500 - 12.5 + bpy})
        ind = ind + 1
    end

    local ccpx, ccpy = cWPx/100000000*400, cWPy/100000000*400
    bt[ind] = WindowLib:buttonsNew([[<div><svg height="50" width="50">
            <text x="10" y="20" font-size="30" font-family="Play" text-anchor="middle" alignment-baseline="middle" fill="red">☟</text>
            </svg></div>]],nil,{class = "mapMarker", name = "myPos",width = 25, height = 30, posX = mapcenter - 12.5 + ccpx, posY = 500 - 30 + ccpy})
    ind = ind + 1

    local function calculateWarpRoute(wpX, wpY, wpZ)
        wpX, wpY, wpZ = wpX ~= nil and wpX or 0, wpY ~= nil and wpY or 0, wpZ ~= nil and wpZ or 0
        local routeSubDiv = {}
        local indRT = 0
        for i, marker in ipairs(markers) do
            if marker.warp == true then
                indRT = indRT + 1
                routeSubDiv[indRT] = {}
                local normX, normY, normZ = normalizeVec(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
                local dist = vectorLen(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
                local l = dist/5
                local n = 0
                for j=0, 5, 1 do
                    n = j * l
                    routeSubDiv[indRT][j+1] = {cWPx + normX * n, cWPy + normY * n, cWPz + normZ * n, i, n}
                end
            end
        end
        local routeTest = {}
        local minDist = 99999999999999999999999
        local totalDist = 0
        indRT = 0
        for i, marker in ipairs(markers) do
            if marker.warp == true then
                local mX, mY, mZ = markers[i].center[1], markers[i].center[2], markers[i].center[3]
                for i2, line in ipairs(routeSubDiv) do
                    if  marker ~= markers[routeSubDiv[i2][4]] then
                        for i3, subdiv in ipairs(line) do
                            local sX, sY, sZ = subdiv[1], subdiv[2], subdiv[3]
                            local cpX, cpY, cpZ, distCP = getClosestPointToLine(mX, mY, mZ, sX, sY, sZ, wpX, wpY, wpZ)
                            local dist = vectorLen(sX-cpX, sY-cpY, sZ-cpZ)
                            local dist1 = vectorLen(sX-cWPx, sY-cWPy, sZ-cWPz)
                            totalDist = distCP
                            local dist2 = vectorLen(mX-cpX, mY-cpY, mZ-cpZ)
                            local distTot = vectorLen(mX-sX, mY-sY, mZ-sZ)
                            if totalDist < minDist and dist+dist2 <= distTot + 10000 then
                                minDist = totalDist
                                indRT = indRT + 1
                                routeTest[indRT] = {subdiv[5]+dist, {sX, sY, sZ}, subdiv[4], {cpX, cpY, cpZ}, i, distCP}
                            end
                        end
                    end
                end
            end
        end

        if indRT ~= 0 then
            params.Travel_Planner.warp.warp1Dest = markers[routeTest[indRT][3]]
            params.Travel_Planner.warp.warp1Stop = routeTest[indRT][2]
            params.Travel_Planner.warp.warp2Dest = markers[routeTest[indRT][5]]
            params.Travel_Planner.warp.warp2Stop = routeTest[indRT][4]
            params.Travel_Planner.warp.warpDistance = routeTest[indRT][1]
            params.Travel_Planner.warp.cruiseDistance = routeTest[indRT][6]
        else
            params.Travel_Planner.warp = {}
        end
        windowsShow()
    end

    if params.Travel_Planner.warp.warp1Dest ~= nil then
        local pX, pY = params.Travel_Planner.warp.warp1Dest.center[1], params.Travel_Planner.warp.warp1Dest.center[2]
        local wpx, wpy = pX/100000000*400, pY/100000000*400
        plasvg = plasvg .. [[<polyline points="]].. mapcenter + ccpx .. "," .. 500 + ccpy .. " ".. mapcenter + wpx .. "," .. 500 + wpy ..[[" style="fill:none;stroke:red;stroke-width:1;stroke-dasharray:4"/>]]
        pX, pY = params.Travel_Planner.warp.warp1Stop[1], params.Travel_Planner.warp.warp1Stop[2]
        wpx, wpy = pX/100000000*400, pY/100000000*400
        pX, pY = params.Travel_Planner.warp.warp2Dest.center[1], params.Travel_Planner.warp.warp2Dest.center[2]
        local wp1x, wp1y = pX/100000000*400, pY/100000000*400
        plasvg = plasvg .. [[<polyline points="]]..  mapcenter + wpx .. "," .. 500 + wpy .. " ".. mapcenter + wp1x .. "," .. 500 + wp1y ..[[" style="fill:none;stroke:red;stroke-width:1;stroke-dasharray:4"/>]]
        pX, pY = params.Travel_Planner.warp.warp2Stop[1], params.Travel_Planner.warp.warp2Stop[2]
        wpx, wpy = pX/100000000*400, pY/100000000*400
        pX, pY = params.Travel_Planner.selected.pos[1], params.Travel_Planner.selected.pos[2]
        wp1x, wp1y = pX/100000000*400, pY/100000000*400
        plasvg = plasvg .. [[<polyline points="]]..  mapcenter + wpx .. "," .. 500 + wpy .. " ".. mapcenter + wp1x .. "," .. 500 + wp1y ..[[" style="fill:none;stroke:red;stroke-width:0.5;stroke-dasharray:2 3"/>]] 
    end

    local bf = function() return function()
                calculateWarpRoute(params.Travel_Planner.selected.pos[1], params.Travel_Planner.selected.pos[2], params.Travel_Planner.selected.pos[3])
            end end
    bt[ind] = WindowLib:buttonsNew("CALCULATE MULTI WARPS ROUTE", bf(), {width = 250, height = 25, posX = 5, posY = 870})
    ind = ind + 1
    
    bf = function() return function()
                DUSystem.setWaypoint("::pos{0,0,"..params.Travel_Planner.selected.pos[1]..","..params.Travel_Planner.selected.pos[2]..","..params.Travel_Planner.selected.pos[3].."}")
                params.Travel_Planner.Destination.value = params.Travel_Planner.selected.pos
                DUSystem.print("Autopilot destination set to: "..params.Travel_Planner.selected.name)
                windowsShow()
            end end
    bt[ind] = WindowLib:buttonsNew("SET AS AUTOPILOT DESTINATION", bf(), {name = "setDest", width = 250, height = 25, posX = 5, posY = 840})
    ind = ind + 1

    plasvg = plasvg ..[[<text x="]].. 130 ..[[" y="]].. 160 ..[[" font-size="20" text-anchor="middle" font-family="Play" alignment-baseline="baseline" fill="]]..params.Menu_Settings.WINDOW_TEXT_COLOR.value..[[">]]..params.Travel_Planner.pageNum..[[</text>]]

    if params.Travel_Planner.selected.name ~= "n/a" then
        local pX, pY = params.Travel_Planner.selected.pos[1], params.Travel_Planner.selected.pos[2]
        local wpx, wpy = pX/100000000*400, pY/100000000*400
        plasvg = plasvg .. [[<circle cx="]].. mapcenter + wpx..[[" cy="]].. 500 + wpy ..[[" r="15" stroke-width="2" stroke="red" fill="none"/>]]
    end

    bf = function() return function()
        params.Travel_Planner.pageNum = utils.clamp(params.Travel_Planner.pageNum - 1, 1, 100)
        windowsShow()
    end end
    bt[ind] = WindowLib:buttonsNew("<<", bf(), {name = "prevPage", width = 25, height = 25, posX = 5, posY = 150})
    ind = ind + 1

    bf = function() return function()
        params.Travel_Planner.pageNum = utils.clamp(params.Travel_Planner.pageNum + 1, 1, 100)
        windowsShow()
    end end

    bt[ind] = WindowLib:buttonsNew(">>", bf(), {name = "nextPage", width = 25, height = 25, posX = 230, posY = 150})
    ind = ind + 1

    local maxButtons = 20
    for i, v in ipairs(bookmarks) do
        if i >= (params.Travel_Planner.pageNum-1) * maxButtons and i <= params.Travel_Planner.pageNum * maxButtons then
            local bmf = function() return function()
                DUSystem.setWaypoint(bookmarks[i].pos)
                local bx, by, bz = convertToWorldCoordinates(bookmarks[i].pos)
                local redraw = false
                if params.Travel_Planner.selected.name ~= bookmarks[i].name[1] then redraw = true end
                local dist = vectorLen(bx-cWPx, by-cWPy, bz-cWPz)
                params.Travel_Planner.selected = {name = bookmarks[i].name[1], dist = dist, warp = bookmarks[i].warp ~= nil and bookmarks[i].warp or false, pos = {bx, by, bz}}
                
                if redraw == true  then windowsShow() APW_builder() if warpdrive then warpdrive.showWidget() end end
            end end
            bt[ind] = WindowLib:buttonsNew(bookmarks[i].name[1], bmf(), {name = bookmarks[i].name[1], width = 250, height = 25, posX = 5 , posY = 180 + (i-1)*30 - (params.Travel_Planner.pageNum-1) * (maxButtons-1)*30})
            ind = ind + 1
        end
    end

    local tempWarp = "n/a"
    if params.Travel_Planner.selected.warp == true then tempWarp = ceil(((DUConstruct.getMass()/100) * (params.Travel_Planner.selected.dist / 200000))*0.00025) end
    local closestP = "n/a"
    local planetDistance = 999999999999
    local cpi = 0
    local cpdist = 0
    for i, v in pairs(Helios) do
        cpdist = vectorLen(v.center[1]-params.Travel_Planner.selected.pos[1], v.center[2]-params.Travel_Planner.selected.pos[2], v.center[3]-params.Travel_Planner.selected.pos[3])
        if cpdist < planetDistance then
            planetDistance = cpdist
            closestP = v.name[1]
        end
    end

    local d1Name = params.Travel_Planner.warp.warp1Dest ~= nil and params.Travel_Planner.warp.warp1Dest.name[1] or "n/a"
    local d2Name = params.Travel_Planner.warp.warp2Dest ~= nil and params.Travel_Planner.warp.warp2Dest.name[1] or "n/a"
    local warpable = params.Travel_Planner.warp.warpDistance ~= nil and floor(params.Travel_Planner.warp.warpDistance/1000/200).."su" or "n/a"
    local cruise = params.Travel_Planner.warp.cruiseDistance ~= nil and floor(params.Travel_Planner.warp.cruiseDistance/1000/200).."su" or "n/a"

    local textSvg = [[
                    <text x="]].. 5 ..[[" y="]].. 25 ..[[" font-size="20" text-anchor="start" font-family="Play" alignment-baseline="baseline" fill="]]..params.Menu_Settings.WINDOW_TEXT_COLOR.value..[[">
                    <tspan x="]].. 5 ..[[" dy="20" >Name: ]]..params.Travel_Planner.selected.name ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Distance : ]].. format('%.2f SU',params.Travel_Planner.selected.dist / 200000) ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Warpable: ]]..tostring(params.Travel_Planner.selected.warp) ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Warpcells: ]].. tempWarp ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Closest planet: ]].. closestP .."("..floor(planetDistance/1000/200).."su)"..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="800" >First Warp destination: ]].. d1Name ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Second Warp destination: ]].. d2Name ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Warpable distance: ]].. warpable ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Remaining Cruise distance: ]].. cruise ..[[</tspan>
                    </text>
                    ]]

    plasvg = '<div><svg style="position: absolute; left:0px; top:0px"  viewBox="0 0 1300 1000">'..plasvg..textSvg..'</svg></div>'

    return plasvg, bt
end