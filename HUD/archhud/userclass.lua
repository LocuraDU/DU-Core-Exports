--- Enables a "Lite" version of the HUD along with AR
--- Aims for showing vital information while using less system resources
--- Press Alt + 3 to toggle between Lite and default HUDs
--- Note: This replaces the mode where the HUD is hidden!
local enableLiteHud = true

userBase = (function()
  --[[
    Embed our libraries for template rendering
  ]]

  local SmartTemplateLibrary = (function ()
    --[[
      Wolfe Labs Smart Template Library (STL)
      A simple, Twig-like templating language for Lua
      Syntax:
        {{ variable }} prints the contents of "variable"
        {% some_lua_code %} executes the Lua code, useful for creating blocks like {% if %} and {% else %}, make sure you add {% end %} too :)
      (C) 2022 - Wolfe Labs
    ]]
  
    --- Helper function that generates a clean print statement of a certain string
    ---@param str string The string we need to show
    ---@return string
    local function mkPrint(str)
      return 'print(\'' .. str:gsub('\'', '\\\''):gsub('\n', '\\n') .. '\')'
    end
  
    --- Helper function that merges tables
    ---@vararg table
    ---@return table
    local function tMerge(...)
      local tables = {...}
      local result = {}
      for _, t in pairs(tables) do
        for k, v in pairs(t) do
          result[k] = v
        end
      end
      return result
    end
  
    ---@class Template
    local Template = {
      --- Globals available for every template by default
      globals = {
        math = math,
        table = table,
        string = string,
        ipairs = ipairs,
        pairs = pairs,
      }
    }
  
    -- Makes our template directly callable
    function Template.__call(self, ...)
      return Template.render(self, ({...})[1])
    end
  
    --- Renders our template
    ---@param vars table The variables to be used when rendering the template
    ---@return string
    function Template:render(vars)
      -- Safety check, vars MUST be a table or nil
      if type(vars or {}) ~= 'table' then
        error('Template parameters must be a table, got ' .. type(vars))
      end
      
      --- This is our return buffer
      local _ = {}
  
      -- Creates our environment
      local env = tMerge(Template.globals, self.globals or {}, vars or {}, {
        print = function (str) table.insert(_, tostring(str or '')) end,
      })
  
      -- Invokes our template
      self.callable(env)
  
      -- General trimming
      local result = table.concat(_, ''):gsub('%s+', ' ')
  
      -- Trims result
      result = result:sub(result:find('[^%s]') or 1):gsub('%s*$', '')
  
      -- Done
      return result
    end
  
    --- Creates a new template
    ---@param source string The code for your template
    ---@param globals table Global variables to be used on on the template
    ---@param buildErrorHandler function A function to handle build errors, if none is found throws an error
    ---@return Template
    function Template.new(source, globals, buildErrorHandler)
      -- Creates our instance
      local self = {
        source = source,
        globals = globals,
      }
  
      -- Yield function (mostly for games who limit executions per frame)
      local yield = (coroutine and coroutine.isyieldable() and coroutine.yield) or function () end
  
      -- Parses direct printing of variables, we'll convert a {{var}} into {% print(var) %}
      source = source:gsub('{{(.-)}}', '{%% print(%1) %%}')
  
      -- Ensures {% if %} ... {% else %} ... {% end %} stays on same line
      source = source:gsub('\n%s*{%%', '{%%')
      source = source:gsub('%%}\n', '%%}')
  
      --- This variable stores all our Lua "pieces"
      local tPieces = {}
  
      -- Parses actual Lua inside {% lua %} tags
      while #source > 0 do
        --- The start index of Lua tag
        local iLuaStart = source:find('{%%')
  
        --- The end index of Lua tag
        local iLuaEnd = source:find('%%}')
  
        -- Checks if we have a match
        if iLuaStart then
          -- Errors when not closing a tag
          if not iLuaEnd then
            error('Template error, missing Lua closing tag near: ' .. source:sub(0, 16))
          end
  
          --- The current text before Lua tag
          local currentText = source:sub(1, iLuaStart - 1)
          if #currentText then
            table.insert(tPieces, mkPrint(currentText))
          end
  
          --- Our Lua tag content
          local luaTagContent = source:sub(iLuaStart, iLuaEnd + 1):match('{%%(.-)%%}') or ''
          table.insert(tPieces, luaTagContent)
  
          -- Removes parsed content
          source = source:sub(iLuaEnd + 2)
        else
          -- Adds remaining Lua as a single print statement
          table.insert(tPieces, mkPrint(source))
  
          -- Marks content as parsed
          source = ''
        end
  
        -- Yields loading
        yield()
      end
  
      -- Builds the Lua function
      self.code = table.concat(tPieces, '\n')
  
      -- Builds our function and caches it, this is our template now
      local _, err = load(string.format([[return function (_) _ENV = _; _ = _ENV[_]; %s; end]], self.code), nil, 't', {})
      if _ and not err then
        _ = _()
      end
  
      -- Checks for any errors
      if err then
        if buildErrorHandler then
          buildErrorHandler(self, err)
        else
          error('Failed compiling template: ' .. err)
        end
  
        -- Retuns an invalid instance
        return nil
      else
        -- If everything passed, assigns our callable to our compiled function
        self.callable = _
      end
  
      -- Initializes our instance
      return setmetatable(self, Template)
    end
  
    -- By default, returns the constructor of our class
    return Template.new
  end)()
  
  local function SmartTemplate(code, globals)
    return SmartTemplateLibrary(code, globals, function(template, err)
      DUSystem.print(' [ERROR] Failed compiling template: ' .. err)
      DUSystem.print('[SOURCE] ' .. code)
      error()
    end)
  end

  --[[
    Initialize any important constants and globals
  ]]

  local json = require('json')
  
  local core, unit, system, library, construct = nil, nil, DUSystem, DULibrary, DUConstruct

  hasInitialized, result = pcall(function()
    -- Initializes our atlas as a map of body ID to body info
    local atlas = {}
    for systemId, celestialBodies in pairs(require('atlas') or {}) do
      for celestialBodyId, celestialBody in pairs(celestialBodies) do
        atlas[celestialBodyId] = celestialBody
      end
    end

    --- Distance to "infinity", used when projecting AR directions, set to 100su
    local infinityDistance = 100 * 200000

    --- This is our "reference" gravity value, it will be calculated below
    ---@type number
    local referenceGravity1g = nil

    --[[
      General Helpers
    ]]

    --- Gets the appropriate HUD color
    ---@param forcePvPZone boolean
    ---@return table<number,number>
    local function getHudColor(forcePvPZone)
      local isPvPZone = construct.isInPvPZone()
      if type(forceSafeZone) ~= 'nil' then
        isPvPZone = forcePvPZone
      end
      if isPvPZone then
        return { PvPR, PvPG, PvPB }
      else
        return { SafeR, SafeG, SafeB }
      end
    end

    --- Gets the appropriate HUD color in RGB notation
    ---@param alpha number
    ---@param forcePvPZone boolean
    ---@return string
    local function getHudColorRgb(alpha, forcePvPZone)
      local color = getHudColor(forcePvPZone)
      color[4] = alpha or 1
      return ('rgba(%s, %s, %s, %s)'):format(color[1], color[2], color[3], color[4])
    end

    --- Converts a coordinate from local to world space
    ---@param coordinate vec3
    ---@return vec3
    local function convertLocalToWorldCoordinates(coordinate)
      return vec3(construct.getWorldPosition())
      + coordinate.x * vec3(construct.getWorldOrientationRight())
      + coordinate.y * vec3(construct.getWorldOrientationForward())
      + coordinate.z * vec3(construct.getWorldOrientationUp())
    end

    --- Gets the current IPH/AP destination
    ---@return table
    local function getCurrentDestination()
      local position = nil
      if customLocation and not Autopilot then
        position = vec3(CustomTarget.position)
      elseif AutopilotTargetCoords then
        position = vec3(AutopilotTargetCoords)
      end

      if position and AutopilotTargetName ~= 'None' then
        return {
          name = AutopilotTargetName or 'Unknown Location',
          position = position,
        }
      end
      return nil
    end

    --- Converts fuel tank raw data into meaningful table
    ---@return table
    local function getFuelTankInfo(tank, tankType)
      local result = {}

      -- Loads hard-coded properties
      local properties = { 'id', 'name', 'volumeMax', 'massEmpty', 'massLast', 'timeLast', 'linkedElementIndex' }
      for index, property in pairs(properties) do
        result[property] = tank[index] or nil
      end

      -- Adds extra info
      result.isDataPrecise = false
      result.mass = core.getElementMassById(result.id)
      result.volumeMass = result.mass - result.massEmpty

      -- Adds linked element (if any)
      if result.slotIndex ~= 0 and tankType then
        result.linkedElement = unit[tankType .. '_' .. result.linkedElementIndex]

        -- Reads accurate data from linked element
        if result.linkedElement then
          local linkedData = json.decode(result.linkedElement.getWidgetData())
          if linkedData then
            result.isDataPrecise = true
            result.level = (linkedData.percentage or 0) / 100
            result.timeLeft = tonumber(linkedData.timeLeft) or nil
          end
        end
      end

      return result
    end

    --- Gets the fuel tank levels per type
    ---@return table
    local tanksPreviousReadings = {}
    local function getFuelLevels(fuelTankType)
      local now = system.getArkTime()

      local tanks = {}
      local tankType = nil
      local density = 0
      
      -- Selects right fuel type
      if 'atmo' == fuelTankType then
        tanks = atmoTanks
        tankType = 'atmofueltank'
        density = 4
      elseif 'space' == fuelTankType then
        tanks = spaceTanks
        tankType = 'spacefueltank'
        density = 6
      elseif 'rocket' == fuelTankType then
        tanks = rocketTanks
        tankType = 'rocketfueltank'
        density = 0.8
      end

      -- Processes our fuel tanks
      local fuelTanks = {}
      local fuelTimes = {
        min = nil,
        max = nil,
      }
      for _, _tank in pairs(tanks) do
        local tank = getFuelTankInfo(_tank, tankType)

        -- Compares with previous reading
        local fuelReadingDelta, fuelMassUsed, lastTimeLeft = nil, nil, nil
        local previousReading = tanksPreviousReadings[tank.id]
        if previousReading then
          fuelMassUsed = math.max(0, previousReading.volumeMass - tank.volumeMass)
          fuelReadingDelta = now - previousReading.readingTime
          lastTimeLeft = previousReading.timeLeft
        end

        -- Let's use the widget data if we have it available
        local data = nil
        if tank.isDataPrecise then
          data = {
            level = tank.level,
            timeLeft = tank.timeLeft,
          }
        else
          -- When no data is available, compute it on the fly with whatever we have
          local timeLeft = lastTimeLeft
          if fuelMassUsed and fuelReadingDelta and fuelMassUsed > 0 then
            timeLeft = tank.volumeMass / (fuelMassUsed / fuelReadingDelta)
          end

          data = {
            level = tank.volumeMass / tank.volumeMax,
            timeLeft = timeLeft,
          }
        end

        -- Calculates minimum and maximum burn times
        if data.timeLeft then
          if fuelTimes.min and fuelTimes.max then
            fuelTimes.min = math.min(data.timeLeft, fuelTimes.min)
            fuelTimes.max = math.max(data.timeLeft, fuelTimes.max)
          else
            fuelTimes.min = data.timeLeft
            fuelTimes.max = data.timeLeft
          end
        end

        -- Updates previous reading
        tanksPreviousReadings[tank.id] = {
          readingTime = now,
          volumeMass = tank.volumeMass,
          timeLeft = data.timeLeft,
        }

        table.insert(fuelTanks, data)
      end

      return fuelTanks, fuelTimes
    end

    --- Gets the current forward direction in world space
    ---@return vec3
    local function getCurrentPointedAt()
      return convertLocalToWorldCoordinates(vec3(0, infinityDistance, 0))
    end

    --- Gets the current motion direction in world space
    ---@return vec3
    local function getCurrentMotion()
      local worldVelocity = vec3(construct.getWorldAbsoluteVelocity())
      if worldVelocity:len() < 1 then
        return nil
      end
      return worldVelocity:normalize_inplace() * infinityDistance + vec3(construct.getWorldPosition())
    end

    --- Converts a distance amount into meters, kilometers or su
    ---@param distance number
    ---@return string
    local function getDistanceAsString(distance)
      if distance > 100000 then
        return ('%.1f su'):format(distance / 200000)
      elseif distance > 1000 then
        return ('%.1f km'):format(distance / 1000)
      end
      return ('%.1f m'):format(distance)
    end

    --- Converts a number of seconds into a string
    ---@param seconds number
    ---@return string
    local function getTimeAsString(seconds, longFormat)
      local days = math.floor(seconds / 86400)
      seconds = seconds - days * 86400

      local hours = math.floor(seconds / 3600)
      seconds = seconds - hours * 3600

      local minutes = math.floor(seconds / 60)
      seconds = seconds - minutes * 60

      -- Long format (X hours, Y minutes, Z seconds)
      if longFormat then
        local result = {}
        if days > 0 then table.insert(result, days .. 'd') end
        if hours > 0 then table.insert(result, hours .. 'h') end
        if minutes > 0 then table.insert(result, minutes .. 'm') end
        if hours == 0 then
          table.insert(result, math.floor(seconds) .. 's')
        end

        return table.concat(result, ' ')
      end

      -- Short format (X:YY:ZZ)
      local result = {}
      if hours > 0 then
        table.insert(result, hours + 24 * days)
      end
      table.insert(result, ('%02d'):format(math.floor(minutes)))
      table.insert(result, ('%02d'):format(math.floor(seconds)))
      return table.concat(result, ':')
    end

    --- Converts a m/s value into a string (optionally converts to km/h too)
    ---@param value number
    ---@param convertToKmph boolean
    ---@return string
    local function getMetersPerSecondAsString(value, convertToKmph)
      if convertToKmph then
        return ('%.1f km/h'):format(value * 3.6)
      end
      return ('%.1f m/s'):format(value)
    end

    --- Rounds a value to desired precision
    ---@param value number
    ---@param precision number
    ---@return string
    local function getRoundedValue(value, precision)
      return ('%.' .. (precision or 0) .. 'f'):format(value)
    end
    
    --- Gets closest celestial body to world position (in m/s²)
    ---@param altitude number
    ---@param celestialBody table
    local function getGravitationalForceAtAltitude(altitude, celestialBody)
      return celestialBody.GM / (celestialBody.radius + altitude) ^ 2
    end
    
    --- Gets closest celestial body to world position (in Gs)
    ---@param altitude number
    ---@param celestialBody table
    local function getGravitationalForceAtAltitudeInGs(altitude, celestialBody)
      return getGravitationalForceAtAltitude(altitude, celestialBody) / referenceGravity1g
    end
    
    --- Gets the altitude where a celestial body has certain gravitational force (in m/s²)
    ---@param intensity number
    ---@param celestialBody table
    local function getAltitudeAtGravitationalForce(intensity, celestialBody)
      return math.sqrt(celestialBody.GM / intensity) - celestialBody.radius
    end
    
    --- Gets the altitude where a celestial body has certain gravitational force (in Gs)
    ---@param intensity number
    ---@param celestialBody number
    local function getAltitudeAtGravitationalForceInGs(intensity, celestialBody)
      return getAltitudeAtGravitationalForce(intensity * referenceGravity1g, celestialBody)
    end
    
    --- Gets closest celestial body to world position
    ---@param position vec3
    ---@param maxRange number
    local function getClosestCelestialBody(position, allowInfiniteRange)
      local closestBody = nil
      local closestBodyDistance = nil

      for _, celestialBody in pairs(atlas) do
        local celestialBodyPosition = vec3(celestialBody.center)
        local celestialBodyDistance = (position - celestialBodyPosition):len()
        local celestialBodyGravity0 = getAltitudeAtGravitationalForceInGs(0.1, celestialBody)

        if (not closestBodyDistance or closestBodyDistance > celestialBodyDistance) and (allowInfiniteRange or celestialBodyDistance <= celestialBodyGravity0) then
          closestBody = celestialBody
          closestBodyDistance = celestialBodyDistance
        end
      end

      return closestBody, closestBodyDistance
    end

    --- Gets a celestial body relative position from a world position
    ---@param position vec3
    ---@param celestialBody table
    ---@return table
    local function getCelestialBodyPosition(position, celestialBody)
      return position - vec3(celestialBody.center.x, celestialBody.center.y, celestialBody.center.z)
    end

    --- Gets a lat, lon, alt position from a world position
    ---@param position vec3
    ---@param celestialBody table
    ---@return table
    local function getLatLonAltFromWorldPosition(position, celestialBody)
      -- We need to extract the "local" coordinate (offset from planet center) here and then normalize it to do math with it
      local offset = getCelestialBodyPosition(position, celestialBody)
      local offsetNormalized = offset:normalize()

      return {
        lat = 90 - (math.acos(offsetNormalized.z) * 180 / math.pi),
        lon = math.atan(offsetNormalized.y, offsetNormalized.x) / math.pi * 180,
        alt = offset:len() - celestialBody.radius,
      }
    end

    --- Gets the distance to a certain point in space
    ---@param point vec3
    ---@return number
    local function getDistanceToPoint(point)
      return (vec3(construct.getWorldPosition()) - point):len()
    end

    --- Gets the distance to a certain point in space
    --- Code adapted from: https://community.esri.com/t5/coordinate-reference-systems-blog/distance-on-a-sphere-the-haversine-formula/ba-p/902128
    ---@param point vec3
    ---@param celestialBody table
    ---@return number
    local function getDistanceAroundCelestialBody(point, celestialBody)
      local currentCoordinates = getLatLonAltFromWorldPosition(vec3(construct.getWorldPosition()), celestialBody)
      local targetCoordinates = getLatLonAltFromWorldPosition(point, celestialBody)
      local flyingAltitude = currentCoordinates.alt, celestialBody.maxStaticAltitude

      -- Helper function to convert degrees to radians
      local function rad(deg)
        return deg * math.pi / 180
      end

      local phi1, phi2 = rad(currentCoordinates.lat), rad(targetCoordinates.lat)
      local deltaPhi, deltaLambda = rad(currentCoordinates.lat - targetCoordinates.lat), rad(currentCoordinates.lon - targetCoordinates.lon)

      local a = math.sin(deltaPhi / 2) ^ 2 + math.cos(phi2) * math.cos(phi2) * math.sin(deltaLambda / 2) ^ 2
      local c = 2 * math.atan(math.sqrt(a), math.sqrt(1 - a))

      return (celestialBody.radius + flyingAltitude) * c
    end

    --[[
      AR Helpers
    ]]

    --- Gets the x, y, depth screen coordinates (in 0-1 space) from a world position
    ---@param coordinate vec3
    ---@return vec3
    local function getARPointFromCoordinate(coordinate)
      local result = vec3(library.getPointOnScreen({ coordinate:unpack() }))
      if result:len() == 0 then
        return nil
      end
      return result
    end

    --[[
      Render-related stuff, this mostly generates a self-contained render function that updates the UI for us, based on input parameters
    ]]

    local render = (function()
      local UI = {}
      local Shapes = {}
      local renderGlobals = {
        UI = UI,
        Shapes = Shapes,
        WorldCoordinate = getARPointFromCoordinate,
        Time = getTimeAsString,
        Round = getRoundedValue,
        Exists = function(value) return 'nil' ~= type(value) end,
        Percentage = function(value, precision) return getRoundedValue(100 * value, precision) .. '%' end,
        Metric = getDistanceAsString,
        MetersPerSecond = getMetersPerSecondAsString,
        KilometersPerHour = function(value) return ('%.0f km/h'):format(value) end,
        TimeToDistance = function(distance, speed) return ((speed > 0) and getTimeAsString(distance / speed, true)) or nil end,
        DistanceTo = getDistanceToPoint,
        DistanceAroundCelestialBody = getDistanceAroundCelestialBody,
        GravityAt = getGravitationalForceAtAltitude,
        GravityAtInGs = getGravitationalForceAtAltitudeInGs,
        Colors = {
          Main = '#09D4EB',
          Accent = '#5FFF77',
          Shadow = 'rgba(0, 0, 0, 0.75)',
        },
        GetHudColor = getHudColorRgb,
      }

      --- Draws text as SVG
      renderGlobals.TextSvg = SmartTemplate([[
        <svg>
          <text x="0" y="{{ size or 20 }}" font-size="{{ size or 20 }}" style="font-family: {{ font or 'Play' }}; font-weight: {{ weight or 'normal' }}; fill: transparent; stroke: {{ stroke or 'transparent' }}; stroke-width: 4px;">{{ text }}</text>
          <text x="0" y="{{ size or 20 }}" font-size="{{ size or 20 }}" style="font-family: {{ font or 'Play' }}; font-weight: {{ weight or 'normal' }}; fill: {{ color or GetHudColor() }};">{{ text }}</text>
        </svg>
      ]], renderGlobals)

      --- Draws text
      renderGlobals.Label = SmartTemplate([[
        <span style="font-size: {{ size or 1 }}em; font-family: {{ font or 'Play' }}; font-weight: {{ weight or 'normal' }}; color: {{ color or GetHudColor() }}; text-shadow: 0px 0px 1px {{ stroke or Colors.Shadow }}, 0px 0px 2px #000, 0px 0px 4px #000;">
          {{ text }}
        </span>
      ]], renderGlobals)

      --- Draws a Hexagon primitive shaoe
      Shapes.Hexagon = SmartTemplate([[
        <svg style="width: {{ size or 1 }}em; height: {{ size or 1 }}em;" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M24.25 1.56699L24 1.42265L23.75 1.56699L4.69745 12.567L4.44745 12.7113V13V35V35.2887L4.69745 35.433L23.75 46.433L24 46.5774L24.25 46.433L43.3026 35.433L43.5526 35.2887V35V13V12.7113L43.3026 12.567L24.25 1.56699ZM9.44745 32.4019V15.5981L24 7.19615L38.5526 15.5981V32.4019L24 40.8038L9.44745 32.4019Z" fill="{{ color }}" stroke="{{ stroke }}"/>
        </svg>
      ]])

      --- Draws a Crosshair primitive shaoe
      Shapes.Crosshair = SmartTemplate([[
        <svg style="width: {{ size or 1 }}em; height: {{ size or 1 }}em;" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M21.5 46V46.5H22H26H26.5V46V26.5H46H46.5V26V22V21.5H46H26.5V2V1.5H26H22H21.5V2V21.5H2H1.5V22V26V26.5H2H21.5V46Z" fill="{{ color }}" stroke="{{ stroke }}"/>
        </svg>
      ]])

      --- Draws a Crosshair primitive shaoe
      Shapes.Diamond = SmartTemplate([[
        <svg style="width: {{ size or 1 }}em; height: {{ size or 1 }}em;" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M24.3536 1.64645L24 1.29289L23.6465 1.64645L1.64645 23.6465L1.29289 24L1.64645 24.3536L23.6465 46.3536L24 46.7071L24.3536 46.3536L46.3536 24.3536L46.7071 24L46.3536 23.6465L24.3536 1.64645ZM24 39.636L8.36396 24L24 8.36396L39.636 24L24 39.636Z" fill="{{ color }}" stroke="{{ stroke }}"/>
        </svg>
      ]])

      --- Creates an element that is always centered at a certain coordinate
      UI.PositionCenteredAt = SmartTemplate(
        'position: absolute; top: {{ Percentage(y, 6) }}; left: {{ Percentage(x, 6) }}; margin-top: -{{ (height or 1) / 2 }}em; margin-left: -{{ (width or 1) / 2 }}em;'
      , renderGlobals)

      --- Renders a destination marker
      UI.DestinationMarker = SmartTemplate([[
      {%
        local screen = WorldCoordinate(position)
        local distance = DistanceTo(position)

        -- When on same celestial body, we need to take into account going around it
        -- We use math.max here so we can also take the vertical displacement into account
        if Exists(currentCelestialBody) and Exists(destinationCelestialBody) and currentCelestialBody.id == destinationCelestialBody.id then
          distance = math.max(distance, DistanceAroundCelestialBody(position, destinationCelestialBody.info))
        end

        -- Calculates the ETA at current speed
        local eta = nil
        if speed and speed > 0 then
          eta = TimeToDistance(distance, speed)
        end
      %}
      {% if screen then %}
        <div style="{{ UI.PositionCenteredAt({ x = screen.x, y = screen.y, width = 2, height = 2 }) }}">
          <div style="postion: relative;">
            {{ Shapes.Hexagon({ color = GetHudColor(), stroke = Colors.Shadow, size = 2 }) }}
          {% if title or distance then %}
            <div style="font-size: 0.8em; position: absolute; top: 1em; left: 2.5em; border-top: 2px solid {{ GetHudColor() }}; white-space: nowrap;">
            {% if title then %}
              <div>{{ Label({ text = title, size = 1.2, weight = 'bold' }) }}</div>
            {% end %}
            {% if distance then %}
              <div>{{ Label({ text = Metric(distance) }) }}</div>
            {% end %}
            {% if eta then %}
              <div style="font-size: 0.8em;">{{ Label({ text = 'ETA: ' .. eta }) }}</div>
            {% end %}
            </div>
          {% end %}
          </div>
        </div>
      {% end %}
      ]], renderGlobals)

      --- Renders a crosshair shape
      UI.Crosshair = SmartTemplate([[
        <div style="{{ UI.PositionCenteredAt({ x = x, y = y, width = 1.5, height = 1.5 }) }}">
          {{ Shapes.Crosshair({ color = GetHudColor(), stroke = Colors.Shadow, size = 1.5 }) }}
        </div>
      ]], renderGlobals)

      --- Renders a diamond shape
      UI.Diamond = SmartTemplate([[
        <div style="{{ UI.PositionCenteredAt({ x = x, y = y, width = 1.5, height = 1.5 }) }}">
          {{ Shapes.Diamond({ color = GetHudColor(), stroke = Colors.Shadow, size = 1.5 }) }}
        </div>
      ]], renderGlobals)

      --- Renders a horizontal progress bar
      UI.ProgressHorizontal = SmartTemplate([[
        <div style="width: {{ width or 2 }}em; height: {{ height or 1 }}em; border: 0.1em solid {{ stroke or GetHudColor() }};">
          <div style="width: {{ 100 * (progress or 0) }}%; height: 100%; background: {{ color or GetHudColor() }};"></div>
        </div>
      ]], renderGlobals)

      --- Renders a horizontal progress bar
      UI.ProgressVertical = SmartTemplate([[
        <div style="position: relative; width: {{ width or 1 }}em; height: {{ height or 2 }}em; border: 0.1em solid {{ stroke or GetHudColor() }};">
          <div style="position: absolute; bottom: 0px; left: 0px; width: 100%; height: {{ 100 * (progress or 0) }}%; background: {{ color or GetHudColor() }};"></div>
        </div>
      ]], renderGlobals)

      --- Renders a horizontal progress bar
      UI.DataRow = SmartTemplate([[
        <tr class="data-row">
          <td class="data-row-label">
            {{ Label({ text = label, weight = 'bold' }) }}
          </td>
          <td class="data-row-value">
            {{ Label({ text = value }) }}
          </td>
        </tr>
      ]], renderGlobals)
      
      --- This is our HUD's base render function and template
      local renderUI = SmartTemplate([[
      {%
        if currentPointingAt then
          currentPointingAtOnScreen = WorldCoordinate(currentPointingAt)
        end
        if currentMotion then
          currentMotionOnScreen = WorldCoordinate(currentMotion)
        end
      %}

        {% if Exists(currentDestination) then %}
          {{ UI.DestinationMarker({ title = currentDestination.name, position = currentDestination.position, currentCelestialBody = currentCelestialBody, destinationCelestialBody = destinationCelestialBody, speed = currentDestinationApproachSpeed }) }}
        {% end %}

        {% if Exists(currentPointingAtOnScreen) then %}
          {{ UI.Crosshair(currentPointingAtOnScreen) }}
        {% end %}

        {% if Exists(currentMotionOnScreen) then %}
          {{ UI.Diamond(currentMotionOnScreen) }}
        {% end %}

      {% if Exists(info) then %}
      {%
        local burnTimes = info.burnTimes
      %}
        <style>
        .wlhud-info {
          position: absolute;
          bottom: 15%;
          left: 50%;
          transform: translateX(-50%);

          display: flex;
          flex-direction: column;
          align-items: center;
          
          font-size: 0.8em;
        }

        .data-row-label {
          text-align: right;
        }
        .data-row-value {
          padding-left: 0.5em;
        }

        .wlhud-fuel {
          display: flex;
          flex-direction: row;
          align-items: flex-end;
        }
        .wlhud-fuel-type {
          display: flex;
          flex-direction: column;
          align-items: center;
        }
        .wlhud-fuel-type > div {
          margin: 0px 0.4em;
        }
        .wlhud-fuel-type-tanks {
          display: flex;
          flex-direction: row;
        }
        .wlhud-fuel-type-tanks > div {
          margin: 0px 0.1em;
        }
        .wlhud-fuel-type + .wlhud-fuel-type { margin-top: 1em; }
        </style>

        <div class="wlhud-info">
          <table>
          {% if info.isThrottleMode then %}
            {{ UI.DataRow({ label = 'Throttle:', value = Percentage(info.throttleValue) }) }}
          {% elseif info.isCruiseMode then %}
            {{ UI.DataRow({ label = 'Cruise:', value = KilometersPerHour(info.throttleValue) }) }}
          {% end %}

            {{ UI.DataRow({ label = 'Acceleration:', value = Round(info.accelerationInGs, 1) .. 'g' }) }}
            {{ UI.DataRow({ label = 'Speed:', value = MetersPerSecond(currentSpeed, true) }) }}
            {{ UI.DataRow({ label = 'vSpeed:', value = MetersPerSecond(currentSpeedVertical) }) }}

          {% if Exists(burnTimes) and burnTimes.min and burnTimes.max then %}
            {% if burnTimes.min == burnTimes.max then %}
              {{ UI.DataRow({ label = 'Burn Time:', value = Time(burnTimes.min, true) }) }}
            {% else %}
              {{ UI.DataRow({ label = 'Burn Time Min.:', value = Time(burnTimes.min, true) }) }}
              {{ UI.DataRow({ label = 'Burn Time Max.:', value = Time(burnTimes.max, true) }) }}
            {% end %}
          {% end %}
          </table>

          <div class="wlhud-fuel">
          {% for _, fuelType in pairs(info.fuel) do %}
            {% local tankTypeColor = GetHudColor() %}
            {% if #fuelType.tanks > 0 then %}
              <div class="wlhud-fuel-type">
                <div class="wlhud-fuel-type-tanks">
                {% for _, tank in pairs(fuelType.tanks) do %}
                  {% if tank.level < 0.2 or (tank.timeLeft and tank.timeLeft < 60) then %}
                    {% tankTypeColor = '#F70' %}
                    {{ UI.ProgressVertical({ height = 4, width = 0.5, progress = tank.level, stroke = tankTypeColor, color = tankTypeColor }) }}
                  {% else %}
                    {{ UI.ProgressVertical({ height = 4, width = 0.5, progress = tank.level }) }}
                  {% end %}
                {% end %}
                </div>
                <div>{{ Label({ text = fuelType.label, size = 0.8, color = tankTypeColor })}}</div>
              </div>
            {% end %}
          {% end %}
          </div>
        </div>
      {% end %}
      ]], renderGlobals)

      --- This is what actually renders to the screen
      return function(data)
        userScreen = renderUI(data or {})
      end
    end)()

    --[[
      Event bindings
    ]]

    -- This is our main render function
    local function onRenderFrame()
      -- This is our current AP/IPH destination
      local currentPosition = vec3(construct.getWorldPosition())

      -- This is our current AP/IPH destination
      local currentDestination = getCurrentDestination()

      -- Pre-calculates some vectors
      local worldVertical = vec3(core.getWorldVertical())
      local worldVelocity = vec3(construct.getWorldVelocity())
      local worldAcceleration = vec3(construct.getWorldAcceleration())
      local atmoDensity = unit.getAtmosphereDensity()

      -- This is our current celestial body and coordinates
      local currentCelestialBody, currentCelestialBodyCoordinates = getClosestCelestialBody(currentPosition), nil
      if currentCelestialBody then
        currentCelestialBodyCoordinates = getLatLonAltFromWorldPosition(currentPosition, currentCelestialBody)
      end

      -- This is our current AP/IPH destination in lat/lon/alt space, along with what celestial body it is
      local currentDestinationCelestialBody, currentDestinationCelestialBodyCoordinates = nil, nil
      if currentDestination then
        currentDestinationCelestialBody = getClosestCelestialBody(currentDestination.position)
        if currentDestinationCelestialBody then
          currentDestinationCelestialBodyCoordinates = getLatLonAltFromWorldPosition(currentDestination.position, currentDestinationCelestialBody)
        end
      end

      -- Prepares data for our current and destination celestial body
      local currentCelestialBodyInfo, destinationCelestialBodyInfo = nil, nil
      if currentCelestialBody and currentCelestialBodyCoordinates then
        currentCelestialBodyInfo = {
          info = currentCelestialBody,
          coordinates = currentCelestialBodyCoordinates,
        }
      end
      if currentDestinationCelestialBody and currentDestinationCelestialBodyCoordinates then
        destinationCelestialBodyInfo = {
          info = currentDestinationCelestialBody,
          coordinates = currentDestinationCelestialBodyCoordinates,
        }
      end

      -- Is destination on same celestial body
      local isDestinationOnSameCelestialBody = false
      if currentCelestialBody and currentDestinationCelestialBody and currentCelestialBody.id == currentDestinationCelestialBody.id then
        isDestinationOnSameCelestialBody = true
      end

      -- This is our current direction forward
      local currentPointingAt = getCurrentPointedAt()

      -- This is our current motion vector
      local currentMotion = getCurrentMotion()

      -- Let's calculate whether we're getting closer to our destination or not
      local currentDestinationApproachSpeed = nil
      if isDestinationOnSameCelestialBody then
        currentDestinationApproachSpeed = worldVelocity:len()
      elseif currentDestination then
        local destinationVector = (currentDestination.position - currentPosition):normalize()
        currentDestinationApproachSpeed = destinationVector:dot(worldVelocity)
      end

      -- Lite HUD
      local extraHudInfo = nil
      if enableLiteHud and not showHud then
        local atmo, burnTimeAtmo = getFuelLevels('atmo')
        local space, burnTimeSpace = getFuelLevels('space')
        local rocket, burnTimeRocket = getFuelLevels('rocket')

        local function getMinAndMaxFromMultipleSources(...)
          local sources = {...}
          local min, max = nil, nil

          for _, source in pairs(sources) do
            -- Min value
            if min and source.min then
              min = math.min(min, source.min)
            elseif source.min then
              min = source.min
            end

            -- Max value
            if max and source.max then
              max = math.min(max, source.max)
            elseif source.max then
              max = source.max
            end
          end

          return { min = min, max = max }
        end

        -- Gets min/max burn times
        local burnTimes = nil
        if atmoDensity > 0.10 then
          -- We're in atmo
          burnTimes = getMinAndMaxFromMultipleSources(burnTimeAtmo, burnTimeRocket)
        elseif atmoDensity <= 0.10 and atmoDensity > 0 then
          -- We're in atmo-space transition
          burnTimes = getMinAndMaxFromMultipleSources(burnTimeAtmo, burnTimeSpace, burnTimeRocket)
        else
          -- We're in space
          burnTimes = getMinAndMaxFromMultipleSources(burnTimeSpace, burnTimeRocket)
        end

        -- Pushes the HUD info to template
        extraHudInfo = {
          throttleValue = unit.getAxisCommandValue(0),
          isThrottleMode = unit.getControlMode() == 0,
          isCruiseMode = unit.getControlMode() == 1,
          acceleration = worldAcceleration:len(),
          accelerationInGs = worldAcceleration:len() / core.getGravityIntensity(),
          burnTimes = burnTimes,
          fuel = {
            { tanks = atmo, burnTimes = burnTimeAtmo, label = 'Atmo' },
            { tanks = space, burnTimes = burnTimeSpace, label = 'Space' },
            { tanks = rocket, burnTimes = burnTimeRocket, label = 'Rocket' },
          }
        }
      end

      -- This will print all data with our template
      render({
        info = extraHudInfo,
        currentDestination = currentDestination,
        currentDestinationApproachSpeed = currentDestinationApproachSpeed,
        currentPointingAt = currentPointingAt,
        currentMotion = currentMotion,
        currentSpeed = worldVelocity:len(),
        currentSpeedVertical = -worldVertical:dot(worldVelocity),

        -- Routing utilities
        currentCelestialBody = currentCelestialBodyInfo,
        destinationCelestialBody = destinationCelestialBodyInfo,
      })
    end
    
    -- Overrides our render functions
    local function onStart()
      for global, value in pairs(_G) do
        if global:find('Unit') then
          -- Is this the Control Unit (or "unit" global, which for some reason is not present on global environment)
          if 'table' == type(value) then
            if 'function' == type(value.exit) and 'function' == type(value.setTimer) then
              unit = value
            end
            if 'function' == type(value.getElementIdList) then
              core = value
            end
          end
        end
      end

      -- Pre-calculate Alioth's gravity at 0m (our 1g reference)
      referenceGravity1g = getGravitationalForceAtAltitude(0, atlas[2])

      -- This will allow or not hooks
      local isHookingPossible = true

      if not unit then
        system.print('WARNING: Control Unit was not found! AR will not be installed.')
        isHookingPossible = false
      end

      if not core then
        system.print('WARNING: Core Unit was not found! AR will not be installed.')
        isHookingPossible = false
      end

      if not HUD then
        system.print('WARNING: Base HUD was not found! AR will not be installed.')
        isHookingPossible = false
      end

      if isHookingPossible then
        local parentTick = HUD.hudtick
        HUD.hudtick = function()
          onRenderFrame()
          parentTick()
        end
      end
    end

    -- Stubs otherwise the main HUD will crash
    local function onStop() end
    local function onUpdate() end
    local function onFlush() end

    -- This is our use API
    return {
      ExtraOnStart = onStart,
      ExtraOnStop = onStop,
      ExtraOnUpdate = onUpdate,
      ExtraOnFlush = onFlush,
    }
  end)

  if hasInitialized then
    return result
  else
    system.print('Failed to initialize AR HUD!')
    system.print('ERROR: ' .. result)
  end
end)()