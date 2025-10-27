local UILib = {}
UILib.__index = UILib

local ESP_FONTSIZE = 13
local BLACK = Color3.new(0, 0, 0)

local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    return drawing
end

local function destroyAllDrawings(drawings)
    for _, drawing in ipairs(drawings) do
        if drawing and drawing.Remove then
            drawing:Remove()
        end
    end
end

local function getMousePos()
    return Vector2.new(mouse.X, mouse.Y)
end

local KEY_MAP = {
    ['m1'] = 0x01, ['m2'] = 0x02, ['mb'] = 0x04, ['unbound'] = 0x08,
    ['tab'] = 0x09, ['enter'] = 0x0D, ['shift'] = 0x10, ['ctrl'] = 0x11,
    ['alt'] = 0x12, ['pause'] = 0x13, ['capslock'] = 0x14, ['esc'] = 0x1B,
    ['space'] = 0x20, ['pageup'] = 0x21, ['pagedown'] = 0x22, ['end'] = 0x23,
    ['home'] = 0x24, ['left'] = 0x25, ['up'] = 0x26, ['right'] = 0x27,
    ['down'] = 0x28, ['insert'] = 0x2D, ['delete'] = 0x2E,
    ['0'] = 0x30, ['1'] = 0x31, ['2'] = 0x32, ['3'] = 0x33, ['4'] = 0x34,
    ['5'] = 0x35, ['6'] = 0x36, ['7'] = 0x37, ['8'] = 0x38, ['9'] = 0x39,
    ['a'] = 0x41, ['b'] = 0x42, ['c'] = 0x43, ['d'] = 0x44, ['e'] = 0x45,
    ['f'] = 0x46, ['g'] = 0x47, ['h'] = 0x48, ['i'] = 0x49, ['j'] = 0x4A,
    ['k'] = 0x4B, ['l'] = 0x4C, ['m'] = 0x4D, ['n'] = 0x4E, ['o'] = 0x4F,
    ['p'] = 0x50, ['q'] = 0x51, ['r'] = 0x52, ['s'] = 0x53, ['t'] = 0x54,
    ['u'] = 0x55, ['v'] = 0x56, ['w'] = 0x57, ['x'] = 0x58, ['y'] = 0x59,
    ['z'] = 0x5A, ['numpad0'] = 0x60, ['numpad1'] = 0x61, ['numpad2'] = 0x62,
    ['numpad3'] = 0x63, ['numpad4'] = 0x64, ['numpad5'] = 0x65, ['numpad6'] = 0x66,
    ['numpad7'] = 0x67, ['numpad8'] = 0x68, ['numpad9'] = 0x69, ['multiply'] = 0x6A,
    ['add'] = 0x6B, ['separator'] = 0x6C, ['subtract'] = 0x6D, ['decimal'] = 0x6E,
    ['divide'] = 0x6F, ['f1'] = 0x70, ['f2'] = 0x71, ['f3'] = 0x72, ['f4'] = 0x73,
    ['f5'] = 0x74, ['f6'] = 0x75, ['f7'] = 0x76, ['f8'] = 0x77, ['f9'] = 0x78,
    ['f10'] = 0x79, ['f11'] = 0x7A, ['f12'] = 0x7B, ['numlock'] = 0x90,
    ['scrolllock'] = 0x91, ['lshift'] = 0xA0, ['rshift'] = 0xA1, ['lctrl'] = 0xA2,
    ['rctrl'] = 0xA3, ['lalt'] = 0xA4, ['ralt'] = 0xA5, ['semicolon'] = 0xBA,
    ['plus'] = 0xBB, ['comma'] = 0xBC, ['minus'] = 0xBD, ['period'] = 0xBE,
    ['slash'] = 0xBF, ['tilde'] = 0xC0, ['lbracket'] = 0xDB, ['backslash'] = 0xDC,
    ['rbracket'] = 0xDD, ['quote'] = 0xDE
}

function UILib.new(name, size, watermarkActivity)
    repeat wait(1/9999) until isrbxactive()
    
    local self = setmetatable({}, UILib)
    
    self:_initProperties(name, size, watermarkActivity)
    self:_setupTheme()
    self:_createUIElements()
    
    return self
end

