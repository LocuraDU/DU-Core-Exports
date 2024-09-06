-- ################################################################################
-- #                       Copyright JERONIMO 2021                                #
-- ################################################################################

local utils = require("cpml/utils")
local pid = require("cpml/pid")

local clamp, abs, sqrt, min, max = utils.clamp, math.abs, math.sqrt, math.min, math.max
MasterModeList = {
    "CRUISE",
    "TRAVEL",
    "PARKING",
    "SPORT",
}

NavigatorPlusPlus = {}
NavigatorPlusPlus.__index = NavigatorPlusPlus

function NavigatorPlusPlus.new(core,unit)
    local self = setmetatable({}, NavigatorPlusPlus)
    self.unit = unit
    self.core = core
    
    self.boosterState = 0
    self.boosterStateHasChanged = false
    self.boosterMaxSpeed = 1200
    
    self.MasterMode = "CRUISE"
    self.previousMasterMode = ""
    self.throttleValue = 0
    self.previousThrottleValue = 0
    self.mouseWheelValue = 0
    self.maxSpeedKMPH = 49999
    self.targetSpeedRangesSteps = {10,25,100,500,1000}
    self.targetSpeedRanges = {100,200,2000,6000,49999}
    self.currentTargetSpeedStep = 0
    self.atmoMaxSpeed = 1200
    
    self.TargetLongitudinalSpeedPID = pid.new(1, 0, 10)
    self.TargetLateralSpeedPID = pid.new(1, 0, 10)
    self.TargetVerticalSpeedPID = pid.new(1, 0, 10)
    self.LongitudinalBrakePID = pid.new(1, 0, 10)
    self.LateralBrakePID = pid.new(1, 0, 10)
    self.VerticalBrakePID = pid.new(1, 0, 10)
    
    self.targetGAC = self.unit.computeGroundEngineAltitudeStabilizationCapabilities()
    return self
end

function NavigatorPlusPlus.setAtmoMaxSpeed(self,speed)
    self.atmoMaxSpeed = speed
end

function NavigatorPlusPlus.getAtmoMaxSpeed(self)
    return self.atmoMaxSpeed
end

------------------
-- Throttle setup
------------------
function NavigatorPlusPlus.setupCustomTargetSpeedRanges(self, customTargetSpeedRanges)
    self.customTargetSpeedRanges = customTargetSpeedRanges
end

function NavigatorPlusPlus.getTargetSpeedRangeStep(self,value)
    for i, v in ipairs(self.targetSpeedRanges) do
        self.currentTargetSpeedStep = self.targetSpeedRangesSteps[i]
        if value > 0 then
            if abs(self.throttleValue) < v then
                return self.currentTargetSpeedStep
            end
        else
            if abs(self.throttleValue) <= v then
                if self.targetSpeedRangesSteps[i-1] ~= nil then
                    if abs(self.throttleValue) - self.currentTargetSpeedStep <= self.targetSpeedRanges[i-1] then
                        self.currentTargetSpeedStep = abs(self.throttleValue) - self.targetSpeedRanges[i-1]
                    end
                end
                return self.currentTargetSpeedStep
            end
        end
    end
end

function NavigatorPlusPlus.updateThrottleValue(self,value)
    if self.MasterMode == "CRUISE" then
        self.throttleValue = clamp(self.throttleValue + value * self:getTargetSpeedRangeStep(value),-self.maxSpeedKMPH,self.maxSpeedKMPH)
    elseif self.MasterMode == "TRAVEL" or self.MasterMode == "SPORT" then
        self.throttleValue = clamp(self.throttleValue + value/10,-1,1)
    else self.throttleValue = 0
    end
    if abs(self.throttleValue) < 0.01 then self.throttleValue = 0 end
end

function NavigatorPlusPlus.setThrottleValue(self,value)
    if self.MasterMode == "CRUISE" then
        self.throttleValue = clamp(value,-self.maxSpeedKMPH,self.maxSpeedKMPH)
        --DUSystem.print("cruise set throttle value")
    elseif self.MasterMode == "TRAVEL" or self.MasterMode == "SPORT" then
        self.throttleValue = clamp(value,-1,1)
    else self.throttleValue = 0
    end
end

function NavigatorPlusPlus.resetThrottleValue(self)
    self.throttleValue = 0
end

function NavigatorPlusPlus.getThrottleValue(self)
    return self.throttleValue
end

