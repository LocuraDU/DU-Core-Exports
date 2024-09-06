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
    
    self.backBurn = false
    self.modeOn = false
    self.follow = false
    self.modeRocket = false
    self.warmup = false
    self.autoLand = false
    self.hasATelemeter = self.telemeter ~= nil and type(self.telemeter) == 'table' and #self.telemeter > 0 and true or false
    self.VStabAltMSeepFactor = 1.0
    self.cruiseSpeed = 250
    self.shiftSpeed = 1000
    self.cruiseAngle = 30
    self.shiftAngle = 60
    self.stopDistance = 5 --stop distance from follower to player
    self.altAdjust = 2.5 --altitude adjustment factor
    self.targetSpeedPID = pid.new(0.02, 0.001, 1)
    self.altPIDProportional = 10 --316227766
    self.altPIDIntegral = 0.0
    self.altPIDDerivitave = 10
    --self.altitudeCorrectionPID = pid.new(self.altPIDProportional, self.altPIDIntegral, self.altPIDDerivitave)
    self.altitudeCorrectionPID = pid.new(1,0,1)
    self.altitudeBoostPID = pid.new(self.altPIDProportional, self.altPIDIntegral, self.altPIDDerivitave)

    self.buttons = {} -- list of buttons to be implemented in widget
    self.name = "DRONE FLIGHT++" -- name of the widget
    self.SVGSize = {x=255,y=255} -- size of the window to fit the svg, in pixels
    self.pos = {x=500, y=500}
    self.class = "widgetnopadding"  --class = "widgets" (only svg)/ class = "widgetnopadding" (default++ widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.tittle = "DRONE FLIGHT++" --tittle for default++ widget style
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

function WidgetsPlusPlusCustom.loadData(self)
    if Data then
        DUSystem.print("Loading Drone Mode personal data")
        local d2L = Data:getData("DM_"..tostring(self.player.getId()))
        if d2L then
            self.modeOn = d2L["dM"] ~= nil and d2L["dM"] or false
            self.cruiseAngle = d2L["cA"] ~= nil and d2L["cA"] or 30
            self.shiftAngle = d2L["sA"] ~= nil and d2L["sA"] or 60
            self.follow = d2L["fl"] ~= nil and d2L["f"] or false
            self.stopDistance = d2L["sD"] ~= nil and d2L["sD"] or 5
            self.altAdjust = d2L["aA"] ~= nil and d2L["aA"] or 2.5
            self.backBurn = d2L["bB"] ~= nil and d2L["bB"] or false
        end
    end
end
function WidgetsPlusPlusCustom.saveData(self)
    if Data then
        DUSystem.print("Saving Drone Mode personal data")
        local d2S = {}
        d2S["dM"] = self.modeOn
        d2S["cA"] = self.cruiseAngle
        d2S["sA"] = self.shiftAngle
        d2S["fl"] = self.follow
        d2S["sD"] = self.stopDistance
        d2S["aA"] = self.altAdjust
        d2S["bB"] = self.backBurn
        --DUSystem.print("table: "..Data:serialize(d2S))
        Data:setData("DM_"..tostring(self.player.getId()),d2S)
    end
end

--local targetSpeed = 1
function WidgetsPlusPlusCustom.onActionStart(self, action) -- uncomment to receive pressed key
    --DUSystem.print(action)
    --targetSpeed = 1
    if self.modeOn == false then return nil end
    --DUSystem.print("Key Pressed"..action)
    if action == 'speedup' then
    elseif action == 'speeddown' then
    elseif action == 'stopengines' then
        self.modeRocket = not self.modeRocket
        if self.modeRocket then self.warmup = true else self.warmup = false VStabAltMLock = nil end
    elseif action == 'forward' then
        self.modeRocket = false
        self.autoLand = false
    elseif action == 'backward' then
        self.modeRocket = false
        self.autoLand = false
    elseif action == 'yawright' then
        -- map to roll
    elseif action == 'yawleft' then
        -- map to roll
    elseif action == 'right' then -- roll
        -- normal roll
    elseif action == 'left' then -- roll
        -- normal roll
    elseif action == 'straferight' then
        self.modeRocket = false
        self.autoLand = false
    elseif action == 'strafeleft' then
        self.modeRocket = false
        self.autoLand = false
    elseif action == 'up' then
        self.autoLand = false
        -- pitch up 45 degrees while held?
    elseif action == 'down' then
        self.autoLand = false
        -- pitch down45 degrees while held?
    elseif action == 'lshift' then
    elseif action == 'lalt' then
    elseif action == 'brake' then
        self.modeRocket = false
        self.autoLand = false
    elseif action == 'gear' then
        DUSystem.print('Auto landing mode activated')
        self.autoLand = true
        self.modeRocket = false
        if self.hasATelemeter == false then DUSystem.print("WARNING no telemeter detected! Crash landing") end
        landTime = currentTime
    elseif action == 'light' then
    elseif action == 'booster' then
    elseif action == 'antigravity' then
    elseif action == 'groundaltitudedown' then
        -- decrease locked altitude
    elseif action == 'groundaltitudeup' then
        -- increase locked altitude
    elseif action == 'warp' then
    end

end

-- function WidgetsPlusPlusCustom.onActionStop(self, action) -- uncomment to receive released key
--      --DUSystem.print(action)
-- end

-- function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive pressed key
--      --DUSystem.print(action)
-- end

local abs, floor, asin, sqrt, cos, acos, sin, deg, atan, rad, sign, clamp, rad2deg, format, max, min = math.abs, math.floor, math.asin, math.sqrt, math.cos, math.acos, math.sin, math.deg, math.atan, math.rad, utils.sign, utils.clamp, constants.rad2deg, string.format, math.max, math.min

local function sf(s)
    return string.format("%.4f", s)
end

----------------------------------------------------------------
--               Thrust Management library                    --
----------------------------------------------------------------

-- Vectors manipulations --
---------------------------
local function normalizeVecOld(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function normalizeVec(x,y,z)
    local l = 1/sqrt(x*x + y*y + z*z)
    return x*l, y*l, z*l
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
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

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end

local function cross(x, y, z, vx, vy, vz)
    return y*vz - z*vy, z*vx - x*vz, x*vy - y*vx
end

local function local2World(vx,vy,vz)
    local x = vx * cWORx + vy * cWOFx + vz * cWOUPx + cWCOMx
    local y = vx * cWORy + vy * cWOFy + vz * cWOUPy + cWCOMy
    local z = vx * cWORz + vy * cWOFz + vz * cWOUPz + cWCOMz
    return x,y,z
end

local function world2local(x,y,z)
    local v = DULibrary.systemResolution3({cWORx, cWORy, cWORz},{cWOFx, cWOFy, cWOFz},{cWOUPx, cWOUPy, cWOUPz},{x,y,z})
    return v[1],v[2],v[3]
end

local function multiplyVec(x,y,z,factor)
    return x*factor, y*factor, z*factor
end


-- Rotations control --
-----------------------
local function getConstructRot(x, y, z)
    if x == nil then x, y, z = -1,0,0 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CUx, CUy, CUz = cWOUPx, cWOUPy, cWOUPz
    local cx, cy, cz = cross(x, y, z, CUx, CUy, CUz)
    local rAx, rAy, rAz =  normalizeVec(cx, cy, cz) -- rot axis
    local ConstructRot = acos(clamp(dotVec(rAx, rAy, rAz,CRx, CRy, CRz), -1, 1)) * rad2deg
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CUx, CUy, CUz) > 0 then ConstructRot = -ConstructRot end
    return ConstructRot
end

local function getConstructPitch(x, y, z)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CFx, CFy, CFz = cWOFx, cWOFy, cWOFz
    local cx, cy, cz = cross(x, y, z, CRx, CRy, CRz)
    local pAx, pAy, pAz =  normalizeVec(cx, cy, cz) --pith axis
    local ConstructPitch = acos(clamp(dotVec(pAx, pAy, pAz, CFx, CFy, CFz), -1, 1)) * rad2deg
    cx, cy, cz = cross(pAx, pAy, pAz, CFx, CFy, CFz)
    if dotVec(cx, cy, cz, CRx, CRy, CRz) < 0 then ConstructPitch = -ConstructPitch end
    return ConstructPitch
end

local function getConstructRoll(x,y,z)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CFx, CFy, CFz = -cWOFx, -cWOFy, -cWOFz
    local cx, cy, cz = cross(x, y, z, CFx, CFy, CFz)
    local rAx, rAy, rAz =  normalizeVec(cx, cy, cz) --roll Axis
    local ConstructRoll = acos(clamp(dotVec(rAx, rAy, rAz, CRx, CRy, CRz), -1, 1)) * rad2deg
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CFx, CFy, CFz) < 0 then ConstructRoll = -ConstructRoll end
    return ConstructRoll