function UILib:_initProperties(name, size, watermarkActivity)
    self.identity = name
    self._watermark_activity = watermarkActivity
    self.x, self.y = 20, 60
    self.w = size and size.x or 300
    self.h = size and size.y or 400
    
    -- Input system
    self._inputs = {}
    for key, id in pairs(KEY_MAP) do
        self._inputs[key] = { id = id, held = false, click = false }
    end
    
    -- State management
    self._open = true
    self._watermark = true
    self._active_tab = nil
    self._dragging = false
    self._drag_offset = Vector2.new(0, 0)
    self._active_dropdown = nil
    self._active_colorpicker = nil
    self._clipboard_color = nil
    self._tick = os.clock()
    self._base_opacity = 0
    
    -- Styling
    self._title_h, self._tab_h, self._padding, self._gradient_detail = 25, 20, 6, 80
end

function UILib:_setupTheme()
    self._color_accent = Color3.fromRGB(255, 127, 0)
    self._color_text = Color3.fromRGB(255, 255, 255)
    self._color_crust = Color3.fromRGB(0, 0, 0)
    self._color_border = Color3.fromRGB(25, 25, 25)
    self._color_surface = Color3.fromRGB(38, 38, 38)
    self._color_overlay = Color3.fromRGB(76, 76, 76)
end

function UILib:_createUIElements()
    local elements = {}
    
    local windowElements = {
        createDrawing('Square', { Filled = true, Color = self._color_surface }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_crust }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_border }),
        createDrawing('Square', { Filled = true, Color = self._color_border }),
        createDrawing('Text', { Text = self.identity, Outline = true, Color = self._color_text })
    }
    
    local watermarkElements = {
        createDrawing('Square', { Filled = true, Color = self._color_surface }),
        createDrawing('Square', { Filled = true, Color = self._color_accent }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_crust }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_border }),
        createDrawing('Text', { Text = self.identity, Outline = true, Color = self._color_text })
    }
    
    for _, elem in ipairs(windowElements) do table.insert(elements, elem) end
    for _, elem in ipairs(watermarkElements) do table.insert(elements, elem) end
    
    self._tree = {
        _tabs = {},
        _drawings = elements
    }
end

function UILib:ToggleWatermark(state) self._watermark = state end
function UILib:ToggleMenu(state) self._open = state end
function UILib:IsMenuOpen() return self._open end

function UILib:Tab(name)
    local tab = {
        name = name,
        _sections = {},
        _drawings = {
            createDrawing('Square', { Color = self._color_border, Filled = true }),
            createDrawing('Square', { Color = BLACK, Filled = true }),
            createDrawing('Square', { Color = self._color_accent, Filled = true }),
            createDrawing('Text', { Color = self._color_text, Outline = true, Text = name })
        }
    }
    
    table.insert(self._tree._tabs, tab)
    if not self._active_tab then self._active_tab = name end
    
    return name
end

function UILib:Section(tabName, name)
    for _, tab in ipairs(self._tree._tabs) do
        if tab.name == tabName then
            local section = {
                name = name,
                _items = {},
                _drawings = {
                    createDrawing('Square', { Filled = true, Color = self._color_surface }),
                    createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_crust }),
                    createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_overlay }),
                    createDrawing('Text', { Text = name, Outline = true, Color = self._color_text })
                }
            }
            table.insert(tab._sections, section)
            return name
        end
    end
end

function UILib:_addItem(tabName, sectionName, itemType, value, callback, drawings, meta)
    for _, tab in ipairs(self._tree._tabs) do
        if tab.name == tabName then
            for _, section in ipairs(tab._sections) do
                if section.name == sectionName then
                    local item = {
                        type = itemType,
                        value = value,
                        callback = callback,
                        _drawings = drawings
                    }
                    if meta then for k, v in pairs(meta) do item[k] = v end end
                    table.insert(section._items, item)
                    return
                end
            end
        end
    end
end

function UILib:Checkbox(tabName, sectionName, label, defaultValue, callback)
    local drawings = {
        createDrawing('Square', { Color = self._color_crust, Thickness = 1, Filled = false }),
        createDrawing('Square', { Color = self._color_accent, Filled = true }),
        createDrawing('Square', { Color = BLACK, Filled = true }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label })
    }
    self:_addItem(tabName, sectionName, 'checkbox', defaultValue, callback, drawings)
