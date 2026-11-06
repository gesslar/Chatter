---@class Glu

__PKGNAME__ = __PKGNAME__ or {
  config = {
    package_path = getMudletHomeDir() .. "/__PKGNAME__/",
    preferences_file = "__PKGNAME__.Preferences.lua",
    history_file = getMudletHomeDir() .. "/__PKGNAME__.History.lua",
    metrics = {
      tabs = {
        height = 25,
      }
    },
    dependencies = {
      { name = "Helper", url = "https://github.com/gesslar/Helper/releases/latest/download/Helper.mpackage" },
    },
    category = {
      type = {
        all = { display = "All", tooltip = "All channels", order = 1 },
        say = { display = "Say", tooltip = "Say channels", order = 2 },
        org = { display = "Org", tooltip = "Organisation channels", order = 3 },
        ooc = { display = "OOC", tooltip = "Out of Character channels", order = 4 },
        help = { display = "Help", tooltip = "Help channels", order = 5 },
      },
    },
    -- Every colour in the UI is derived from these.
    palette = {
      base = { 18, 22, 25 },           -- window and body background
      tab = { 0, 50, 0 },              -- tab bar and unselected tabs
      accent = { 82, 100, 0 },         -- selected tab, title, and intro
      message = color_table.sea_green, -- status messages in the main console
    },
    style = {},
    intro = "○",
    enable_intro = false,
    defaults = {
      size = 12,
    },
    font_size = { min = 6, max = 32 },
  },
  current = "all",
  groups = {},
  tabs = {},
  widget = {},
  prefs = {},
  history = {},
  glu = require("__PKGNAME__/vendor/Glu-single")("__PKGNAME__")
}

local glu = __PKGNAME__.glu

-- Colour formatting
--- Formats an RGB table as a decho colour tag, e.g. "<82,100,0>".
function __PKGNAME__.dtag(rgb)
  return "<" .. table.concat(rgb, ",") .. ">"
end

--- Formats an RGB table for a Qt stylesheet. Without alpha, this is a hex
--- colour; with alpha (0-100), it is an rgba() value.
function __PKGNAME__.css(rgb, alpha)
  -- to_hex also validates the colour, so both forms reject a bad one.
  local hex = glu.colour.to_hex(rgb)
  if alpha == nil then
    return hex
  end

  return "rgba(" .. table.concat(rgb, ",") .. "," .. alpha .. "%)"
end