end

local function rollAngularVelocity(x,y,z, angle, speed)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = normalizeVec(x,y,z)
    local CFx, CFy, CFz = -cWOFx, -cWOFy, -cWOFz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CFx, CFy, CFz) end
    local RollDeg = getConstructRoll(x, y, z)
    if (RollPID == nil) then 
        RollPID = pid.new(0.2, 0, 2)
    end
    RollPID:inject(0 - RollDeg)
    local PIDget = RollPID:get()
    return PIDget * CFx * speed, PIDget * CFy * speed, PIDget * CFz * speed
end

local function pitchAngularVelocity(x,y,z, angle, speed)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CRx, CRy, CRz) end
    local PitchDeg = getConstructPitch(x, y, z)
    if (PitchPID == nil) then 
        PitchPID = pid.new(0.2, 0, 2)
    end
    PitchPID:inject(0-PitchDeg)
    local PIDget = PitchPID:get()
    return PIDget * CRx * speed, PIDget * CRy * speed, PIDget * CRz * speed
end

local function yawAngularVelocity(x,y,z, angle, speed)
    if x == nil then x, y, z = -1,0,0 end
    x, y, z = normalizeVec(x,y,z)
    local CUx, CUy, CUz = -cWOUPx, -cWOUPy, -cWOUPz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CUx, CUy, CUz) end
    local YawDeg = getConstructRot(x, y, z)
    if (YawPID == nil) then 
        YawPID = pid.new(0.2, 0, 2)
    end
    YawPID:inject(0 - YawDeg)
    local PIDget = YawPID:get()
    return PIDget * CUx * speed, PIDget * CUy * speed, PIDget * CUz * speed
