--local webColors = require("autoconf/custom/DEFAULT++/webColors")

WindowLibPlusPlus = {}
WindowLibPlusPlus.__index = WindowLibPlusPlus
-- Defaults
local Default_Window_Position_X = 0
local Default_Window_Position_Y = 0
local Default_Window_Width = 300
local Default_Window_Height = 150
local Default_Window_TitleBar_Height = 25
local Default_Button_Position_X = 0
local Default_Button_Position_Y = 0
local Default_Button_Width = 96
local Default_Button_Height = 24


WindowLibPlusPlus.css = {}
WindowLibPlusPlus.buttonsNew = {}

-- WindowLibPlusPlus initializer: Gets our environment ready
function WindowLibPlusPlus.init()
    local self = setmetatable({}, WindowLibPlusPlus)
    --self.buttons = setmetatable({}, WindowLibPlusPlus.buttons)
    self.index          = 0
    self.windows        = {} -- Table containing all our windows
    self.buttonLock     = nil -- Lets us lock a button so it doesn't loop
    self.wlib_drag      = false
    self.CLICK          = false
    self.mouseWheel     = 0
    --self.cursorWin      = {}
    self.previousGenerated = ""
    return self
end

function WindowLibPlusPlus.winlibCSSUpdate(self)
    local WC = params.Menu_Settings.WINDOW_COLOR.value
    local WCA = params.Menu_Settings.WINDOW_COLOR_A.value
    local WTC = params.Menu_Settings.WINDOW_TEXT_COLOR.value
    local TCA = params.Menu_Settings.TITTLE_COLOR_A.value
    local TTC = params.Menu_Settings.TITTLE_TEXT_COLOR.value
    local BCA = params.Menu_Settings.BUTTON_COLOR_A.value
    local BTC = params.Menu_Settings.BUTTON_TEXT_COLOR.value
    local wTC = params.Menu_Settings.WIDGET_TEXT_COLOR.value
    local wAC = params.Menu_Settings.WIDGET_ANIM_COLOR.value
    local tittleR, tittleG, tittleB = webColors.namedColor2RGB(params.Menu_Settings.TITTLE_COLOR.value)
    local tittleRGB = tostring(tittleR)..","..tostring(tittleG)..","..tostring(tittleB)
    local windowR, windowG, windowB = webColors.namedColor2RGB(WC)
    local windowRGB = tostring(windowR)..","..tostring(windowG)..","..tostring(windowB)
    local buttonR, buttonG, buttonB = webColors.namedColor2RGB(params.Menu_Settings.BUTTON_COLOR.value)
    local buttonRGB = tostring(buttonR)..","..tostring(buttonG)..","..tostring(buttonB)
    local buttonborderR, buttonborderG, buttonborderB = webColors.namedColor2RGB(params.Menu_Settings.BUTTON_BORDER_COLOR.value)
    local buttonborderRGB = tostring(buttonborderR)..","..tostring(buttonborderG)..","..tostring(buttonborderB)

    self.css.base = [[
        BODY {
            background:rgba(0, 0, 0, 0);
            color:#000000;
            width:100vw;
            height:100vh;
        }
        DIV.WinLib_window {
            position:absolute;
            background:rgba(]]..windowRGB..[[, ]]..WCA..[[);
            color:]]..WTC..[[;
            font-family:"Arial", Sans-Serif;
            box-shadow:0px 1px rgba(128, 128, 128, 0.5);
            font-size:15px;
            text-align:middle;
            fill:]]..WTC..[[;
        }
        DIV.WinLib_window_title {
            height:20px;
            background-color: rgba(]]..tittleRGB..[[, ]]..TCA..[[);
            background-image: white;
            color:]]..TTC..[[;
            font-size:16px;
            text-align:center;
            padding-left:4px;
            font-family:"Bank";
        }
        DIV.WinLib_window>.WinLib_content {
            padding:4px;
            color:]]..WTC..[[;
            fill:]]..WTC..[[;
        }
        DIV.WinLib_button {
            position:absolute;
            background: rgba(]]..buttonRGB..[[, ]]..BCA..[[);
            border:1px solid rgb(]]..buttonborderRGB..[[);
            font-family:"Play";
            font-size:12px;
            text-align: center;
            vertical-align: text-top;
            color:]]..BTC..[[;
            overflow:hidden;
            padding-top:5px;
        }
        .widgets {
            background:rgba(0, 0, 0, 0) !important;
            box-shadow:0px 0px rgba(0, 0, 0, 0) !important;
        }
        .widgetnopadding {
            padding: 0px !important;
            padding-top: 0px !important;
            padding-left: 0px !important;
        }
        .separator {
            background:rgba(0, 0, 0, 0) !important;
            border:0px solid rgba(0, 0, 0, 0) !important;
            font-size:0px !important;
            color:rgba(0, 0, 0, 0) !important;
            box-shadow:0px 0px rgba(0, 0, 0, 0) !important;
            border: 0px solid rgba(0, 0, 0, 0) !important;
        }
        .Help_Menu {
            font-family:"Play" !important;
            font-size:14px !important;
        }
        .buttonHover {
            position:absolute;
            border: 3px solid rgb(]]..buttonborderRGB..[[) !important;
            font-family:"Play" !important;
            font-size:13px !important;
            text-align: center !important;
            vertical-align: text-top !important;
            box-shadow:3px 2px rgba(50, 50, 50, 0.5) !important;
            color:]]..BTC..[[ !important;
            overflow:hidden !important;
            padding-top:2px !important;
        }
        .mapPlanet {
            position:absolute;
            border: 0px solid rgba(0, 0, 0, 0)!important;
            background: rgba(0, 0, 0, 0)!important;
            font-family:"Play" !important;
            font-size:25px !important;
            text-align: center !important;
            vertical-align: text-top !important;
            box-shadow:0px 0px rgba(0, 0, 0, 0) !important;
            color:]]..BTC..[[ !important;
            overflow:visible !important;
            padding-top:0px !important;
        }
        .mapMarker {
            position:absolute;
            border: 0px solid rgba(0, 0, 0, 0)!important;
            background: rgba(0, 0, 0, 0)!important;
            font-family:"Play" !important;
            font-size:25px !important;
            text-align: center !important;
            vertical-align: text-top !important;
            box-shadow:0px 0px rgba(0, 0, 0, 0) !important;
            color:]]..wTC..[[ !important;
            overflow:visible !important;
            padding-top:0px !important;
        }
        .fixed {
            z-index:1 !important;
        }
        .demo {
        text-align:center;
        }
        #blink {
            background: linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet);
            -webkit-background-clip: text;
            background-clip: text;
            color:transparent;
            background-size: 400%% 100%%;
            animation: rainbow 10s ease-in-out infinite;
            text-align:center;
        font-family:"Play" !important;
        font-weight:bold;
        }
        @keyframes rainbow {
            0%%,100%% {
                background-position: 0 0;
            }
    
            50%% {
                background-position: 100%% 0;
            }
        }]]
