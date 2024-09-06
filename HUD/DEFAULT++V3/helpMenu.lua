local help = {}
local fontSize = 12
local lineSpace = 16
help.info = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'INSTRUCTION MANUAL'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[" style="font-weight: bold; " font-size="]]..fontSize*1.8 ..[[">]]..'Default ++ v3.6 for Release 1.4.0'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'The touch screen revolutionary hud and flight script!'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'By Jeronimo 2016-2023'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'> "ALT + 1" to open and close Main menu.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'> "LEFT CLICK" as main CLICK.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'> "MOUSE WHEEL STEER" over button to change its VALUE.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'> "LEFT CLICK" over button to change its INCREMENT.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'> "CTRL + LEFT CLICK" to save a button in the QUICK TOOL BAR'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'(a little asterisk "*" confirms the shortcut is active).'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'> "double tap + hold ALT" to access QUICK TOOL BAR.'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'> All the DEFAULT ++ windows and widgets are dragable'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'either by their tittle or background.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'> All the DEFAULT ++ widgets are resizeable using mouse wheel'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'> "ALT + 2" to open and close Travel Planner++.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace ..[[">]]..'Bookmarks and double warp calculator are accessible here'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'> Discord: Jeronimo#4624'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[" style="font-weight: bold; " font-size="]]..fontSize*1.5 ..[[">]]..'ENJOY!'..[[</tspan>
            </text>]]
        
help.menuSettings = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'MENU SETTINGS'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'This MENU is dedicated to windows customization'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- TITTLE COLOR: Tittle bar color parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- TITTLE ALPHA: Tittle bar opacity parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- TITTLE TEXT COLOR: Tittle bar text color parameter'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- WINDOW COLOR: Background color parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- WINDOW ALPHA: Background opacity parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- WINDOW TEXT COLOR: Text color parameter'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- BUTTON COLOR: Buttons background color parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- BUTTON BORDER COLOR: Buttons border color parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- BUTTON ALPHA: Buttons background opacity parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- BUTTON TEXT COLOR: Buttons text color parameter'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- WIDGET COLOR: Widgets background color parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- WIDGET SVG COLOR1: Widgets SVG color parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- WIDGET SVG COLOR2: Widgets SVG color parameter'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- COLOR PRESETS: Up to 5 presets that can be customized at will'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- HELP MENU: Open and close this instructions window'..[[</tspan>
            </text>]]
        
help.engineSettings = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'ENGINES SETTINGS'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'This MENU is dedicated to engines default settings'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- PITCH FACTOR: Pitch speed factor parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- YAW FACTOR: Yaw speed factor parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ROLL FACTOR: Roll speed factor parameter'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ANGULAR DAMPENING FACTOR: Anti rotational drift factor parameter'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- LONG BRAKE FACTOR: Brake intensity factor along logitudinal axis'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- LAT BRAKE FACTOR: Brake intensity factor along lateral axis'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- VERT BRAKE FACTOR: Brake intensity factor along vertical axis'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- SPACE BRAKE INTENSIITY: Multiplication factor for all 3 above factors in space'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- GYRO AXIS: Use gyro to set the Forward/Right/Up of the construct'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- PITCH TILTING: Adjust the default pitch angle of the construct'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ROLL TILTING: Adjust the default roll angle of the construct'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- HOVERS ON/OFF: Activate/deactivate hover engines'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- HOVER MODE: Dynamic/Static enables altitude stabilisation'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- HOVER ALTITUDE: Altitude for Static Mode'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- VBOOSTER ON/OFF/AUTO: Activate/deactivate booster engines (Auto = deactivated in atmo)'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- AGG ALTITUDE: Adjust the Anti-gravity engine altitude'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- ENGINES ON/OFF: Activate/deactivate all the engines'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ENGINES AUTO: Long press "C" on the ground to deactivate all engines'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ECO MODE: Deactivate all engines that doesnt have the engine tag "eco"'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'Warning: make sure you set the tag "eco" to at least '..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'one of each type of engines (thrusters / hovers / vboosters)'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ATMO MAX SPEED: Speed limiter for atmosphere'..[[</tspan>
            </text>]]
        
help.autopilotSettings = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'AUTOPILOT SETTINGS'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'This MENU is dedicated to autopilot features settings'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- AUTO BRAKE SPEED: Speed under which auto braking will occure (auto brake for Travel mode)'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- STABILISATIONS ALTITUDE MAX: Altitude under wich auto stabilisation will be effective'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace ..[[">]]..'- ROLL STABILISATION: Automatic roll stabilisation'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- TURN ASSIST: Automatic pitch and yaw while rolling'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- TURN ASSIST MIN ROLL: Minimum roll angle for the turn assist to occure'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- TURN ASSIST MAX PITCH: Maximum pitch angle for the turn assist to occure'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- PITCH STABILISATION: Automatic pitch stabilisation'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- AUTO PITCH AMPLITUDE: Angle under which pitch stabilisation will occure'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ALTITUDE STABILISATION: Automatic pitch to keep a stable altitude'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ATMO ANTI-STALL: Will try to prevent construct from stalling in atmo'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- INERTIA AUTO BRAKE: Anti drift auto braking on/off'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- ATMO INERTIA FACTOR: Amto drift sensibility factor'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- SPACE INERTIA FACTOR: Space drift sensibility factor'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- SPACE AUTO PROGRADE: Force align construct to its velocity vector'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- SPACE AUTO ORBIT SPEED: Auto speed adjustment for orbit'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- ROCKETS MAX SPEED: Speed limiter in atmo for rockets(set -1 to disable)(WIP)'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'*Rockets are completly disabled at the moment'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- DOCKING PARENT: MANUAL / CLOSEST / OWNER docking parent type'..[[</tspan>
            </text>]]
        