end

local function angle3DVec(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4) -- x1 = first vector(ex: velocity vec) / x2 = second vector(ex: construct X axis) / x3 = reference X axis / x4 = reference Z axis
    local angle = acos(dotVec(x1,y1,z1,x2,y2,z2) / (vectorLen(x1,y1,z1) * vectorLen(x2,y2,z2))) * rad2deg
    local tx,ty,tz = cross(x1,y1,z1,x4,y4,z4)
    local cx,cy,cz = cross(tx,ty,tz,x3,y3,z3)
    return angle*sign(dotVec(cx,cy,cz,x4,y4,z4))
end

local function getConstructRoll90(x,y,z) --for the auto yaw when pitch = 90
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CUx, CUy, CUz = -cWOUPx, -cWOUPy, -cWOUPz
    local cx, cy, cz = cross(x, y, z, CUx, CUy, CUz)
    local rAx, rAy, rAz =  normalizeVec(cx, cy, cz) --roll Axis
    local ConstructRoll = acos(clamp(dotVec(rAx, rAy, rAz, CRx, CRy, CRz), -1, 1)) * rad2deg
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CUx, CUy, CUz) < 0 then ConstructRoll = -ConstructRoll end
    return ConstructRoll
end

local function rollAngularVelocity90(x,y,z, angle, speed) --for the auto yaw when pitch = 90
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = normalizeVec(x,y,z)
    local CUx, CUy, CUz = -cWOUPx, -cWOUPy, -cWOUPz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CUx, CUy, CUz) end
    local RollDeg = getConstructRoll90(x, y, z)
    if (RollPID90 == nil) then 
        RollPID90 = pid.new(0.05, 0, 1)
    end
    RollPID90:inject(0 - RollDeg)
    local PIDget = RollPID90:get()
    return PIDget * CUx * speed, PIDget * CUy * speed, PIDget * CUz * speed
end

local function getAAR(ox, oy, oz, nx, ny, nz, px, py, pz)
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

function WidgetsPlusPlusCustom.BDC(self)
    local MaxBrakesForce = DUConstruct.getMaxBrake() or 0--unitData.maxBrake ~= nil and unitData.maxBrake or 0
    local maxSpeed = 50000/3.6
    local cAV = DUConstruct.getVelocity()
    local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
    local cWAV = DUConstruct.getWorldAbsoluteVelocity()
    local zSpeedMPS = abs(cAVz) --sqrt(cAVx^2+cAVy^2+cAVz^2) getConstructIMass
    local cM = DUConstruct.getMass()
    --local cM = construct.getInertialMass()
    local grav = self.core.getWorldGravity()
    local g = self.core.getGravityIntensity()
    local G_axis = -1*sign(cWAV[1]*grav[1] + cWAV[2]*grav[2] + cWAV[3]*grav[3])
    local brakesAcceleration = MaxBrakesForce + g*G_axis * cM
    local brakeDistance = cM * maxSpeed^2 / brakesAcceleration * (1 - sqrt(1 - ((zSpeedMPS)^2 / maxSpeed^2)))
    return brakeDistance
end

local longSpeedStrength = 0
local latSpeedStrength = 0
local vertSpeedStrength = 0
local Axy90 = 0
PreviousMasterMode = "CRUISE"

local VStabCount = 0
local VStabAdjustedAngle = 0
local altM = 0