end
--WindowLibPlusPlus.winlibCSSUpdate()

WindowLibPlusPlus.css.window_block = [[

    #{wlib_id} {
        width:{wlib_width}px;
        height:{wlib_height}px;
        top:{wlib_posY}px;
        left:{wlib_posX}px;
        z-index:{wlib_zIndex};
    }
    #{wlib_id}>.WinLib_window_title {
        height:{wlib_title_height}px;
        line-height:{wlib_title_height}px;
    }
    {wlib_buttons_generated}]]
WindowLibPlusPlus.css.button_block = [[

    #{wlib_id} {
        width:{wlib_width}px;
        height:{wlib_height}px;
        top:{wlib_posY}px;
        left:{wlib_posX}px;
    }]]
WindowLibPlusPlus.css.generated_block = [[
    <style>
{wlib_css_generated}
    </style>
]]

-- WindowLibPlusPlus HTML
WindowLibPlusPlus.html = {}
WindowLibPlusPlus.html.base = [[

<style type="text/css">
{wlib_css}
{wlib_css_generated}
</style>
{wlib_html_generated}
]]
WindowLibPlusPlus.html.window = [[
<DIV class="WinLib_window {wlib_custom_class}" id="{wlib_id}">
{wlib_title_bar}
    <DIV class="WinLib_content">
{wlib_html}
{wlib_buttons_generated}
    </DIV>
</DIV>]]
WindowLibPlusPlus.html.window_title = [[
    <DIV class="WinLib_window_title" id="title_bar">
        {wlib_title}
    </DIV>]]