end

function UILib:Slider(tabName, sectionName, label, defaultValue, callback, min, max, step, appendix)
    local drawings = {
        createDrawing('Square', { Color = self._color_crust, Filled = true }),
        createDrawing('Square', { Color = self._color_accent, Filled = true }),
        createDrawing('Square', { Color = BLACK, Filled = true }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = tostring(defaultValue) }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label })
    }
    self:_addItem(tabName, sectionName, 'slider', defaultValue, callback, drawings, {
        min = min, max = max, step = step, appendix = appendix
    })
end

function UILib:Choice(tabName, sectionName, label, defaultValue, callback, choices, multi)
    local drawings = {
        createDrawing('Square', { Color = self._color_crust, Thickness = 1, Filled = false }),
        createDrawing('Square', { Color = self._color_crust, Filled = true }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = ">" }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label })
    }
    self:_addItem(tabName, sectionName, 'choice', defaultValue, callback, drawings, {
        choices = choices, multi = multi
    })
end

function UILib:Colorpicker(tabName, sectionName, label, defaultValue, callback)
    local drawings = {
        createDrawing('Square', { Color = self._color_crust, Thickness = 1, Filled = false }),
        createDrawing('Square', { Color = self._color_crust, Filled = true }),
        createDrawing('Square', { Color = BLACK, Filled = true }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label })
    }
    self:_addItem(tabName, sectionName, 'colorpicker', defaultValue, callback, drawings, {
        label = label
    })
end

function UILib:Button(tabName, sectionName, label, callback)
    local drawings = {
        createDrawing('Square', { Color = self._color_crust, Thickness = 1, Filled = false }),
        createDrawing('Square', { Color = self._color_crust, Filled = true }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label })
    }
    self:_addItem(tabName, sectionName, 'button', nil, callback, drawings, {
        label = label
    })
end

function UILib:Keybind(tabName, sectionName, label, defaultValue, callback, mode)
    local drawings = {
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = label }),
        createDrawing('Square', { Color = self._color_crust, Thickness = 1, Filled = false }),
        createDrawing('Square', { Color = self._color_crust, Filled = true }),
        createDrawing('Text', { Color = self._color_text, Outline = true, Text = defaultValue })
    }
    self:_addItem(tabName, sectionName, 'key', defaultValue, callback, drawings, {
        mode = mode or 'Hold', _listening = false, _state = nil
    })
end

function UILib:CreateSettingsTab(customName)
    local menuTab = self:Tab(customName or 'Menu')
    local menuSettings = self:Section(menuTab, 'Settings')
    
    self:Keybind(menuTab, menuSettings, 'Open key', 'f1', function(state)
        self:ToggleMenu(state)
    end, 'Toggle')
    
    self:Checkbox(menuTab, menuSettings, 'Watermark', true, function(state)
        self:ToggleWatermark(state)
    end)
    
    self:Checkbox(menuTab, menuSettings, 'Debug', false, nil)
    
    local menuTheme = self:Section(menuTab, 'Theming')
    self:_setupThemeSettings(menuTab, menuTheme)
    
    return menuTab, menuSettings, menuTheme
end