local planetVertSpeedMPS = 0
local prevAltHoldAng = -4.8

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    --DUSystem.print("test flush override ")
    if self.modeOn == false then return nil end --not enabled, bypass.
    params.AutoPilot_Settings.inertiaAutoBrake.value = false
    params.KeyBind_Params.shiftLock.value = false
    if Nav:getMasterMode() ~= "CRUISE" then
        DUSystem.print("Drone Flight++ force reset mode to CRUISE")
        PreviousMasterMode = Nav:getMasterMode()
        params.KeyBind_Params.flightMode.value = "CRUISE"
        Nav:setMasterMode("CRUISE")
        windowsShow()
    end
    -- Globals --
    -------------
    local cWCOM = DUConstruct.getWorldCenterOfMass()
    local cWCOMx, cWCOMy, cWCOMz = cWCOM[1], cWCOM[2], cWCOM[3]
    local cPCx, cPCy, cPCz = currentPlanetCenter[1], currentPlanetCenter[2], currentPlanetCenter[3]
    local wVx, wVy, wVz = cWCOMx-cPCx, cWCOMy-cPCy, cWCOMz-cPCz  -- world vertical
    altM = vectorLen(cWCOMx-cPCx, cWCOMy-cPCy, cWCOMz-cPCz) - currentPlanetRadius or 0 --Altitude to center of mass
    local cWAV = DUConstruct.getWorldVelocity()
    local cWAVx, cWAVy, cWAVz = cWAV[1], cWAV[2], cWAV[3]
    local nWVx, nWVy, nWVz = normalizeVec(wVx, wVy, wVz)
    planetVertSpeedMPS = dotVec(cWAVx, cWAVy, cWAVz, nWVx, nWVy, nWVz)
    local planetLatSpeedMPS = sqrt(vectorLen(cWAVx, cWAVy, cWAVz)^2-planetVertSpeedMPS^2)
    local cMAS = DUConstruct.getMaxAngularSpeed()

    local targetLongSpeed = 0 -- default braking if no input
    local targetLatSpeed = 0 -- default braking if no input
    local targetVertSpeed = 0 -- default braking if no input
    local tAVx, tAVy, tAVz = 0,0,0


    if self.modeRocket == true then
        --DUSystem.print("Rocket Mode "..Ax0)
        local finalRollInput = rollInput + DUSystem.getControlDeviceYawInput()
        local finalYawInput = yawInput - DUSystem.getControlDeviceLeftRightInput()

        tAVx = finalRollInput *  params.Engines_Settings.yawSpeedFactor.value * cWOFx
                + finalYawInput *  params.Engines_Settings.yawSpeedFactor.value * -cWOFx
                
        tAVy = finalRollInput *  params.Engines_Settings.yawSpeedFactor.value * cWOFy
                + finalYawInput *  params.Engines_Settings.yawSpeedFactor.value * -cWOFy
                
        tAVz = finalRollInput *  params.Engines_Settings.yawSpeedFactor.value * cWOFz
                + finalYawInput *  params.Engines_Settings.yawSpeedFactor.value * -cWOFz

        local pitchOffset = 90 + (-upInput * 30)
        if upInput ~= 0 then
            --no auto altitude calculations
        else
            --if not prevAltHoldAng then prevAltHoldAng = -4.8 end --This could be made modifyable, its the base angle required to maintain altitude
            local aAdj = prevAltHoldAng + clamp(planetVertSpeedMPS,-1,1)/1000
            pitchOffset = pitchOffset + clamp(planetVertSpeedMPS/10,-30,30) + aAdj
            prevAltHoldAng = aAdj
        end
    
        local pAVx, pAVy, pAVz = pitchAngularVelocity(wVx, wVy, wVz, pitchOffset + params.Engines_Settings.pitchAngleAdjustment.value, params.Engines_Settings.pitchSpeedFactor.value*0.5)
        tAVx = tAVx + pAVx
        tAVy = tAVy + pAVy
        tAVz = tAVz + pAVz

        if Ax0 < -45 and Ax0 > -135 then --auto yaw (roll) to stay flat
            local rAVx, rAVy, rAVz = rollAngularVelocity90(wVx, wVy, wVz, 0, 1)
            tAVx = tAVx + rAVx
            tAVy = tAVy + rAVy
            tAVz = tAVz + rAVz
        end

        if abs(Ax0) > 85 then self.warmup = false end
        if self.warmup then
            targetVertSpeed = params.Engines_Settings.amtoMaxSpeed.value * (abs(Ax0)/90)
        else
            targetVertSpeed = params.Engines_Settings.amtoMaxSpeed.value
        end

        return targetLongSpeed, targetLatSpeed, targetVertSpeed, tAVx, tAVy, tAVz

    elseif self.autoLand == true then
        --DUSystem.print('autoland')
        --TODO update autoland brake distance?
        local finalYawInput = yawInput - DUSystem.getControlDeviceLeftRightInput()
        tAVx = finalYawInput *  params.Engines_Settings.yawSpeedFactor.value * -cWOFx
        tAVy = finalYawInput *  params.Engines_Settings.yawSpeedFactor.value * -cWOFy
        tAVz = finalYawInput *  params.Engines_Settings.yawSpeedFactor.value * -cWOFz

        local pAVx, pAVy, pAVz = pitchAngularVelocity(wVx, wVy, wVz, 0, params.Engines_Settings.pitchSpeedFactor.value)
        tAVx = tAVx + pAVx
        tAVy = tAVy + pAVy
        tAVz = tAVz + pAVz
        local rAVx, rAVy, rAVz = rollAngularVelocity(wVx, wVy, wVz, 0, params.Engines_Settings.rollSpeedFactor.value)
        tAVx = tAVx + rAVx
        tAVy = tAVy + rAVy
        tAVz = tAVz + rAVz
        targetLongSpeed = 0
        targetLatSpeed = 0
        local raycast = self.hasATelemeter == true and self.telemeter[1] and self.telemeter[1].raycast() or nil
        local raycastDistance = 50
        if raycast then
            raycastDistance = type(raycast.distance) == "number" and raycast.distance > 0.2 and raycast.distance or 300
        end
        local brakeDist = self:BDC()
        
        targetVertSpeed = self.hasATelemeter == false and -50 or raycastDistance < 25 and -2.5*raycastDistance or brakeDist > 100 and -90 or -raycastDistance
        --DUSystem.print(targetVertSpeed)

        if not lPx then lPx, lPy, lPz = 0,0,0 end
        if params.Engines_Settings.engines.value == "AUTO" then
            local cWP = DUConstruct.getWorldPosition()
            local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
            if currentTime - landTime > 2 and abs(vectorLen(cWPx, cWPy, cWPz) - vectorLen(lPx, lPy, lPz)) < 0.1 and Engines == true then
                DUSystem.print("Switching off engines")
                Engines = false
                updateParams()
            elseif abs(vectorLen(cWPx, cWPy, cWPz) - vectorLen(lPx, lPy, lPz)) > 0.1 then
                lPx, lPy, lPz = cWPx, cWPy, cWPz -- land position
                landTime = currentTime
            end
        end

        return targetLongSpeed, targetLatSpeed, targetVertSpeed, tAVx, tAVy, tAVz
    elseif self.player.isSeated() == false and self.unit.isRemoteControlled() == true and self.follow == true and params.KeyBind_Params.movementLock.value == false then
        --DUSystem.print('follower mode on')

        local playerPos = self.player.getPosition()
        local pPosx, pPosy, pPosz = playerPos[1], playerPos[2], playerPos[3]
        local yaw2p = deg(atan(pPosx, pPosy)) --yaw angle to player
        local pDist = sqrt(pPosx^2 + pPosy^2 + pPosz^2) --distance from follower to player
        local playerWPos = self.player.getWorldPosition()
        local pWPosx, pWPosy, pWPosz = playerWPos[1], playerWPos[2], playerWPos[3]
        local pAlt = vectorLen(pWPosx-cPCx, pWPosy-cPCy, pWPosz-cPCz) - currentPlanetRadius or 0 --Player altitude
        
        -- Rotations --
        ---------------
        local tAVx ,tAVy,tAVz = 0, 0, 0
        if (Yaw2pPID == nil) then 
            Yaw2pPID = pid.new(0.05* params.Engines_Settings.yawSpeedFactor.value, 0, params.Engines_Settings.yawSpeedFactor.value)
        end
        Yaw2pPID:inject(0 - yaw2p)
        local yaw2pPIDget = Yaw2pPID:get()
        tAVx = tAVx + yaw2pPIDget * cWOUPx 
        tAVy = tAVy + yaw2pPIDget * cWOUPy
        tAVz = tAVz + yaw2pPIDget * cWOUPz

        local rAVx, rAVy, rAVz = rollAngularVelocity(wVx, wVy, wVz, 0, params.Engines_Settings.rollSpeedFactor.value)
        tAVx = tAVx + rAVx
        tAVy = tAVy + rAVy
        tAVz = tAVz + rAVz
        local brakeDist = abs(brakingCalculation())
        local pitchFactor = pDist > self.stopDistance and clamp(pDist-self.stopDistance-brakeDist, 0, 30) or 0
        local pAVx, pAVy, pAVz = pitchAngularVelocity(wVx, wVy, wVz, pitchFactor, params.Engines_Settings.pitchSpeedFactor.value)
        tAVx = tAVx + pAVx
        tAVy = tAVy + pAVy
        tAVz = tAVz + pAVz

        -- Thrust --
        ------------
        nwVx, nwVy, nwVz = normalizeVec(wVx, wVy, wVz)
        targetLatSpeed, targetLongSpeed, targetVertSpeed = 0, 0, 0
        local fVx, fVy, fVz = cross(nwVx, nwVy, nwVz, cWORx, cWORy, cWORz) -- right releative to gravity up
        fVx, fVy, fVz = multiplyVec(fVx, fVy, fVz, -Ax0)-- -planetVertSpeedMPS*3.6*3) -- increase speed
        if pDist > self.stopDistance then
            targetLatSpeed, targetLongSpeed, targetVertSpeed = world2local(fVx, fVy, fVz)
        end

        targetVertSpeed = targetVertSpeed + pAlt+self.altAdjust-altM
        
        return targetLongSpeed, targetLatSpeed, targetVertSpeed, tAVx, tAVy, tAVz, targetSpeed
    else
        --DUSystem.print('drone mode on')

        -- Final inputs --
        ------------------
        local finalPitchInput = pitchInput + DUSystem.getControlDeviceForwardInput()
        local finalRollInput = rollInput + DUSystem.getControlDeviceYawInput()
        local finalYawInput = yawInput - DUSystem.getControlDeviceLeftRightInput()
        local finalRotationInput = finalPitchInput + finalRollInput + finalYawInput
        local finalPRInput = abs(finalPitchInput) + abs(finalRollInput)

        -- Variables --
        ---------------
        local xySpeedKPH = sqrt(xSpeedKPH^2+ySpeedKPH^2)

        -- ROTATIONS --
        ---------------
        --TODO use this??
        --local dampenYaw = clamp((90-abs(Axy90))/90,0.01,1)
        local tAVx = finalYawInput * cMAS * params.Engines_Settings.yawSpeedFactor.value * cWOUPx
        local tAVy = finalYawInput * cMAS * params.Engines_Settings.yawSpeedFactor.value * cWOUPy
        local tAVz = finalYawInput * cMAS * params.Engines_Settings.yawSpeedFactor.value * cWOUPz

        -- DRONE FLIGHT VARIABLES --
        ----------------------------
        local strafeSpeed = 2000
        local pitchSensitivity = 1 --threshold in degrees
        local rollSensitivity = 1 --threshold in degrees
        longSpeedStrength = 0
        latSpeedStrength = 0
        vertSpeedStrength = 0
        --Ax0 --Pitch Angle (degrees)
        --Ay0 --Roll Angle (degrees)
        local Ax90 = abs(clamp(Ax0,-90,90)) -- -90 to 90 degrees pitch (clamped)
        local Ay90 = abs(clamp(Ay0,-90,90)) -- -90 to 90 degrees roll (clamped)
        Axy90 = abs(90-deg(atan( 1 / sqrt( math.tan(rad(Ax0))^2 + math.tan(rad(Ay0))^2 ) ))) -- 0 to 90 Actual angle relative to horizontal (degrees)

        -- Shift Adjustments --
        -----------------------
        local rollModifier = 0
        local pitchModifier = 0
        local targetTravelSpeed = 0
        local targetSpeed = 0
        if finalPRInput ~= 0 then
            if SHIFT == false then
                rollModifier = self.cruiseAngle --35.3
                pitchModifier = self.cruiseAngle
                targetTravelSpeed = self.cruiseSpeed
            elseif SHIFT == true then
                rollModifier = self.shiftAngle
                pitchModifier = self.shiftAngle
                targetTravelSpeed = self.shiftSpeed
            end
        else
            targetTravelSpeed = 0
            --self.targetSpeedPID:reset()
        end
        self.targetSpeedPID:inject(targetTravelSpeed-xyzSpeedKPH)
        targetSpeed = self.targetSpeedPID:get() + xyzSpeedKPH
        
        -- Roll Stabilization & Drone Rolling --
        ----------------------------------------
        if abs(Ax0) < 89 then 
            local rollOffset = finalRollInput * rollModifier
            local rAVx, rAVy, rAVz = rollAngularVelocity(wVx, wVy, wVz, 0 + rollOffset, params.Engines_Settings.rollSpeedFactor.value)
            tAVx = tAVx + rAVx
            tAVy = tAVy + rAVy
            tAVz = tAVz + rAVz
        end

        --Pitch Stabilization & Drone Pitching --
        -----------------------------------------
        local cAV = DUConstruct.getWorldVelocity()
        local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
        local gravity = self.core.getWorldGravity()
        local gx, gy, gz = gravity[1], gravity[2], gravity[3]
        local WAFA = DUConstruct.getWorldAirFrictionAcceleration()
        local WAFAx, WAFAy, WAFAz = WAFA[1], WAFA[2], WAFA[3]

        if finalYawInput == 0 and finalPitchInput == 0 and finalRollInput == 0 and upInput <= 0
        and self.backBurn == true 
        then
            -- BackBurn --
            local axx, axy, axz, an = 0,0,0,0
            local nwVx, nwVy, nwVz = normalizeVec(wVx, wVy, wVz) -- normalized world vector (negative grav.)
            local ncWAVx, ncWAVy, ncWAVz = normalizeVec(cWAVx, cWAVy, cWAVz)
            local vAngle = acos(dotVec(ncWAVx, ncWAVy, ncWAVz, nwVx, nwVy, nwVz) / (vectorLen(ncWAVx, ncWAVy, ncWAVz) * vectorLen(nwVx, nwVy, nwVz)))*rad2deg
            if vAngle < 15 and planetVertSpeedMPS > 9 then 
            local ux, uy, uz = multiplyVec(-gx,-gy,-gz,1)
            axx, axy, axz, an = getAAR(cWOUPx, cWOUPy, cWOUPz, cWAVx+ux, cWAVy+uy, cWAVz+uz, 0, 0, 0)
            else
            local ux, uy, uz = multiplyVec(gx,gy,gz,1.8)
            axx, axy, axz, an = getAAR(-cWOUPx, -cWOUPy, -cWOUPz, cWAVx+ux, cWAVy+uy, cWAVz+uz, 0, 0, 0)
            end
            local aFact = clamp(an*rad2deg/40,-1,1) -- 40 = less sensitive
            tAVx = axx * aFact
            tAVy = axy * aFact
            tAVz = axz * aFact

        else
            -- Stabilization & Drone Rolling --
            local angF = SHIFT == true and self.shiftAngle or self.cruiseAngle
            local rAVx, rAVy, rAVz = rollAngularVelocity(wVx, wVy, wVz, 0 + finalRollInput * angF, params.Engines_Settings.rollSpeedFactor.value)
            local pAVx, pAVy, pAVz = pitchAngularVelocity(wVx, wVy, wVz, 0 - finalPitchInput * angF , params.Engines_Settings.pitchSpeedFactor.value)
            tAVx = tAVx + pAVx + rAVx
            tAVy = tAVy + pAVy + rAVy
            tAVz = tAVz + pAVz + rAVz
        end

        -- Vector Manipulation --
        -------------------------
        local nwVx, nwVy, nwVz = normalizeVec(wVx, wVy, wVz) -- normalized world vector (negative grav.)
        local wLx, wLy, wLz = cross(nwVx, nwVy, nwVz, cWOUPx, cWOUPy, cWOUPz) -- world left
        local wFx, wFy, wFz = normalizeVec(cross(-nwVx, -nwVy, -nwVz, wLx, wLy, wLz)) -- world forward (forward perpendicular to grav.)
        local cFx, cFy, cFz = normalizeVec(cross(wLx, wLy, wLz, cWOUPx, cWOUPy, cWOUPz)) -- construct forward
 
        local fGA = dotVec(gx, gy, gz, cFx, cFy, cFz) -- forward grav. acceleration (my forward engine)
        local fAirA = dotVec(WAFAx, WAFAy, WAFAz, cFx, cFy, cFz) -- forward air resistance acceleration
        local fTotA = fGA + fAirA -- forward total acceleration
        local fS = dotVec(cWAVx, cWAVy, cWAVz, cFx, cFy, cFz) -- forward speed
 
        -- Angle from world vertical (radians)
        local fAngle = acos(dotVec(cWOUPx, cWOUPy, cWOUPz, nwVx, nwVy, nwVz) / (vectorLen(cWOUPx, cWOUPy, cWOUPz) * vectorLen(nwVx, nwVy, nwVz)))
        local adjacent = fTotA + fS
        local hyp = adjacent/math.cos(fAngle)
        local tVx, tVy, tVz = multiplyVec(wFx, wFy, wFz, hyp) -- scale to max grav. thrust
 
        -- Downinput shifts vector down
        local downInput = upInput < 0 and abs(upInput) or 0 -- downInput
        local dVx, dVy, dVz = multiplyVec(-nwVx, -nwVy, -nwVz, downInput*(abs(planetVertSpeedMPS)+hyp+50))
        local tVx, tVy, tVz = tVx+dVx, tVy+dVy, tVz+dVz -- add downinput vector
 
        -- Convert back to local coords
        local tLVx, tLVy, tLVz = world2local(tVx, tVy, tVz)
        targetLatSpeed, targetLongSpeed, targetVertSpeed = multiplyVec(tLVx, tLVy, tLVz, 3.6) -- convert to kph
 
        -- MODIFIERS --
        local ncWAVx, ncWAVy, ncWAVz = normalizeVec(cWAVx, cWAVy, cWAVz)
        local VvsNZang = acos(dotVec(-cWOUPx, -cWOUPy, -cWOUPz, ncWAVx, ncWAVy, ncWAVz) / (vectorLen(-cWOUPx, -cWOUPy, -cWOUPz) * vectorLen(ncWAVx, ncWAVy, ncWAVz)))*rad2deg
        --angle between velocity vector and -z axis (when to brake)
        if brakeInput == 1 
        or finalYawInput == 0 and finalPitchInput == 0 and finalRollInput == 0 and upInput == 0 
        and (
          VvsNZang < 95 or VvsNZang > 165 or xyzSpeedKPH < 0.01
        )
        then
            targetLatSpeed, targetLongSpeed, targetVertSpeed = 0,0,0
        end
      
        local targetForwardSpeed = dotVec(tVx, tVy, tVz, cFx, cFy, cFz)
        local targetForwardAcceleration = targetForwardSpeed - fS
        local forwardRemainingAcceleration = fTotA - targetForwardAcceleration
 
        -- only up, not down input --
        local extraVertSpeed = upInput > 0 and upInput*strafeSpeed or 0
        targetVertSpeed = targetVertSpeed + extraVertSpeed

        return targetLongSpeed, targetLatSpeed, targetVertSpeed, tAVx, tAVy, tAVz
    end