---------------
-- Master mode
---------------
function NavigatorPlusPlus.setMasterMode(self,mode)
--DUSystem.print("nav: "..mode)
    local cAV = DUConstruct.getVelocity()
    local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
    local xyzSpeedKPH = sqrt((cAVx^2+cAVy^2+cAVz^2))*3.6
    if xyzSpeedKPH < 10 then
        self.MasterMode = mode
    else
        if mode == "CRUISE" or mode ~= "TRAVEL" then self.MasterMode = "CRUISE" end
        if mode == "TRAVEL" then self.MasterMode = "TRAVEL" end
    end
    if self.MasterMode == "CRUISE" then
        self.throttleValue = xyzSpeedKPH
    elseif self.MasterMode == "TRAVEL" or self.MasterMode == "PARKING" or self.MasterMode == "SPORT" then
        self:resetThrottleValue()
    end
    self.TargetLongitudinalSpeedPID:reset()
    self.TargetLateralSpeedPID:reset()
    self.TargetVerticalSpeedPID:reset()
--DUSystem.print("nav: "..mode)
end

--function NavigatorPlusPlus.cycleMasterMode(self)
--    local function valUp(t,val)
--        local index = TABLE.index(t,val)
--        local newVal 
--        if index == nil then
--            newVal = t[1]
--        elseif t[index+1] == nil then
--            newVal = t[1]
--        else
--            newVal = t[index+1]
--        end
--        return newVal
--    end
--    self:setMasterMode(valUp(MasterModeList,self.MasterMode))
--end

function NavigatorPlusPlus.getMasterMode(self)
    return self.MasterMode
end

---------
-- Update
---------
function NavigatorPlusPlus.throttleUpdate(self)
    local ThrottleInputFromMouseWheel = DUSystem.getThrottleInputFromMouseWheel() --getMouseWheel()
        if self.mouseWheelValue ~= ThrottleInputFromMouseWheel then
            self:updateThrottleValue(ThrottleInputFromMouseWheel)
        end
    self.mouseWheelValue = ThrottleInputFromMouseWheel
end

function NavigatorPlusPlus.updateMaxSpeed(self,speed)
    self.maxSpeedKMPH = speed
    self.targetSpeedRanges = {100,200,2000,6000,self.maxSpeedKMPH}
end

-----------------
-- Acceleration 
----------------
function NavigatorPlusPlus.maxForceForward(self)
    local cOF = DUConstruct.getOrientationForward()
    local maxKPAlongAxis = DUConstruct.getMaxThrustAlongAxis('thrust analog longitudinal', cOF)
    if inspace == 1 then
        return maxKPAlongAxis[3]~= nil and maxKPAlongAxis[3] or 0
    else
        return maxKPAlongAxis[1]~= nil and maxKPAlongAxis[1] or 0
    end
end

function NavigatorPlusPlus.maxForceBackward(self)
    local cOF = DUConstruct.getOrientationForward()
    local maxKPAlongAxis = DUConstruct.getMaxThrustAlongAxis('thrust analog longitudinal', cOF)
    if inspace == 1 then
        return maxKPAlongAxis[4]~= nil and maxKPAlongAxis[4] or 0
    else
        return maxKPAlongAxis[2]~= nil and maxKPAlongAxis[2] or 0
    end
end

function NavigatorPlusPlus.getMaxKPA(self)
    return self:maxForceForward(), self:maxForceBackward()
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

function NavigatorPlusPlus.composeAccelerationFromTargetSpeed(self,axis,speed) --axis: longitudinal / lateral / vertical // speed: in kmph
--DUSystem.print("1")
    local cAV = DUConstruct.getWorldVelocity()
--DUSystem.print("1aa")
    local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
    local gravity = self.core.getWorldGravity()
    local gx, gy, gz = gravity[1], gravity[2], gravity[3]
--DUSystem.print("1a")
    local AWDx, AWDy, AWDz = 0, 0, 0 --AxisWorldDirection
    local AxisSpeed = 0
    tSpeed = clamp(speed, -self.maxSpeedKMPH+10, self.maxSpeedKMPH-10)
    if inspace == 0 and tSpeed ~= 0 then
        tSpeed = clamp(tSpeed, -self.atmoMaxSpeed, self.atmoMaxSpeed)
    end
    tSpeed = tSpeed * 0.27777777777
    