help.widgets = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'WIDGETS SETTINGS'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'This MENU is dedicated to widgets settings'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- All DEFAULT++ widgets are resizeable, repositionable,'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'by using the "Quick tool Bar" menu.'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Widgets with the "ALT" option on will only popup'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'when "Quick tool Bar" menu is opened.'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Widgets with the "AUTO" option on will only popup'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..' when the needed conditions they requiere are active.'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Too many opened widgets can cause CPU overload'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'Use them wisely!'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Custom widgets are fully customizable and modular'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'they can be found and edited in the DEFAULT++V3 folder.'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'Number of custom widgets is unlimited as long as their file name number is consecutive'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Custom Widgets are using DEFAULT++ windows system to display custom SVGs,'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'they can also include custom buttons and thrust overide'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- If interested into making your own widgets/huds'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace ..[[">]]..'contact me directly on discord for details'..[[</tspan>
            </text>]]
        
help.keybingParams = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'KEYBINDS PARAMETERS'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'This MENU is dedicated to keybind parameters'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- FLIGHT MODE: Warning! Default flight mode keybind is deactivated'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'CRUISE: Use throttle to control the construct speed and brakes'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'TRAVEL: Use throttle to control the construct thrust'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'PARKING: Use AWSD to move around, press shift for full power'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'SPORT: Use AWSD to move around, but throttle is always to max'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- QE/AD INVERT: Inverts keybind for yaw and roll'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- DOUBLE TAP TIME: Time in seconds for activating a double tap'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'*DOUBLE TAP FEATURES: Acrobatic pitch/rot/roll using respective control keys' ..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'*DOUBLE TAP FEATURES: Backburn stop in space using "double tap CTRL"' ..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'*DOUBLE TAP FEATURES: Vertical stop and hovering in atmo using "double tap CTRL"' ..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- SHIFT LOCK: Enable the "SHIFT key to lock in place a control key'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'Fisrt hold "SHIFT" then press and release any control key, then release "SHIFT"'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- ACROBATIC PITCH/ROT/ROLL: Double tap and hold to execute acrobatic figures of set angles'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- FREEZE CONTROL: Freeze/unfreeze movements while using a remote or ECU'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- FREEZE VIEW: Freeze/unfreeze camera movements'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- MOUSE CONTROL: Alternate toggle able keyboard + mouse scheme'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'- M-C SENSIBILITY: Sensibility of the mouse control'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- ALT + 3456789 constumizable keybinds for selected features'..[[</tspan>
            </text>]]
        
help.quickToolBar = [[
            <text x="500" y="30" font-size="]]..fontSize..[[" text-anchor="middle">
                <tspan x="500" font-size="]]..fontSize*2 ..[[">]]..'QUICK TOOL BAR'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'This MENU is dedicated to the quick menu tool bar'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- While in the "ALT+1" main menu, hold "CTRL" then click to add'..[[</tspan>
                <tspan x="500" dy="]]..lineSpace..[[">]]..'or remove shortcut buttons to the Quick Tool Bar'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Quick Tool Bar is accessible by double taping and holding "ALT" key while on the main screen'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Widgets are interactible while Quick Tool Bar is opened'..[[</tspan>
                
                <tspan x="500" dy="]]..lineSpace*2 ..[[">]]..'- Certain widgets with "ALT" parameters will only popup with the Quick Tool Bar'..[[</tspan>
            </text>]]
            
help.print = function(system)
            system.print("------------------------")
            system.print("HELP / KEYBINDS")
            system.print("------------------------")
            system.print("ALT + 1 = open/close Main settings menu")
            system.print("Double Tap ALT while flying to acces quicktool menu")
            system.print("ALT + 2 = open/close Travel Planner")
            system.print("Hold SHIFT + Control Key = key lock(if enabled in the menu)")
            system.print("Double Tap W/A/S/D = acrobatic rotation")
            system.print("Double Tap CTRL in atmo = vertical stop and hover")
            system.print("Double Tap CTRL in space = backburn stop")
            system.print("------------------------")
            system.print("HELP / COMMANDS")
            system.print("------------------------")
            system.print("help = print the help menu")
            system.print("reset all: formats databank to factory settings")
            system.print("reset player: reset current player settings to default")
            system.print("type in a ::pos{} coordinate to translate it to world coordinate")
            system.print("align to ::pos{} OR align to vec3() = construct alignment to coordinate")
            system.print("align to destination = construct alignment to previous entered coordinates")
            system.print("------------------------")
            system.print("TRAVEL PLANNER COMMANDS:")
            system.print("add asteroids ::pos{};::pos{};::pos{} etc...")
            system.print("clear asteroids")
            system.print("------------------------")
            system.print("End of the help menu")
            system.print("------------------------")
        end
return help