-- Channel management
function __PKGNAME__.receiveComm(event)
  local channel = gmcp.Comm.Channel.Text.channel or ""
  local text = gmcp.Comm.Channel.Text.text or ""

  text = ansi2decho(text) --[[@as string]]

  -- Replace line breaks with spaces, to wrap!
  text = rex.gsub(text, "[\\r\\n]", " ") --[[@as string]]

  text = __PKGNAME__.style.console.default_fg .. text .. "\n"
  if __PKGNAME__.config.enable_intro == true then
    text = __PKGNAME__.style.intro .. "<r> " .. text
  end

  -- Everything goes to "all". A channel grouped under "all" itself, or under
  -- a group with no tab, has nowhere else to go.
  local group, groups = __PKGNAME__.groups[channel], { "all" }
  if group then
    if group.muted then
      groups = {}
    elseif group.group ~= "all" and __PKGNAME__.tabs[group.group] then
      groups[#groups + 1] = group.group
    end
  end

  __PKGNAME__.echo(groups, text)

  -- Maybe later
  -- Chatter.log(groups, text)
end

function __PKGNAME__.addWidget(widget)
  __PKGNAME__.widget = __PKGNAME__.widget or {}

  local name = widget.name

  __PKGNAME__.widget[name] = __PKGNAME__.widget[name] or widget
end

function __PKGNAME__.buildStyles()
  local palette = __PKGNAME__.config.palette
  local css = __PKGNAME__.css
  local dtag = __PKGNAME__.dtag

  local center = "qproperty-alignment: 'AlignCenter | AlignVCenter';" -- Center text
  local bold = "font-weight: bold;"                                   -- Bold text

  -- Tab text is a contrasting shade of its own background.
  local tab = {
    fg = {
      selected = glu.colour.lighten_or_darken(palette.accent, palette.accent, 85),
      unselected = glu.colour.lighten_or_darken(palette.tab, palette.tab, 85),
    },
    bg = {
      selected = palette.accent,
      unselected = palette.tab,
    }
  }

  local button = glu.colour.lighten(palette.base, 15)

  __PKGNAME__.style = {
    window = {
      adjLabel = "background-color:" .. css(palette.base) .. "; border: 1px solid " .. css(palette.base) .. ";",
      button = [[
      QLabel{ border-radius: 7px; background-color: ]] .. css(button, 50) .. [[;}
      QLabel::hover{ background-color: ]] .. css(button) .. [[;}
      ]],
    },
    header = {
      background = "background-color: " .. css(palette.tab) .. ";",
    },
    body = {
      background = "background-color: " .. css(palette.base) .. ";",
    },
    tabs = {
      selected = center .. " " .. bold,
      unselected = center .. " " .. bold,
      colours = tab,
    },
    console = {
      default_fg = dtag(tab.fg.unselected),
      background = " ",
    },
    title = {
      colour = dtag(palette.accent),
      format = "l13b",
    },
    message = {
      colour = dtag(palette.message),
    },
    intro = dtag(palette.accent) .. __PKGNAME__.config.intro,
  }
end

function __PKGNAME__.loadPrefs()
  __PKGNAME__.prefs = glu.preferences.load(
    nil,
    __PKGNAME__.config.preferences_file,
    __PKGNAME__.config.defaults
  )

  -- A size saved before the limits existed may lie outside them.
  local size = tonumber(__PKGNAME__.prefs.size) or __PKGNAME__.config.defaults.size
  __PKGNAME__.prefs.size = __PKGNAME__.clampFontSize(size)

  __PKGNAME__.savePrefs()
end

function __PKGNAME__.savePrefs()
  glu.preferences.save(
    nil,
    __PKGNAME__.config.preferences_file,
    __PKGNAME__.prefs
  )
end

--- Moves the window into a state, reporting the outcome and saving on success.
--- `field` is the window flag that reflects the state, and `target` the value
--- it holds once the window is there.
local function changeWindowState(field, target, method, verb, done, already)
  local window = __PKGNAME__.MainWindow
  local colour = __PKGNAME__.style.message.colour

  if not window then
    decho(colour .. "Unable to " .. verb .. " __PKGNAME__ window.\n")
    return
  end

  if (window[field] and true or false) == target then
    decho(colour .. "__PKGNAME__ window is already " .. already .. ".\n")
    return
  end

  window[method](window)

  if (window[field] and true or false) == target then
    decho(colour .. "__PKGNAME__ window " .. done .. ".\n")
    window:save()
  else
    decho(colour .. "Unable to " .. verb .. " __PKGNAME__ window.\n")
  end
end

function __PKGNAME__.show()
  changeWindowState("hidden", false, "show", "show", "shown", "visible")
end

function __PKGNAME__.hide()
  changeWindowState("hidden", true, "hide", "hide", "hidden", "hidden")
end

function __PKGNAME__.toggle()
  if __PKGNAME__.MainWindow.hidden then
    __PKGNAME__.show()
  else
    __PKGNAME__.hide()
  end
end

function __PKGNAME__.isVisible()
  return not __PKGNAME__.MainWindow.hidden
end

function __PKGNAME__.flash()
  if __PKGNAME__.MainWindow then
    __PKGNAME__.MainWindow:flash()
  end
end

function __PKGNAME__.minimize()
  changeWindowState("minimized", true, "minimize", "minimize", "minimized", "minimized")
end

function __PKGNAME__.restore()
  changeWindowState("minimized", false, "restore", "restore", "restored", "restored")
end

function __PKGNAME__.lock()
  changeWindowState("locked", true, "lockContainer", "lock", "locked", "locked")
end

function __PKGNAME__.unlock()
  changeWindowState("locked", false, "unlockContainer", "unlock", "unlocked", "unlocked")
end

function __PKGNAME__.isLocked()
  return __PKGNAME__.MainWindow.locked
end

function __PKGNAME__.save()
  __PKGNAME__.MainWindow:save()
  decho(__PKGNAME__.style.message.colour .. "__PKGNAME__ window saved.\n")
end

function __PKGNAME__.load()
  __PKGNAME__.MainWindow:load()
  decho(__PKGNAME__.style.message.colour .. "__PKGNAME__ window loaded.\n")
end

function __PKGNAME__.loadGroups()
  __PKGNAME__.groups = glu.preferences.load(nil, "__PKGNAME__.Groups.lua", {})

  __PKGNAME__.saveGroups()
end

function __PKGNAME__.saveGroups()
  glu.preferences.save(nil, "__PKGNAME__.Groups.lua", __PKGNAME__.groups)
end

--- Makes each label in the window's right click menu show its nest properly:
---
--- * [Mudlet 5.1.0-5.1.1 workaround, see the WORKAROUND block below]
---   Hiding and showing the window leaves the items of every closed submenu
---   flagged auto_hidden (Geyser.Label:show(true) stops at a hidden nest
---   parent), and show() never draws an auto_hidden label. A label displaying
---   its nest is visible, so its items' flag is stale and is cleared first.
--- * The menu is built before the tab consoles, which then draw over the items
---   that open on top of them, so the items are raised once displayed.
---
--- Wrapped once per label, since buildUi may run on a surviving window.
function __PKGNAME__.patchMenu(label)
  if not label.__PKGNAME__Patched then
    label.__PKGNAME__Patched = true

    local displayNest = label.displayNest
    function label:displayNest(...)
      -- WORKAROUND(Mudlet 5.1.0-5.1.1): remove from here...
      -- Geyser regressed in Mudlet/Mudlet#11714 and is fixed by
      -- Mudlet/Mudlet#12460. Once a release carrying that fix is the oldest
      -- Mudlet Chatter supports, delete this block, its bullet above, and the
      -- two auto_hidden specs under "patchMenu" in chatter_spec.lua.
      if not (self.hidden or self.auto_hidden) then
        for _, item in ipairs(self.nestedLabels or {}) do
          item.auto_hidden = false
        end
      end
      -- WORKAROUND(Mudlet 5.1.0-5.1.1): ...to here.

      local result = displayNest(self, ...)
      for _, item in ipairs(self.nestedLabels or {}) do
        item:raise()
      end
      return result
    end
  end

  for _, item in pairs(label.MenuLabels or {}) do
    __PKGNAME__.patchMenu(item)
  end
end

function __PKGNAME__.buildUi()
  __PKGNAME__.MainWindow = __PKGNAME__.MainWindow or Adjustable.Container:new({
    name = "__PKGNAME__.MainWindow",
    x = 0,
    y = 0,
    width = 400,
    padding = 0,
    locked = false,
    titleText = "",

    adjLabelstyle = __PKGNAME__.style.window.adjLabel,
    buttonstyle = __PKGNAME__.style.window.button,
    buttonFontSize = 10,
    buttonsize = 20,
  })
  __PKGNAME__.MainWindow:setTitle(
    "__PKGNAME__",
    __PKGNAME__.style.title.colour,
    __PKGNAME__.style.title.format
  )
  __PKGNAME__.addWidget(__PKGNAME__.MainWindow)
  __PKGNAME__.patchMenu(__PKGNAME__.MainWindow.rCLabel)
  -- The container has just restored its saved layout. Keep it out of sight
  -- while it's built, then honour whether that layout had it hidden.
  local start_hidden = __PKGNAME__.MainWindow.hidden
  __PKGNAME__.MainWindow:hide()

  -- This is the container that holds everything
  __PKGNAME__.Container = __PKGNAME__.Container or Geyser.VBox:new({
    name = "__PKGNAME__.Container",
    x = 5,
    y = 5,
    width = "100%-10",
    height = "100%-10",
  }, __PKGNAME__.MainWindow)
  __PKGNAME__.addWidget(__PKGNAME__.Container)

  -- Adding a label so we don't have wonky spaces between the tabs
  __PKGNAME__.TabBarFiller = __PKGNAME__.TabBarFiller or Geyser.Label:new({
    name = "__PKGNAME__.TabBarFiller",
    y = 0,
    x = 0,
    height = __PKGNAME__.config.metrics.tabs.height,
    width = "100%-" .. tostring(tonumber(__PKGNAME__.MainWindow.buttonsize) * 3),
    v_policy = Geyser.Fixed,
    h_policy = Geyser.Fixed,
    stylesheet = __PKGNAME__.style.header.background,
  }, __PKGNAME__.Container)
  __PKGNAME__.addWidget(__PKGNAME__.TabBarFiller)

  -- This is the header that contains all of the "tabs"
  __PKGNAME__.TabBar = __PKGNAME__.TabBar or Geyser.HBox:new({
      name = "__PKGNAME__.TabBar",
      x = 0,
      y = 0,
      width = "100%",
      height = "100%",
    },
    __PKGNAME__.TabBarFiller)
  __PKGNAME__.addWidget(__PKGNAME__.TabBar)

  -- This the label that contains all of the miniconsoles
  __PKGNAME__.Body = __PKGNAME__.Body or Geyser.Label:new({
    name = "__PKGNAME__.Body",
    stylesheet = __PKGNAME__.style.body.background,
    x = 0,
    width = "100%",
  }, __PKGNAME__.Container)
  __PKGNAME__.addWidget(__PKGNAME__.Body)

  -- Add the tabs
  __PKGNAME__.tabs = __PKGNAME__.tabs or {}

  -- Sort the categories by order
  local names = table.keys(__PKGNAME__.config.category.type) or {}
  table.sort(names, function(a, b)
    return __PKGNAME__.config.category.type[a].order < __PKGNAME__.config.category.type[b].order
  end)

  -- Create and add the tabs
  for _, name in ipairs(names) do
    local display_name = __PKGNAME__.config.category.type[name].display

    -- Create the tab
    __PKGNAME__.tabs[name] = __PKGNAME__.tabs[name] or {}
    __PKGNAME__.tabs[name].tab = __PKGNAME__.tabs[name].tab or Geyser.Button:new({
      name = "__PKGNAME__.Tabs." .. name,
      msg = display_name,
      tooltip = __PKGNAME__.config.category.type[name].tooltip,
      clickFunction = function() __PKGNAME__.click(name) end,
    }, __PKGNAME__.TabBar)
    __PKGNAME__.tabs[name].tab:echo(nil, "nocolor", nil)
    __PKGNAME__.tabs[name].tab:setFontSize(10)
    __PKGNAME__.tabs[name].tab:setStyle(__PKGNAME__.style.tabs.unselected)
    setLabelCursor("__PKGNAME__.Tabs." .. name, 13)
    __PKGNAME__.fade(__PKGNAME__.tabs[name].tab, "out", true)
    __PKGNAME__.addWidget(__PKGNAME__.tabs[name].tab)

    -- Create the console
    __PKGNAME__.tabs[name].console = __PKGNAME__.tabs[name].console or
        Geyser.MiniConsole:new({
          x = 0,
          y = 5,
          width = "100%",
          height = "100%-2",
          name = "__PKGNAME__.Tabs." .. name .. ".Console",
          autoWrap = true,
          fontName = "Ubuntu",
          fontSize = __PKGNAME__.prefs.size or 9,
        }, __PKGNAME__.Body)
    __PKGNAME__.tabs[name].console:setBackgroundImage(__PKGNAME__.style.console.background, 4)
    __PKGNAME__.addWidget(__PKGNAME__.tabs[name].console)
    __PKGNAME__.tabs[name].console:hide()
  end

  if not start_hidden then
    __PKGNAME__.MainWindow:show()
  end
  -- Show the default tab
  __PKGNAME__.click("all", true)
end

function __PKGNAME__.dismantleUi()
  for _, v in pairs(__PKGNAME__.widget or {}) do
    -- We will do this last.
    if v.name ~= "__PKGNAME__.MainWindow" then
      v:hide()
    end
  end
  __PKGNAME__.widget = nil

  if __PKGNAME__.MainWindow then
    __PKGNAME__.MainWindow:delete()
  end
end

function __PKGNAME__.command(_, input)
  if input == "" then
    echo("\n")
    ---@diagnostic disable-next-line: undefined-global
    helper.print({
      text = __PKGNAME__.help.topics.usage,
      styles = __PKGNAME__.help_styles
    })
    return
  end

  local command, subcommand, value = input:match("^(%S+)%s*(%S*)%s*(.*)$")

  if command == "add" or command == "remove" then
    local channel = subcommand:trim()
    local group = rex.match(value, "^(?:to|from)\\s*(.+)$")

    if not group or not __PKGNAME__.config.category.type[group] then
      echo("Invalid group: " .. tostring(group or value) .. "\n")
      return
    end

    if command == "add" then
      __PKGNAME__.addChannel(channel, group)
    else
      __PKGNAME__.removeChannel(channel, group)
    end
  elseif command == "list" then
    __PKGNAME__.listChannels(subcommand)
  elseif command == "mute" then
    __PKGNAME__.muteChannel(subcommand)
  elseif command == "unmute" then
    __PKGNAME__.unmuteChannel(subcommand)
  elseif command == "toggle" then
    __PKGNAME__.toggle()
  elseif command == "show" then
    __PKGNAME__.show()
  elseif command == "hide" then
    __PKGNAME__.hide()
  elseif command == "flash" then
    __PKGNAME__.flash()
  elseif command == "lock" then
    __PKGNAME__.lock()
  elseif command == "unlock" then
    __PKGNAME__.unlock()
  elseif command == "minimize" then
    __PKGNAME__.minimize()
  elseif command == "restore" then
    __PKGNAME__.restore()
  elseif command == "save" then
    __PKGNAME__.save()
  elseif command == "load" then
    __PKGNAME__.load()
  elseif command == "size" then
    __PKGNAME__.setFontSize(subcommand)
  else
    echo("Invalid command: " .. command .. "\n")
  end
end

--- Clamps a font size to the configured limits, rounding down.
function __PKGNAME__.clampFontSize(size)
  local limits = __PKGNAME__.config.font_size
  return math.floor(glu.number.clamp(size, limits.min, limits.max))
end

function __PKGNAME__.setFontSize(size)
  local font_size = tonumber(size)
  if not font_size then
    echo("Invalid font size: " .. tostring(size) .. "\n")
    return
  end

  font_size = __PKGNAME__.clampFontSize(font_size)

  for _, tab in pairs(__PKGNAME__.tabs) do
    tab.console:setFontSize(font_size)
  end
  __PKGNAME__.prefs.size = font_size
  __PKGNAME__.savePrefs()

  cecho("__PKGNAME__ font size set to <b>" .. tostring(font_size) .. "</b>.\n")
end

function __PKGNAME__.addChannel(channel, group)
  local element

  if __PKGNAME__.groups[channel] then
    element = __PKGNAME__.groups[channel]
    cecho("Channel <b>" .. channel .. "</b> already exists in group <b>" .. element.group .. "</b>.\n")
    if element.group ~= group then
      element.group = group
      cecho("Moving to <b>" .. group .. "</b>.\n")
    else
      return
    end
  else
    element = { group = group, muted = false }
  end

  __PKGNAME__.groups[channel] = element
  __PKGNAME__.saveGroups()

  cecho("Channel <b>" .. channel .. "</b> added to group <b>" .. group .. "</b>.\n")
end

function __PKGNAME__.removeChannel(channel, group)
  local element = __PKGNAME__.groups[channel]
  if not element then
    cecho("Channel <b>" .. channel .. "</b> is not in any group.\n")
    return
  end

  if element.group ~= group then
    cecho("Channel <b>" .. channel .. "</b> is not in group <b>" .. group .. "</b>.\n")
    return
  end

  __PKGNAME__.groups[channel] = nil
  __PKGNAME__.saveGroups()

  cecho("Channel <b>" .. channel .. "</b> removed from group <b>" .. group .. "</b>.\n")
end

function __PKGNAME__.muteChannel(channel)
  local element = __PKGNAME__.groups[channel]
  if not element then
    cecho("Channel <b>" .. channel .. "</b> is not in any group. You must add it to a group first.\n")
    return
  end

  if element.muted then
    cecho("Channel <b>" .. channel .. "</b> is already muted.\n")
    return
  end

  element.muted = true
  __PKGNAME__.saveGroups()

  cecho("Channel <b>" .. channel .. "</b> muted.\n")
end

function __PKGNAME__.unmuteChannel(channel)
  local element = __PKGNAME__.groups[channel]
  if not element then
    cecho("Channel <b>" .. channel .. "</b> is not in any group. You must add it to a group first.\n")
    return
  end

  if not element.muted then
    cecho("Channel <b>" .. channel .. "</b> is not muted.\n")
    return
  end

  element.muted = false
  __PKGNAME__.saveGroups()

  cecho("Channel <b>" .. channel .. "</b> unmuted.\n")
end

function __PKGNAME__.listChannels(group)
  local groups = __PKGNAME__.groups

  if not group or group == "" then
    group = "all"
  end

  if group == "all" then
    local group_names = glu.table.map(
      glu.table.values(groups),
      function(k, v) return v.group end
    )
    groups = glu.table.n_distinct(group_names)
    table.sort(groups)
  elseif __PKGNAME__.config.category.type[group] then
    groups = { group }
  else
    echo("Invalid group: " .. group .. "\n")
    return
  end

  for _, g in ipairs(groups) do
    local channels = {}
    for channel, element in pairs(__PKGNAME__.groups) do
      if element.group == g then
        glu.table.push(channels, channel)
      end
    end

    table.sort(channels, function(a, b) return a < b end)

    channels = glu.table.map(channels, function(_, v)
      if __PKGNAME__.groups[v].muted then
        return "[" .. v .. "]"
      end
      return v
    end)

    cecho("Channels in group <b>" .. g .. "</b>:\n")
    local channel_names = table.concat(channels, ", ")
    cecho("  " .. channel_names .. "\n")
  end
end

--- Returns `count` colours stepping from `from` to `to`, ending exactly on `to`.
function __PKGNAME__.fadeSteps(from, to, count)
  local steps = {}

  for i = 1, count - 1 do
    steps[i] = glu.colour.interpolate(from, to, i * 100 / count)
  end
  steps[count] = { to[1], to[2], to[3] }

  return steps
end

function __PKGNAME__.tabStyle(state, fg, bg)
  return __PKGNAME__.style.tabs[state] ..
      " color: " .. __PKGNAME__.css(fg) ..
      "; background-color: " .. __PKGNAME__.css(bg) .. ";"
end

function __PKGNAME__.fadeTimerName(widget)
  return "Fade_" .. widget.name
end

function __PKGNAME__.fade(widget, direction, immediate)
  local colours = __PKGNAME__.style.tabs.colours
  local from, to

  if direction == "in" then
    from, to = "unselected", "selected"
  elseif direction == "out" then
    from, to = "selected", "unselected"
  else
    return
  end

  local timer_name = __PKGNAME__.fadeTimerName(widget)
  deleteNamedTimer("__PKGNAME__", timer_name)

  if immediate then
    widget:setStyle(__PKGNAME__.tabStyle(to, colours.fg[to], colours.bg[to]))
    return
  end

  local fg = __PKGNAME__.fadeSteps(colours.fg[from], colours.fg[to], 20)
  local bg = __PKGNAME__.fadeSteps(colours.bg[from], colours.bg[to], 20)

  local step = 0
  registerNamedTimer("__PKGNAME__", timer_name, 0.025, function()
    step = step + 1
    widget:setStyle(__PKGNAME__.tabStyle(to, fg[step], bg[step]))
    if step >= #fg then
      deleteNamedTimer("__PKGNAME__", timer_name)
    end
  end, true)
end

function __PKGNAME__.click(tab_name, force)
  if not __PKGNAME__.tabs[tab_name] then return end

  -- Hide the current tab
  local current_tab_name = __PKGNAME__.current
  local current_tab = __PKGNAME__.tabs[current_tab_name].tab
  local current_console = __PKGNAME__.tabs[current_tab_name].console

  if current_tab_name == tab_name and not force then
    return
  end

  __PKGNAME__.fade(current_tab, "out")
  current_console:hide()

  -- Show the new tab
  local new_tab = __PKGNAME__.tabs[tab_name].tab
  __PKGNAME__.fade(new_tab, "in")

  local new_console = __PKGNAME__.tabs[tab_name].console
  new_console:show()

  -- Set the new tab
  __PKGNAME__.current = tab_name
end

-- Echo to the console
function __PKGNAME__.echo(groups, msg)
  for _, name in pairs(groups) do
    __PKGNAME__.tabs[name].console:decho(msg)

    -- Enable the scrollbar if the number of lines exceeds the height
    if __PKGNAME__.tabs[name].console:getLineCount() > __PKGNAME__.tabs[name].console:getRowCount() then
      __PKGNAME__.tabs[name].console:enableScrollBar()
    else
      __PKGNAME__.tabs[name].console:disableScrollBar()
    end
  end
end

-- Log to disk
function __PKGNAME__.log(groups, msg)
  for _, name in pairs(groups) do
    if not __PKGNAME__.history[name] then __PKGNAME__.history[name] = {} end
    glu.table.push(__PKGNAME__.history[name], msg)
  end

  table.save(__PKGNAME__.config.history_file, __PKGNAME__.history)
end

-- Event Handlers
-- Register/Deregister event handlers
function __PKGNAME__.registerEventHandlers()
  registerNamedEventHandler(
    "__PKGNAME__",
    "ReceiveComm",
    "gmcp.Comm.Channel.Text",
    function(event)
      __PKGNAME__.receiveComm(event)
    end
  )
  registerNamedEventHandler(
    "__PKGNAME__",
    "ConnectionScript",
    "sysConnectionEvent",
    __PKGNAME__.connectionScript
  )
  registerNamedEventHandler(
    "__PKGNAME__",
    "command",
    "__PKGNAME__:command",
    __PKGNAME__.command
  )
end

function __PKGNAME__.unregisterEventHandlers()
  deleteNamedEventHandler("__PKGNAME__", "ReceiveComm")
end

-- This connection handler announces to Threshold that we would like to receive
-- Comm GMCP information
function __PKGNAME__.connectionScript()
  if not resumeNamedTimer("__PKGNAME__", "ConnectionTimer") then
    registerNamedTimer("__PKGNAME__", "ConnectionTimer", 1, function()
      sendGMCP([[Core.Supports.Add ["Comm 1"] ]])
      deleteNamedTimer("__PKGNAME__", "ConnectionTimer")
    end)
  end
end

function __PKGNAME__.clearConsole(event, menu, window, startCol, startRow, endCol, endRow)
  -- Only clear consoles that belong to us
  for _, tab in pairs(__PKGNAME__.tabs or {}) do
    if tab.console and tab.console.name == window then
      clearWindow(window)
      return
    end
  end

  decho(__PKGNAME__.dtag(__PKGNAME__.config.palette.message) .. "That is not a __PKGNAME__ console.\n")
end

-- This is the uninstall routine. Cleans everything up!
function __PKGNAME__.uninstall(event, package)
  if package ~= "__PKGNAME__" then return end

  deleteAllNamedTimers("__PKGNAME__")
  deleteAllNamedEventHandlers("__PKGNAME__")
  removeMouseEvent("__PKGNAME__ Clear Console")
  __PKGNAME__.dismantleUi()
  -- Drop the cached module so a reinstall loads the Glu it ships with.
  -- (`package` is our argument here, hence _G.)
  _G.package.loaded["__PKGNAME__/vendor/Glu-single"] = nil
  cecho("<sea_green>[__PKGNAME__]<r> You have uninstalled __PKGNAME__.\n")
  __PKGNAME__ = nil
end

function __PKGNAME__.start(event, package)
  if package and package ~= "__PKGNAME__" then return end

  -- Handlers go in only once the UI exists, in the callback below, as they
  -- echo to it.
  if event == "sysInstall" then
    if package ~= "__PKGNAME__" then return end

    __PKGNAME__.first_time = true

    deleteNamedEventHandler("__PKGNAME__", "install")
  end

  local deps = glu.dependency_queue(
    __PKGNAME__.config.dependencies,
    function(status, message)
      if not status then
        if message then
          cecho("<red>" .. message .. "\n")
        else
          cecho("<red>Failed to load dependencies for __PKGNAME__.\n")
        end
        return
      end

      __PKGNAME__.loadPrefs()
      __PKGNAME__.loadGroups()
      __PKGNAME__.buildStyles()
      __PKGNAME__.buildUi()
      __PKGNAME__.registerEventHandlers()

      local _, _, connected = getConnectionInfo()
      if connected then
        __PKGNAME__.connectionScript()
      end

      if __PKGNAME__.first_time == true then
        tempTimer(0.1, function() raiseEvent("__PKGNAME__:command", "") end)
        __PKGNAME__.first_time = false
      end
    end
  )

  -- deps will be nil if all dependencies were already installed
  if deps then deps.start() end
end

-- ----------------------------------------------------------------------------
-- Help
-- ----------------------------------------------------------------------------

__PKGNAME__.help_styles = {
  h1 = "sea_green",
  h2 = "dark_sea_green",
}

__PKGNAME__.help = {
  name = "__PKGNAME__",
  topics = {
    usage = f [[
<h1><u>__PKGNAME__ v__VERSION__</u></h1>

Syntax: <h2>chatter</h2> [<h2>command</h2>]

  <h2>chatter</h2> - See this help text.

  <h2>chatter add</h2> <<h2>channel</h2>> to <<h2>group</h2>> - Add a channel to a group.
  <h2>chatter remove</h2> <<h2>channel</h2>> from <<h2>group</h2>> - Remove a channel from a group.

  <h2>chatter mute</h2> <<h2>channel</h2>> - Mute a channel.
  <h2>chatter unmute</h2> <<h2>channel</h2>> - Unmute a channel.

  <h2>chatter list</h2> <<h2>group</h2>> - List the channels in a group.
  <h2>chatter list all</h2> - List all channels and groups.

  <h2>chatter toggle</h2> - Toggle the visibility of the chatter window.
  <h2>chatter show</h2> - Show the chatter window.
  <h2>chatter hide</h2> - Hide the chatter window.
  <h2>chatter flash</h2> - Flash the chatter window.
  <h2>chatter lock</h2> - Lock the chatter window to prevent it from being changed.
  <h2>chatter unlock</h2> - Unlock the chatter window.

  <h2>chatter minimize</h2> - Minimize the chatter window.
  <h2>chatter restore</h2> - Restore the chatter window from minimized state.

  <h2>chatter save</h2> - Save the chatter window lock, visibility, and position.
  <h2>chatter load</h2> - Load the last saved chatter window lock, visibility, and position.

  <h2>chatter size</h2> <<h2>size</h2>> - Set the font size for the chatter window.
]],
  }
}

registerNamedEventHandler(
  "__PKGNAME__",
  "install",
  "sysInstall",
  __PKGNAME__.start,
  true
)

registerNamedEventHandler(
  "__PKGNAME__",
  "LoadEvent",
  "sysLoadEvent",
  function(_) __PKGNAME__.start(_, "__PKGNAME__") end
)

-- Registered here rather than once dependencies load, so an uninstall before
-- or without them still cleans up.
registerNamedEventHandler(
  "__PKGNAME__",
  "Uninstall",
  "sysUninstall",
  __PKGNAME__.uninstall
)

addMouseEvent(
  "__PKGNAME__ Clear Console",
  "__PKGNAME__:ClearConsole",
  "Clear Console",
  "Clear the entire history of this console"
)

registerNamedEventHandler(
  "__PKGNAME__",
  "ClearConsole",
  "__PKGNAME__:ClearConsole",
  __PKGNAME__.clearConsole
)