--DUSystem.print("2")
    if axis == "longitudinal" then
        AWDx, AWDy, AWDz = cWOFx, cWOFy, cWOFz
        AxisSpeed = dotVec(cAVx, cAVy, cAVz, AWDx, AWDy, AWDz)
    elseif axis == "lateral" then
        AWDx, AWDy, AWDz = cWORx, cWORy, cWORz
        AxisSpeed = dotVec(cAVx, cAVy, cAVz, AWDx, AWDy, AWDz)
    elseif axis == "vertical" then
        AWDx, AWDy, AWDz = cWOUPx, cWOUPy, cWOUPz
        AxisSpeed = dotVec(cAVx, cAVy, cAVz, AWDx, AWDy, AWDz)
    end
--DUSystem.print("3")
    local GravityAccelerationCommand = dotVec(gx, gy, gz, AWDx, AWDy, AWDz) --DUSystem.print("3a")
    local WAFA = DUConstruct.getWorldAirFrictionAcceleration() --DUSystem.print("3b")--getWorldAirFrictionAcceleration
    local WAFAx, WAFAy, WAFAz = WAFA[1], WAFA[2], WAFA[3] --DUSystem.print("3c")
    local AirResistanceAccelerationCommand = dotVec(WAFAx, WAFAy, WAFAz, AWDx, AWDy, AWDz) --DUSystem.print("3d")--AirResistanceAccelerationCommand
--DUSystem.print("4")
    local AccelerationCommand = 0 --self.TargetSpeedPID:get()
    
    if axis == "longitudinal" then
        self.TargetLongitudinalSpeedPID:inject(tSpeed - AxisSpeed)
        AccelerationCommand = self.TargetLongitudinalSpeedPID:get()
        --DUSystem.print((tSpeed - AxisSpeed)*3.6)
    elseif axis == "lateral" then
        self.TargetLateralSpeedPID:inject(tSpeed - AxisSpeed)
        AccelerationCommand = self.TargetLateralSpeedPID:get()
    elseif axis == "vertical" then
        self.TargetVerticalSpeedPID:inject(tSpeed - AxisSpeed)
        AccelerationCommand = self.TargetVerticalSpeedPID:get()
    end
    --DUSystem.print(axis.." / "..speed.." / "..AccelerationCommand.." / "..GravityAccelerationCommand.." / "..AirResistanceAccelerationCommand)
    local AAG = AccelerationCommand - GravityAccelerationCommand - AirResistanceAccelerationCommand 
    local FAx = AAG * AWDx
    local FAy = AAG * AWDy
    local FAz = AAG * AWDz
--DUSystem.print("5")
    return FAx, FAy, FAz
end

function NavigatorPlusPlus.composeBrakeAcceleration(self,axis,speed)
--DUSystem.print(vtSpeed)
    local cAV = DUConstruct.getWorldVelocity()
    local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
    local gravity = self.core.getWorldGravity()
    local gx, gy, gz = gravity[1], gravity[2], gravity[3]
    local AWDx, AWDy, AWDz = 0, 0, 0 --AxisWorldDirection
    local gravityAccelerationCommand = 0
    local accelerationCommand = 0
    local AirResistanceAccelerationCommand = 0
    local aRAC = 0
    local AxisSpeed = 0
    local BAx, BAy, BAz = 0, 0, 0
    speed = speed ~= nil and speed * 0.27777777777 or 0
    axis = axis ~= nil and axis or "longitudinal"
    local WAFA = DUConstruct.getWorldAirFrictionAcceleration() --DUSystem.print("3b")--getWorldAirFrictionAcceleration
    local WAFAx, WAFAy, WAFAz = WAFA[1], WAFA[2], WAFA[3] --DUSystem.print("3c")