function UILib:_setupThemeSettings(tab, section)
    local presetThemes = {'X11', 'Nord', 'Dracula', 'Catppuccin'}
    local themes = {
        X11 = { {255, 128, 0}, {38, 38, 38}, {25, 25, 25}, {76, 76, 76}, {0, 0, 0} },
        Nord = { {135, 206, 235}, {49, 54, 60}, {72, 80, 90}, {61, 66, 73}, {88, 96, 106} },
        Dracula = { {243, 67, 54}, {40, 44, 59}, {64, 71, 89}, {29, 31, 45}, {72, 73, 95} },
        Catppuccin = { {240, 160, 200}, {48, 47, 63}, {72, 71, 89}, {63, 62, 80}, {33, 32, 44} }
    }
    
    self:Choice(tab, section, 'Preset theme', {presetThemes[1]}, function(values)
        local themeName = values[1]
        local theme = themes[themeName]
        if theme then
            local themingItems = self._tree._tabs[#self._tree._tabs]._sections[2]._items
            local colorItems = {'Accent', 'Base', 'Inner stroke', 'Outer stroke', 'Crust'}
            
            for i, itemName in ipairs(colorItems) do
                local item = themingItems[i + 1] -- +1 to skip preset theme item
                if item then
                    item.value = theme[i]
                    if item.callback then
                        item.callback(Color3.fromRGB(unpack(theme[i])))
                    end
                end
            end
        end
    end, presetThemes, false)
    
    self:Colorpicker(tab, section, 'Accent', {255, 128, 0}, function(newColor)
        self._color_accent = newColor
    end)
    
    self:Colorpicker(tab, section, 'Base', {38, 38, 38}, function(newColor)
        self._color_surface = newColor
    end)
    
    self:Colorpicker(tab, section, 'Inner stroke', {25, 25, 25}, function(newColor)
        self._color_border = newColor
    end)
    
    self:Colorpicker(tab, section, 'Outer stroke', {76, 76, 76}, function(newColor)
        self._color_overlay = newColor
    end)
    
    self:Colorpicker(tab, section, 'Crust', {0, 0, 0}, function(newColor)
        self._color_crust = newColor
    end)
end

function UILib._GetTextBounds(str)
    return #str * ESP_FONTSIZE, ESP_FONTSIZE
end

function UILib._IsMouseWithinBounds(origin, size)
    local mousePos = getMousePos()
    return mousePos.x >= origin.x and mousePos.x <= origin.x + size.x and
           mousePos.y >= origin.y and mousePos.y <= origin.y + size.y
end

function UILib:_RemoveDropdown()
    if self._active_dropdown then
        destroyAllDrawings(self._active_dropdown._drawings)
        self._active_dropdown = nil
    end
end

function UILib:_RemoveColorpicker()
    if self._active_colorpicker then
        destroyAllDrawings(self._active_colorpicker._drawings)
        self._active_colorpicker = nil
    end
end

function UILib:_SpawnDropdown(default, choices, multi, callback, position, width)
    self:_RemoveDropdown()
    
    local drawings = {
        createDrawing('Square', { Filled = true, Color = self._color_surface }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_crust }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_border })
    }
    
    for _, choice in ipairs(choices) do
        table.insert(drawings, createDrawing('Text', {
            Outline = true, Color = self._color_text, Text = choice
        }))
    end
    
    local choiceHash = {}
    for _, choice in ipairs(choices) do choiceHash[choice] = false end
    for _, default_ in ipairs(default) do choiceHash[default_] = true end
    
    self._active_dropdown = {
        choices = choiceHash,
        multi = multi,
        callback = callback,
        position = position,
        w = width,
        _drawings = drawings
    }
end

function UILib:_SpawnColorpicker(default, colorLabel, callback)
    self:_RemoveColorpicker()
    
    local drawings = {
        createDrawing('Square', { Filled = true, Color = self._color_surface }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_crust }),
        createDrawing('Square', { Filled = false, Thickness = 1, Color = self._color_border }),
        createDrawing('Square', { Filled = true, Color = self._color_border }),
        createDrawing('Text', { Outline = true, Color = self._color_text, Text = colorLabel }),
        createDrawing('Square', { Filled = true, Color = self._color_surface })
    }
    
    for _ = 1, self._gradient_detail * 3 do
        table.insert(drawings, createDrawing('Square', { Filled = true }))
    end
    
    local cursorTypes = {
        { 'Circle', { Filled = false, Thickness = 3, Radius = 6, NumSides = 20, Color = self._color_crust } },
        { 'Circle', { Filled = false, Thickness = 1, Radius = 6, NumSides = 20, Color = self._color_border } },
        { 'Square', { Filled = true, Color = self._color_border } },
        { 'Square', { Filled = false, Thickness = 1, Color = self._color_surface } },
        { 'Square', { Filled = false, Thickness = 1, Color = self._color_crust } }
    }
    
    for _, cursor in ipairs(cursorTypes) do
        table.insert(drawings, createDrawing(cursor[1], cursor[2]))
    end
    
    self._active_colorpicker = {
        callback = callback,
        _pallete_pos = nil,
        _slider_y = 0,
        _drawings = drawings
    }
end

return UILib