WindowLibPlusPlus.html.button = [[
    <DIV class="WinLib_button {wlib_custom_class}" id="{wlib_id}">
        {wlib_html}
    </DIV>]]

--WindowLibPlusPlus: Window object
function WindowLibPlusPlus.new(self,html,options,buttons)
--DUSystem.print("creating a window "..options.name)
    local window        = {} -- Window object (new)

    -- User-provided properties (via options)
    window.name         = nil -- Custom window name
    window.title        = nil -- Not provided via exported variable
    window.class        = nil -- Custom class name for styling
    window.posX         = Default_Window_Position_X -- Window position on the X axis
    window.posY         = Default_Window_Position_Y -- Window position on the Y axis
    window.width        = Default_Window_Width -- Window width
    window.height       = Default_Window_Height -- Window Height
    window.titleHeight  = Default_Window_TitleBar_Height -- Window Title bar height
    window.draggable    = false -- Window allowed to be dragged
    window.alwaysOnTop  = false -- Window always on top
    window.fixed        = false -- Prevents the window from going over others

    -- Assign user-provided properties
    if options ~= nil then
        window.name    = (options.name ~= nil) and options.name or window.name
        window.title    = (options.title ~= nil) and options.title or window.title
        window.class    = (options.class ~= nil) and options.class or window.class
        window.posX     = (options.posX ~= nil) and options.posX or window.posX
        window.posY     = (options.posY ~= nil) and options.posY or window.posY
        window.width    = (options.width ~= nil) and options.width or window.width
        window.height   = (options.height ~= nil) and options.height or window.height
        window.titleHeight = (options.titleHeight ~= nil) and options.titleHeight or window.titleHeight
        if options.draggable == nil or options.draggable == true then window.draggable = true else window.draggable = false end
        if options.alwaysOnTop == nil or options.alwaysOnTop == false then window.alwaysOnTop = false else window.alwaysOnTop = true end
        if options.fixed == nil or options.fixed == false then window.fixed = false else window.fixed = true end
    end

    -- Assign buttons if provided
    window.buttons      = (buttons == nil) and {} or buttons

    -- Generated properties
    self.index          = self.index + 1 -- Global index increment
    window.id           = "wlib_window_" .. self.index -- Unique ID
    window.html         = (html == nil) and "" or html -- Content provided by the user

    -- Z-index increment
    if window.fixed == true then
        window.zIndex   = -100
    else
        window.zIndex   = (window.alwaysOnTop == true) and 999999 + self.index or self.index -- Z position (determines if it's in front of the others)
    end

    -- Empty output properties
    window.css          = ""
    window.content      = ""

    -- Update the window object and it's content
    window.refresh      = function()
        -- Generate our buttons blocks
        local button_html  = ""
        local button_css   = ""

        for i, button in pairs(window.buttons) do
            button:refresh()
            button_html = button_html .. button.content
            button_css  = button_css .. button.css
        end

        window.css      = self.css.window_block
                            :gsub("{wlib_id}",window.id)
                            :gsub("{wlib_width}",window.width)
                            :gsub("{wlib_height}",window.height)
                            :gsub("{wlib_posX}",window.posX)
                            :gsub("{wlib_posY}",window.posY)
                            :gsub("{wlib_zIndex}",window.zIndex)
                            :gsub("{wlib_title_height}",window.titleHeight)
                            :gsub("{wlib_buttons_generated}",button_css)

        local title_bar = (window.title == nil) and "" or self.html.window_title
                                                            :gsub("{wlib_title}",window.title)
        local custom_class = (window.class == nil) and "" or window.class
        window.content = self.html.window
                            :gsub("{wlib_id}",window.id)
                            :gsub("{wlib_custom_class}",custom_class)
                            :gsub("{wlib_title_bar}",title_bar)
                            :gsub("{wlib_html}",window.html)
                            :gsub("{wlib_buttons_generated}",button_html)
    end

    -- Updates the HTML within the window
    window.setHTML      = function(content)
        window.html     = content
    end

    -- Updates the window's title
    window.setTitle     = function(content)
        window.title    = content
    end
    
    -- Updates the window's pos
    window.setPos     = function(x,y)
        window.posX    = x
        window.posY    = y
    end

    -- Removes the window
    window.delete       = function()
        self.windows[window.id] = nil
    end

    self.windows[window.id] = window -- Add the new window to the generated stack
    return window -- Returns the window to the user
end

function WindowLibPlusPlus.toggleClick(self,bool)
    --DUSystem.print("clicking detected")
    self.CLICK = bool
end

-- WindowLibPlusPlus update: Compiles our content into strings and updates the screen with it
function WindowLibPlusPlus.update(self)
    --DUSystem.print("win update start")
    self:mouseListener() -- Perform mouse listening each frame
    if params.window_open == false and params.Travel_Planner.window_open == false then
        local svg = ""
        for k1, window in pairs(self.windows) do
            if params.Widget_Speedo.window_open == true and window.name == params.Widget_Speedo.window_tittle then
                svg = widget:Speedometer_Update()
                if svg then 
                    window.setHTML(svg)
                else
                    window.setHTML("")
                end
            end
            if params.Widget_Gyro.window_open == true and window.name == params.Widget_Gyro.window_tittle then
                svg = widget:Gyroscope_Update()
                if svg then
                    window.setHTML(svg)
                else
                    window.setHTML("")
                end
            end
            if params.Widget_FuelTanks.window_open == true then
                for i, v in ipairs(fuelTanksData) do
                    if window.name == params["Widget_FuelTank_"..i].window_tittle then
                        svg = widget:Fueltanks_Update(i)
                        if svg then 
                            window.setHTML(svg)
                        else
                            window.setHTML("")
                        end
                    end
                end
            end
            if params.Widget_Info.window_open == true and window.name == params.Widget_Info.window_tittle then
                svg = widget:Info_Update()
                if svg then 
                    window.setHTML(svg)
                else
                    window.setHTML("")
                end
            end
            if params.Widget_Map.window_open == true and window.name == params.Widget_Map.window_tittle then
                svg = widget:Map_Update()
                if svg then
                    window.setHTML(svg)
                else
                    window.setHTML("")
                end
            end
            for i, v in ipairs(customWidgets) do
                if params["Widget_Custom"..i].window_open == true and window.name == params["Widget_Custom"..i].window_tittle then
                    local custom_widget = customWidgets[i]
                    svg = custom_widget:SVG_Update()
                    if svg then
                        window.setHTML(svg)
                        if #custom_widget.buttons > 0 then
                            for i2, window_button in ipairs(window.buttons) do
                                for ___, custom_button in ipairs(custom_widget.buttons) do
                                    if window.buttons[i2].name == custom_button.name then
                                        --DUSystem.print(window.buttons[i2].name.." / "..window.buttons[i2].posX)
                                        self.windows[k2].buttons[i2].class    = custom_button.class
                                        self.windows[k2].buttons[i2].posX     = custom_button.posX
                                        self.windows[k2].buttons[i2].posY     = custom_button.posY
                                        self.windows[k2].buttons[i2].width    = custom_button.width
                                        self.windows[k2].buttons[i2].height   = custom_button.height
                                        self.windows[k2].buttons[i2].__click  = custom_button.button_function()
                                        self.windows[k2].buttons[i2].refresh()
                                    end
                                end
                            end
                        end
                    else
                        window.setHTML("")
                    end
                end
            end
        end
    end
        -- Empty output properties
    local gen_css       = ""
    local windows       = ""
    --DUSystem.print("win update 1 :")
    -- Loop through our window objects
    for _, window in pairs(self.windows) do
        --DUSystem.print("win update 1a "..window.name)
        window:refresh() -- Updates our window content; Done in separate space for convenience
        --DUSystem.print("win update 1b")
        gen_css         = gen_css .. window.css -- Appends to the generated CSS property
        --DUSystem.print("win update 1c")
        windows         = windows .. window.content -- Appends to the windows property
        --DUSystem.print("win update 1d")
        if window.name == "cursor" then
            --DUSystem.print("name cursor")
            --DUSystem.print(cursorX.." / "..cursorY)
            window.posX = cursorX
            window.posY = cursorY
        end
    end
    --DUSystem.print("win update 2")
    local generated     = self.html.base
                            :gsub("{wlib_css}",self.css.base) -- Add base CSS
                            :gsub("{wlib_css_generated}",gen_css) -- Add base CSS
                            :gsub("{wlib_html_generated}",windows) -- Add generated content
    --screen_1.resetContent(self.screen, generated) -- Add the content to our screen
    --DUSystem.print("set screen before")
    if self.previousGenerated ~= generated then
        DUSystem.setScreen(generated)
    end
    self.previousGenerated = generated
    --DUSystem.print("set screen after")
end

-- Listens for window grab events
function WindowLibPlusPlus.mouseListener(self)
    if params.window_open == true or params.QuickToolBar.window_open == true or params.Travel_Planner.window_open == true then
        local mouse     = self:getMousePos()
        mouseWheel = DUSystem.getMouseWheel()
        if mouseWheel ~= 0 then self.CLICK = true end
        --DUSystem.print(tostring(self.CLICK))
        
        --if self.CLICK == true and self.grabbed == nil then -- Only works if nothing else is grabbed
        if self.grabbed == nil then 
            --DUSystem.print("click")
            --if cursorWin ~= "" then cursorWin.delete() end
            -- Cycle through windows to check if clicked
            --DUSystem.print("cursor deleted")
            for _, window in pairs(self.windows) do
                --DUSystem.print("cycling trhough windows")
                if window.name ~= "cursor" then
                    local bound = { x1 = window.posX, y1 = window.posY,
                                    x2 = window.posX + window.width, y2 = window.posY + window.height } -- Our window's bounds
                    --DUSystem.print(window.posX.."/"..window.posY)
                    if(mouse.x >= bound.x1 and mouse.y >= bound.y1
                            and mouse.x <= bound.x2 and mouse.y <= bound.y2) then -- Check if clicked within bounds
                        if(self.grabbed == nil) then -- If there's nothing assigned yet
                            self.grabbed = window
                            --DUSystem.print(window.name)
                        else -- Check against grabbed
                            if(window.zIndex > self.grabbed.zIndex) then -- Replace if zIndex is higher
                                self.grabbed = window -- This assures we don't grab a window behind
                                --DUSystem.print(window.name)
                            end
                        end
                    end
                end
            end
    
            if(self.grabbed ~= nil) then -- If something was grabbed, act upon it
                self:buttonCheck() -- Check for a button click
                if self.grabbed.zIndex ~= self.index and self.CLICK ~= false then -- Only increment if not already on top
                    if(self.grabbed.alwaysOnTop ~= true) then
                        self.index = self.index + 1 -- Increment our index
                        self.grabbed.zIndex = self.index -- Bring our window to the front
                        --DUSystem.print("zindex")
                    end
                end
                
                if self.grabbed.draggable == true then -- Only act if we're allowed to
                    if(self.grabbed.title == nil) then -- Perform the drag from anywhere on the window
                        self:beginDrag()
                    elseif(mouse.y <= self.grabbed.posY + self.grabbed.titleHeight) then -- Only from the title bar
                        self:beginDrag()
                    else -- If we haven't grabbed a valid spot, release the grab
                        self.grabbed = nil
                    end
                else
                    self.grabbed = nil
                end
            end
        --elseif mouseWheel ~= 0 then
        --    self.buttonCheck() -- Check for a button hover
        else
            self.buttonLock = nil -- Release the button lock
        end
        if mouseWheel ~= 0 then
            self.CLICK = false
            --mouseWheel = 0
        end
    end
end

-- Prepare to drag the window
function WindowLibPlusPlus.beginDrag(self)
    
        local mouse = self:getMousePos() -- Get the mouse position
        self.grabbed.offset = {x = mouse.x - self.grabbed.posX,
                            y = mouse.y - self.grabbed.posY} -- Get the offset of the mouse from the top left
    -- wlib_drag timer uses a tick with the content: WindowLibPlusPlus:performDrag()
    --unit.setTimer("wlib_drag",1/refresh_rate) -- Loop the drag action
    self.wlib_drag = true
end

-- Drag the window
function WindowLibPlusPlus.performDrag(self)
    if self.CLICK == true and mouseWheel == 0 then -- If our mouse is still down
    --system.print("performDrag")
        local mouse     = self:getMousePos() -- Get the mouse position
        local new_x     = tonumber(string.format("%.2f",mouse.x - self.grabbed.offset.x)) -- Rounded new X position
        local new_y     = tonumber(string.format("%.2f",mouse.y - self.grabbed.offset.y)) -- Rounded new Y position

        -- Move window position; Additional check prevents hold flickering
        self.grabbed.posX = (self.grabbed.posX ~= new_x) and new_x or self.grabbed.posX -- Move along the X axis
        self.grabbed.posY = (self.grabbed.posY ~= new_y) and new_y or self.grabbed.posY -- Move along the Y axis
        
        Save_Window_Pos(self.grabbed.name,self.grabbed.posX,self.grabbed.posY)
        --DUSystem.print(self.grabbed.name)
    elseif mouseWheel ~= 0 then
        for i, v in pairs(params) do
            if string.sub (tostring(i),1,7) == "Widget_" and params[i].window_tittle == self.grabbed.name then
                params[i].window_scale = params[i].window_scale + 0.05 * mouseWheel
                DUSystem.print(params[i].window_tittle.." widget scale: "..params[i].window_scale)
                self.CLICK = false
                windowsShow()
            end
        end
    else -- If we've let go of the mouse
        self:releaseWindow() -- Stop dragging
    end
end

-- Stop dragging
function WindowLibPlusPlus.releaseWindow(self)
    --system.print("releaseWindow")
    self.grabbed = nil -- Clear the dragged property
    --unit.stopTimer("wlib_drag") -- Stop the drag loop
    self.wlib_drag = false
end

-- Perform a click check (only on release to avoid a loop)
function WindowLibPlusPlus.buttonCheck(self)
    for _, button in pairs(self.grabbed.buttons) do
        
        local mouse     = self:getMousePos() -- Get the mouse position
        local bound = { x1 = button.posX + self.grabbed.posX,
                        y1 = button.posY + self.grabbed.posY,
                        x2 = button.posX + self.grabbed.posX + button.width,
                        y2 = button.posY + self.grabbed.posY + button.height } -- Our button's bounds
        if(mouse.x >= bound.x1 and mouse.x <= bound.x2 and
                mouse.y >= bound.y1 and mouse.y <= bound.y2 and
                self.buttonLock ~= button) then -- Check if hovering within bounds
            --button:setClass("buttonHover")
            for k1, window in pairs(self.windows) do
                for i1, wbutton in ipairs(window.buttons) do
                    if button.id == wbutton.id and button.class ~= "separator" and button.class ~= "mapMarker" and button.class ~= "mapPlanet" then--and button.class ~= nil and string.sub(button.class,1,3) ~= "map" then
                        self.windows[k1].buttons[i1].class = "buttonHover"
                        --self.windows[k1]:refresh()
                    end
                end
            end
            if self.CLICK == true then
                self.buttonLock = button
                button:__click()
                self.CLICK = false
            end
        else
            for k1, window in pairs(self.windows) do
                for i1, wbutton in ipairs(window.buttons) do
                    if button.id == wbutton.id and button.class ~= "separator" and button.class ~= "mapMarker" and button.class ~= "mapPlanet" then
                        self.windows[k1].buttons[i1].class = ""
                        --self.windows[k1]:refresh()
                    end
                end
            end
        end
    end
    --DUSystem.print("button checked")
end

-- Get our mouse position (in pixels)
function WindowLibPlusPlus.getMousePos(self)
        cursorX = DUSystem.getMousePosX()
        cursorY = DUSystem.getMousePosY()
        --ScreenHeight = system.getScreenHeight()
        --ScreenWidth = system.getScreenWidth()
    -- Interesting fact: Screens are 1024px x 612px
    --return {
    --    x               = screen_1.getMouseX()*1024, -- Convert percent to pixels
    --    y               = screen_1.getMouseY()*612 -- Convert percent to pixels
    --}
    return {
        x               = cursorX, -- Convert percent to pixels
        y               = cursorY -- Convert percent to pixels
    }
end


-- WindowLibPlusPlus buttons


-- WindowLibPlusPlus: Button object
function WindowLibPlusPlus.buttonsNew(self, html, onclick, options)
    local button        = {} -- Button object (new)
    
    -- User-provided properties (via options)
    button.name         = nil
    button.class        = nil -- Custom class name for styling
    button.posX         = Default_Button_Position_X -- Button position on the X axis
    button.posY         = Default_Button_Position_Y -- Button position on the Y axis
    button.width        = Default_Button_Width -- Button width
    button.height       = Default_Button_Height -- Window Height
    
    -- Assign user-provided properties
    if(options ~= nil) then
        button.name    = (options.name ~= nil) and options.name or button.name
        button.class    = (options.class ~= nil) and options.class or button.class
        button.posX     = (options.posX ~= nil) and options.posX or button.posX
        button.posY     = (options.posY ~= nil) and options.posY or button.posY
        button.width    = (options.width ~= nil) and options.width or button.width
        button.height   = (options.height ~= nil) and options.height or button.height
    end
    
    -- Generated properties
    self.index     = self.index + 1 -- Global index increment
    button.id           = "wlib_button_" .. self.index -- Unique ID
    button.html         = (html == nil) and "" or html -- Content provided by the user
    
    -- Empty output properties
    button.css          = ""
    button.previousCSS = ""
    button.previousContent = ""
    -- Update the button object and it's content
    button.refresh      = function()
        
            button.css      = self.css.button_block
                                :gsub("{wlib_id}",button.id)
                                :gsub("{wlib_width}",button.width)
                                :gsub("{wlib_height}",button.height)
                                :gsub("{wlib_posX}",button.posX)
                                :gsub("{wlib_posY}",button.posY)
            local custom_class = (button.class == nil) and "" or button.class
            button.content  = self.html.button
                                :gsub("{wlib_id}",button.id)
                                :gsub("{wlib_custom_class}",custom_class)
                                :gsub("{wlib_html}",button.html)
        end
    button.previousCSS = button.css
    button.previousContent = button.content
    
    button.__click = onclick -- Set click function
    --button.__steer = onsteer -- Set mouse wheel function
    
    -- Override click function
    button.setClick = function(clickMethod)
        button.__click = clickMethod
    end
    
    -- Updates the HTML within the button
    button.setHTML      = function(content)
        button.html     = content
    end
    
    -- Updates the class within the button
    button.setClass      = function(content)
        button.class     = content
    end
    --DUSystem.print(button.html)
    return button
end