--DUSystem.print("1a")

    if axis == "longitudinal" then
        AWDx, AWDy, AWDz = cWOFx, cWOFy, cWOFz
        AxisSpeed = dotVec(cAVx, cAVy, cAVz, AWDx, AWDy, AWDz)
        gravityAccelerationCommand = dotVec(gx, gy, gz, cWOFx, cWOFy, cWOFz)
        accelerationCommand = speed - AxisSpeed
        AirResistanceAccelerationCommand = dotVec(WAFAx, WAFAy, WAFAz, AWDx, AWDy, AWDz)
        aRAC = accelerationCommand - gravityAccelerationCommand - AirResistanceAccelerationCommand
        BAx, BAy, BAz = aRAC * cWOFx, aRAC * cWOFy, aRAC * cWOFz
    elseif axis == "lateral" then
        AWDx, AWDy, AWDz = cWORx, cWORy, cWORz
        AxisSpeed = dotVec(cAVx, cAVy, cAVz, AWDx, AWDy, AWDz)
        gravityAccelerationCommand = dotVec(gx, gy, gz, cWORx, cWORy, cWORz)
        accelerationCommand = speed - AxisSpeed
        AirResistanceAccelerationCommand = dotVec(WAFAx, WAFAy, WAFAz, AWDx, AWDy, AWDz)
        aRAC = accelerationCommand - gravityAccelerationCommand - AirResistanceAccelerationCommand
        BAx, BAy, BAz = aRAC * cWORx, aRAC * cWORy, aRAC * cWORz
    elseif axis == "vertical" then
        AWDx, AWDy, AWDz = cWOUPx, cWOUPy, cWOUPz
        AxisSpeed = dotVec(cAVx, cAVy, cAVz, AWDx, AWDy, AWDz)
        gravityAccelerationCommand = dotVec(gx, gy, gz, cWOUPx, cWOUPy, cWOUPz)
        accelerationCommand = speed - AxisSpeed
        AirResistanceAccelerationCommand = dotVec(WAFAx, WAFAy, WAFAz, AWDx, AWDy, AWDz)
        aRAC = accelerationCommand - gravityAccelerationCommand - AirResistanceAccelerationCommand
        BAx, BAy, BAz = aRAC * cWOUPx, aRAC * cWOUPy, aRAC * cWOUPz
    end

    return BAx, BAy, BAz
end

function NavigatorPlusPlus.composeAccelerationFromThrottle(self)
    if inspace == 0 and self.atmoMaxSpeed > 0 and xyzSpeedKPH > self.atmoMaxSpeed - 5 then
        local FAx, FAy, FAz = self:composeAccelerationFromTargetSpeed('longitudinal',self.atmoMaxSpeed) --axis: longitudinal / lateral / vertical // speed: in kmph
        return FAx, FAy, FAz
    else
        local cM = DUConstruct.getTotalMass()
        local forceCorrespondingToThrottle = 0
        if self.throttleValue > 0 then
            local maxAtmoForceForward = self:maxForceForward()
            forceCorrespondingToThrottle = self.throttleValue * maxAtmoForceForward
        elseif self.throttleValue < 0 then
            local maxAtmoForceBackward = self:maxForceBackward()
            forceCorrespondingToThrottle = -self.throttleValue * maxAtmoForceBackward
        end
        local AccelerationCommand = forceCorrespondingToThrottle / cM
        local FAx = AccelerationCommand * cWOFx
        local FAy = AccelerationCommand * cWOFy
        local FAz = AccelerationCommand * cWOFz
        --DUSystem.print(self:maxForceBackward())
        return FAx, FAy, FAz
    end
end

function NavigatorPlusPlus.updateHovers(self,input,hoverAlt,mode)
    if mode == "STATIC" then
        if input == 0 then
            if hoverAlt ~= nil then
                hoverAlt = clamp(hoverAlt, -999999, self.targetGAC[1])
                if Engines == true then
                    self.unit.activateGroundEngineAltitudeStabilization(hoverAlt)
                end
            end
        else
            self.unit.deactivateGroundEngineAltitudeStabilization()
        end
    else self.unit.deactivateGroundEngineAltitudeStabilization()
    end
end

--function NavigatorPlusPlus.setBoosterCommand(self,state,speed)
--    --if (self.atmosphereDensity < 0.09 or (self.worldVelocity.y < speed and self.atmosphereDensity > 0.09) or speed < 0) and state == 1 and self.boosterState == 0 then
--    --    if self.MasterMode == "CRUISE" then
--    --        self.previousMasterMode = self.MasterMode
--    --        self:setMasterMode("TRAVEL")
--    --    end
--    --    self.boosterState = 1
--    --    self.unit.setEngineThrust('rocket_engine',1)
--    --    DUSystem.print("Boosters on")
--    --    self.throttleValue = 1
--    --elseif self.boosterState == 1 and state == 0 then
--    --    DUSystem.print("Boosters off")
--    --    self.boosterState = 0
--    --    self.unit.setEngineThrust('rocket_engine', 0)
--    --    if self.previousMasterMode == "CRUISE" then
--    --        self:setMasterMode("CRUISE")
--    --        self.previousMasterMode = ""
--    --        DUSystem.print("MasterMode back to cruise unit")
--    --    end
--    --end
--end