end
--DUSystem.print(longSpeed.." / "..latSpeed.." / "..vertSpeed.." / "..otAVx.." / "..otAVy.." / "..otAVz)

----------------
-- WIDGET SVG --
----------------
function WidgetsPlusPlusCustom.SVG_Update(self)
    local WTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local WFC = params.Menu_Settings.WIDGET_FIXED_COLOR.value
    local WAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value

        local bf = function() return function()
                            self.modeOn =  not self.modeOn
                            DUSystem.print("Drone mode has been toggled: "..tostring(self.modeOn))
                            --if self.modeOn == false then
                            --    params.KeyBind_Params.flightMode.value = PreviousMasterMode
                            --    Nav:setMasterMode(PreviousMasterMode)
                            --else
                            --    params.KeyBind_Params.flightMode.value = "CRUISE"
                            --    Nav:setMasterMode("CRUISE")
                            --end
                            --self:saveData()
                            windowsShow() --command to refresh wdgets
                    end end
        local btText = "Drone Mode activated: "..tostring(self.modeOn)
        self.buttons[1] = {btText, bf(), {name = "DM_button1", class = nil, width = 225, height = 25, posX = 5, posY = 75}}

        bf = function() return function()
                            self.follow = not self.follow
                            if self.follow == true then params.KeyBind_Params.movementLock.value = false end
                            windowsShow()
                    end end
        btText = "Follower Mode: "..tostring(self.follow)
        self.buttons[2] = {btText, bf(), {name = "DM_button2", class = nil, width = 225, height = 25, posX = 5, posY = 105}}

        bf = function() return function()
                            params.KeyBind_Params.movementLock.value = not params.KeyBind_Params.movementLock.value
                            windowsShow()
                    end end
        btText = "Freeze Movement: "..tostring(params.KeyBind_Params.movementLock.value)
        self.buttons[3] = {btText, bf(), {name = "DM_button3", class = nil, width = 225, height = 25, posX = 5, posY = 135}}

        bf = function() return function()
                            if mouseWheel == 0 then
                                --DUSystem.print("Hello world!")
                            elseif mouseWheel > 0 then
                                self.altAdjust = clamp(self.altAdjust+0.5,0,100)
                            elseif mouseWheel < 0 then
                                self.altAdjust = clamp(self.altAdjust-0.5,0,100)
                            end
                            windowsShow()
                    end end
        btText = "followALT: "..self.altAdjust
        self.buttons[4] = {btText, bf(), {name = "DM_button4", class = nil, width = 110, height = 25, posX = 5, posY = 165}}

        bf = function() return function()
                            if mouseWheel == 0 then
                                --DUSystem.print("Hello world!")
                            elseif mouseWheel > 0 then
                                self.cruiseAngle = clamp(self.cruiseAngle+1,1,89)
                            elseif mouseWheel < 0 then
                                self.cruiseAngle = clamp(self.cruiseAngle-1,1,89)
                            end
                            windowsShow()
                    end end
        btText = "cruiseAngle: "..self.cruiseAngle
        self.buttons[5] = {btText, bf(), {name = "DM_button5", class = nil, width = 110, height = 25, posX = 120, posY = 165}}

        bf = function() return function()
                            if mouseWheel == 0 then
                                --DUSystem.print("Hello world!")
                            elseif mouseWheel > 0 then
                                self.stopDistance = clamp(self.stopDistance+0.5,0,100)
                            elseif mouseWheel < 0 then
                                self.stopDistance = clamp(self.stopDistance-0.5,0,100)
                            end
                            windowsShow()
                    end end
        btText = "followDist: "..self.stopDistance
        self.buttons[6] = {btText, bf(), {name = "DM_button6", class = nil, width = 110, height = 25, posX = 5, posY = 195}}

        bf = function() return function()
                            if mouseWheel == 0 then
                                --DUSystem.print("Hello world!")
                            elseif mouseWheel > 0 then
                                self.shiftAngle = clamp(self.shiftAngle+1,1,89)
                            elseif mouseWheel < 0 then
                                self.shiftAngle = clamp(self.shiftAngle-1,1,89)
                            end
                            windowsShow()
                    end end
        btText = "shiftAngle: "..self.shiftAngle
        self.buttons[7] = {btText, bf(), {name = "DM_button7", class = nil, width = 110, height = 25, posX = 120, posY = 195}}

        bf = function() return function()
                            self.backBurn = not self.backBurn
                            windowsShow()
                    end end
        btText = "Backburn: "..tostring(self.backBurn)
        self.buttons[8] = {btText, bf(), {name = "DM_button8", class = nil, width = 225, height = 25, posX = 5, posY = 225}}

        local altDiffBar = clamp(planetVertSpeedMPS*-10,-110,110)
        local ry = altDiffBar > 0 and 116 or 116+altDiffBar
        altDiffBar = ry == 116 and altDiffBar or -altDiffBar
        local sO = altDiffBar ~= 0 and 0.5 or 0
        --DUSystem.print(ry..' / '..altDiffBar) self.backBurn = false

    local SVG = [[
        <rect x="240" y="5" width="15" height="222" stroke="]]..WFC..[[" stroke-width="1" fill="none"/>
        <line x1="240" y1="116" x2="255" y2= "116" stroke="]]..WFC..[[" stroke-width="1"/>
        <rect x="240.5" y="]].. format("%.0f",ry) ..[[" width="14" height="]].. format("%.0f",altDiffBar) ..[[" stroke="none" fill="]]..WAC..[[" fill-opacity="]]..sO..[["/>
        <text x="5" y="5" font-size="15" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]].."By: theGreatSardini"..[[</text> 
        <text x="5" y="30" font-size="12" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]].."Middle mouse = Rocket / G = auto land"..[[</text> 
    ]]
    
    SVG = '<div><svg viewBox="0 0 '.. self.SVGSize.x ..' '.. self.SVGSize.y ..'">'..SVG..'</svg></div>'
    return SVG
end