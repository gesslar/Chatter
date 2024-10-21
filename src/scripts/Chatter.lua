local script_name = "Chatter"

Chatter = Chatter or {
  config = {
    name = script_name,
    package_name = "__PKGNAME__",
    package_version = "__VERSION__",
    package_path = getMudletHomeDir() .. "/__PKGNAME__/",
    preferences_file = f [[{script_name}.Preferences.lua]],
    prefix = f"[{script_name}]:",
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
        all =  { display = "All",  tooltip = "All channels",  order = 1 },
        say =  { display = "Say",  tooltip = "Say channels",  order = 2 },
        org =  { display = "Org",  tooltip = "Organisation channels",  order = 3 },
        ooc =  { display = "OOC",  tooltip = "Out of Character channels",  order = 4 },
        help = { display = "Help", tooltip = "Help channels", order = 5 },
      },
    },
    style = {},
    intro = "<82,100,0>○",
    enable_intro = true,
    defaults = {},
  },
  current = "all",
  groups = {},
  tabs = {},
  widget = {},
  prefs = {},
}

Chatter.glu = Chatter.glu or
              require("__PKGNAME__/Glu/glu").
              new("__PKGNAME__", "Glu")

-- Channel management
function Chatter.receiveComm(event)
  local channel = gmcp.Comm.Channel.Text.channel
  local talker = gmcp.Comm.Channel.Text.talker
  local text = gmcp.Comm.Channel.Text.text
  local last_colour

  text, last_colour = ansi2decho(text)
  -- Replace line breaks with spaces, to wrap!
  text = rex.gsub(text, "[\\r\\n]", " ")

  if Chatter.config.enable_intro == true then
    text = f"{Chatter.config.intro}<r> {text}\n"
  else
    text = f"{Chatter.style.console.default_fg}{text}\n"
  end

  local group, groups = Chatter.groups[channel], {}
  if group then
    if not group.muted then
      groups = {"all", group.group}
    end
  else
    groups = {"all"}
  end

  Chatter.echo(groups, text)
end

function Chatter.addWidget(widget)
  Chatter.widget = Chatter.widget or {}

  local name = widget.name
  Chatter.widget[name] = Chatter.widget[name] or widget
end

function Chatter.buildStyles()
  -- local bg = {18, 22, 25}
  local bg = {0,50,0}
  local center = f[[ qproperty-alignment: 'AlignCenter | AlignVCenter'; ]] -- Center text
  local normal = f[[ font-weight: normal; ]] -- Normal text
  local bold = f[[ font-weight: bold; ]] -- Bold text

  local bg_selected = {82, 100, 0}
  local fg_selected = Chatter.glu.colour:lighten_or_darken(bg_selected, bg_selected, 85)
  local bg_unselected = {0, 50, 0}
  local fg_unselected = Chatter.glu.colour:lighten_or_darken(bg_unselected, bg_unselected, 85)
  local tab = {
    fg = {
      selected = fg_selected,
      unselected = fg_unselected,
    },
    bg = {
      selected = bg_selected,
      unselected = bg_unselected,
    }
  }
  local title_colour = tab.bg.selected
  local title_format = "l13b"

  Chatter.style = {
    header = {
      background = f [[ background-color: rgba({table.concat(bg, ",")}, 100%); ]],
    },
    tabs = {
      selected = f[[ {center} {bold} ]],
      unselected = f[[ {center} {bold} ]],
      colours = tab,
    },
    console = {
      default_fg = tab.fg.unselected,
      background = f[[ ]],
    },
    title = {
      colour = string.format("<%s>", table.concat(title_colour, ",")),
      format = title_format,
    },
    message = {
      colour = string.format("<%s>", table.concat(color_table.sea_green, ",")),
    }
  }
end

function Chatter.loadPrefs()
  Chatter.prefs = Chatter.glu.preferences:load_prefs(
    nil,
    Chatter.config.preferences_file,
    Chatter.config.defaults
  )

  Chatter.savePrefs()
end

function Chatter.savePrefs()
  Chatter.glu.preferences:save_prefs(
    nil,
    Chatter.config.preferences_file,
    Chatter.prefs
  )
end

function Chatter.show()
  if Chatter.MainWindow then
    if Chatter.MainWindow.hidden then
      Chatter.MainWindow:show()
      if not Chatter.MainWindow.hidden then
        decho(f"{Chatter.style.message.colour}Chatter window shown.\n")
        Chatter.MainWindow:save()
      else
        decho(f"{Chatter.style.message.colour}Unable to show Chatter window.\n")
      end
    else
      decho(f"{Chatter.style.message.colour}Chatter window is already visible.\n")
    end
  else
    decho(f"{Chatter.style.message.colour}Unable to show Chatter window.\n")
  end
end

function Chatter.hide()
  if Chatter.MainWindow then
    if not Chatter.MainWindow.hidden then
      Chatter.MainWindow:hide()
      if Chatter.MainWindow.hidden then
        decho(f"{Chatter.style.message.colour}Chatter window hidden.\n")
        Chatter.MainWindow:save()
      else
        decho(f"{Chatter.style.message.colour}Unable to hide Chatter window.\n")
      end
    else
      decho(f"{Chatter.style.message.colour}Chatter window is already hidden.\n")
    end
  else
    decho(f"{Chatter.style.message.colour}Unable to hide Chatter window.\n")
  end
end

function Chatter.toggle()
  if Chatter.MainWindow.hidden then
    Chatter.show()
  else
    Chatter.hide()
  end
end

function Chatter.isVisible()
  return not Chatter.MainWindow.hidden
end

function Chatter.flash()
  if Chatter.MainWindow then
    Chatter.MainWindow:flash()
  end
end

function Chatter.minimize()
  if Chatter.MainWindow then
    if not Chatter.MainWindow.minimized then
      Chatter.MainWindow:minimize()
      if Chatter.MainWindow.minimized then
        decho(f"{Chatter.style.message.colour}Chatter window minimized.\n")
        Chatter.MainWindow:save()
      else
        decho(f"{Chatter.style.message.colour}Unable to minimize Chatter window.\n")
      end
    else
      decho(f"{Chatter.style.message.colour}Chatter window is already minimized.\n")
    end
  else
    decho(f"{Chatter.style.message.colour}Unable to minimize Chatter window.\n")
  end
end

function Chatter.restore()
  if Chatter.MainWindow then
    if Chatter.MainWindow.minimized then
      Chatter.MainWindow:restore()
      if not Chatter.MainWindow.minimized then
        decho(f"{Chatter.style.message.colour}Chatter window restored.\n")
        Chatter.MainWindow:save()
      else
        decho(f"{Chatter.style.message.colour}Unable to restore Chatter window.\n")
      end
    else
      decho(f"{Chatter.style.message.colour}Chatter window is already restored.\n")
    end
  else
    decho(f"{Chatter.style.message.colour}Unable to restore Chatter window.\n")
  end
end

function Chatter.lock()
  if Chatter.MainWindow then
    if not Chatter.MainWindow.locked then
      Chatter.MainWindow:lockContainer()
      if Chatter.MainWindow.locked then
        decho(f"{Chatter.style.message.colour}Chatter window locked.\n")
        Chatter.MainWindow:save()
      else
        decho(f"{Chatter.style.message.colour}Unable to lock Chatter window.\n")
      end
    else
      decho(f"{Chatter.style.message.colour}Chatter window is already locked.\n")
    end
  else
    decho(f"{Chatter.style.message.colour}Unable to lock Chatter window.\n")
  end
end

function Chatter.unlock()
  if Chatter.MainWindow then
    if Chatter.MainWindow.locked then
      Chatter.MainWindow:unlockContainer()
      if not Chatter.MainWindow.locked then
        decho(f"{Chatter.style.message.colour}Chatter window unlocked.\n")
        Chatter.MainWindow:save()
      else
        decho(f"{Chatter.style.message.colour}Unable to unlock Chatter window.\n")
      end
    else
      decho(f"{Chatter.style.message.colour}Chatter window is already unlocked.\n")
    end
  else
    decho(f"{Chatter.style.message.colour}Unable to unlock Chatter window.\n")
  end
end

function Chatter.isLocked()
  return Chatter.MainWindow.locked
end

function Chatter.save()
  Chatter.MainWindow:save()
  decho(f"{Chatter.style.message.colour}Chatter window saved.\n")
end

function Chatter.load()
  Chatter.MainWindow:load()
  decho(f"{Chatter.style.message.colour}Chatter window loaded.\n")
end

function Chatter.loadGroups()
  Chatter.groups = Chatter.glu.preferences:load_prefs(nil, "Chatter.Groups.lua", {})

  Chatter.saveGroups()
end

function Chatter.saveGroups()
  Chatter.glu.preferences:save_prefs(nil, "Chatter.Groups.lua", Chatter.groups)
end

function Chatter.buildUi()
  Chatter.MainWindow = Chatter.MainWindow or Adjustable.Container:new({
    name = f"{Chatter.config.name}.MainWindow",
    x = 0, y = 0,
    width = 400,
    padding = 0,
    locked = false,
    titleText = "",

    adjLabelstyle = "background-color:rgba(18,22,25,100%); border: 1px solid rgb(18,22,25);",
    buttonstyle = [[
      QLabel{ border-radius: 7px; background-color: rgba(32,38,45,50%);}
      QLabel::hover{ background-color: rgba(30,38,45,100%);}
      ]],
    buttonFontSize = 10,
    buttonsize = 20,
  })
  Chatter.MainWindow:setTitle(f"{Chatter.config.name}", Chatter.style.title.colour, Chatter.style.title.format)
  Chatter.addWidget(Chatter.MainWindow)
  Chatter.MainWindow:hide()

  -- This is the container that holds everything
  Chatter.Container = Chatter.Container or Geyser.VBox:new({
    name = f"{Chatter.config.name}.Container",
    x = 5, y = 5,
    width = "100%-10", height = "100%-10",
  }, Chatter.MainWindow)
  Chatter.addWidget(Chatter.Container)

  -- Adding a label so we don't have wonky spaces between the tabs
  Chatter.TabBarFiller = Chatter.TabBarFiller or Geyser.Label:new({
    name = f"{Chatter.config.name}.TabBarFiller",
    y = 0, x = 0,
    height = Chatter.config.metrics.tabs.height,
    width = f"100%-{tonumber(Chatter.MainWindow.buttonsize) * 3}",
    v_policy = Geyser.Fixed, h_policy = Geyser.Fixed,
    stylesheet = Chatter.style.header.background,
  }, Chatter.Container)
  Chatter.addWidget(Chatter.TabBarFiller)

  -- This is the header that contains all of the "tabs"
  Chatter.TabBar = Chatter.TabBar or Geyser.HBox:new({
    name = f"{Chatter.config.name}.TabBar",
    x = 0, y = 0,
    width = "100%", height = "100%",
  },
  Chatter.TabBarFiller)
  Chatter.addWidget(Chatter.TabBar)

  -- This the label that contains all of the miniconsoles
  Chatter.Body = Chatter.Body or Geyser.Label:new({
    name = f"{Chatter.config.name}.Body",
    stylesheet = "background-color:rgba(18,22,25,100%);",
    x = 0,
    width = "100%",
  }, Chatter.Container)
  Chatter.addWidget(Chatter.Body)

  -- Add the tabs
  Chatter.tabs = Chatter.tabs or {}

  -- Sort the categories by order
  local names = table.keys(Chatter.config.category.type) or {}
  table.sort(names, function(a, b)
    return Chatter.config.category.type[a].order < Chatter.config.category.type[b].order
  end)

  -- Create and add the tabs
  for _, name in pairs(names) do
    local display_name = Chatter.config.category.type[name].display

    -- Create the tab
    Chatter.tabs[name] = Chatter.tabs[name] or {}
    Chatter.tabs[name].tab = Geyser.Button:new({
      name = f"{Chatter.config.name}.Tabs.{name}",
      msg = display_name,
      tooltip = Chatter.config.category.type[name].tooltip,
      clickFunction = function() Chatter.click(name) end,
    }, Chatter.TabBar)
    Chatter.tabs[name].tab:echo(nil, "nocolor", nil)
    Chatter.tabs[name].tab:setFontSize(10)
    Chatter.tabs[name].tab:setStyle(Chatter.style.tabs.unselected)
    Chatter.fade(Chatter.tabs[name].tab, "out", true)
    Chatter.addWidget(Chatter.tabs[name].tab)

    -- Create the console
    Chatter.tabs[name].console = Chatter.tabs[name].console or
      Geyser.MiniConsole:new({
        x = 0, y = 5, width = "100%", height = "100%-2",
        autoWrap = true,
        fontName = "Ubuntu",
        fontSize = 9,
      }, Chatter.Body)
    Chatter.tabs[name].console:setBackgroundImage(Chatter.style.console.background, 4)
    Chatter.addWidget(Chatter.tabs[name].console)
    Chatter.tabs[name].console:hide()
  end

  Chatter.MainWindow:show()
  -- Show the default tab
  Chatter.click("all", true)
end

function Chatter.dismantleUi()
  for _, v in ipairs(Chatter.widget) do
    if v ~= nil then
      -- We will do this last.
      if v.name ~= f"{Chatter.config.name}.MainWindow" then
        v:hide()
        v = nil
      end
    end
  end
  Chatter.widget = nil

  if Chatter.MainWindow then
    Chatter.MainWindow:hide()
    Chatter.MainWindow = nil
  end
end

function Chatter.chatterCommand(event, input)
  if input == "" then
    echo("\n")
    helper.print({
      text = Chatter.help.topics.usage,
      styles = Chatter.help_styles
    })
    return
  end

  local command, subcommand, value = input:match("^(%S+)%s*(%S*)%s*(.*)$")

  if command == "add" or command == "remove" then
    local channel = subcommand:trim()
    local group = rex.match(value, "^(?:to|from)\\s*(.+)$")

    if not group or not Chatter.config.category.type[group] then
      echo(f"Invalid group: {group}\n")
      return
    end

    if command == "add" then
      Chatter.addChannel(channel, group)
    else
      Chatter.removeChannel(channel, group)
    end
  elseif command == "list" then
    Chatter.listChannels(subcommand)
  elseif command == "mute" then
    Chatter.muteChannel(subcommand)
  elseif command == "unmute" then
    Chatter.unmuteChannel(subcommand)
  elseif command == "toggle" then
    Chatter.toggle()
  elseif command == "show" then
    Chatter.show()
  elseif command == "hide" then
    Chatter.hide()
  elseif command == "flash" then
    Chatter.flash()
  elseif command == "lock" then
    Chatter.lock()
  elseif command == "unlock" then
    Chatter.unlock()
  elseif command == "minimize" then
    Chatter.minimize()
  elseif command == "restore" then
    Chatter.restore()
  elseif command == "save" then
    Chatter.save()
  elseif command == "load" then
    Chatter.load()
  else
    echo(f"Invalid command: {command}\n")
  end
end

function Chatter.addChannel(channel, group)
  local element

  if Chatter.groups[channel] then
    element = Chatter.groups[channel]
    cecho(f"Channel <b>{channel}</b> already exists in group <b>{element.group}</b>.\n")
    if element.group ~= group then
      element.group = group
      cecho(f"Moving to <b>{group}</b>.\n")
    else
      return
    end
  else
    element = {group=group, muted=false}
  end

  Chatter.groups[channel] = element
  Chatter.saveGroups()

  cecho(f"Channel <b>{channel}</b> added to group <b>{group}</b>.\n")
end

function Chatter.removeChannel(channel, group)
  local element = Chatter.groups[channel]
  if not element then
    cecho(f"Channel <b>{channel}</b> is not in any group.\n")
    return
  end

  if element.group ~= group then
    cecho(f"Channel <b>{channel}</b> is not in group <b>{group}</b>.\n")
    return
  end

  Chatter.groups[channel] = nil
  Chatter.saveGroups()

  cecho(f"Channel <b>{channel}</b> removed from group <b>{group}</b>.\n")
end

function Chatter.muteChannel(channel)
  local element = Chatter.groups[channel]
  if not element then
    cecho(f"Channel <b>{channel}</b> is not in any group. You must add it to a group first.\n")
    return
  end

  if element.muted then
    cecho(f"Channel <b>{channel}</b> is already muted.\n")
    return
  end

  element.muted = true
  Chatter.saveGroups()

  cecho(f"Channel <b>{channel}</b> muted.\n")
end

function Chatter.unmuteChannel(channel)
  local element = Chatter.groups[channel]
  if not element then
    cecho(f"Channel <b>{channel}</b> is not in any group. You must add it to a group first.\n")
    return
  end

  if not element.muted then
    cecho(f"Channel <b>{channel}</b> is not muted.\n")
    return
  end

  element.muted = false
  Chatter.saveGroups()

  cecho(f"Channel <b>{channel}</b> unmuted.\n")
end

function Chatter.listChannels(group)
  local groups = Chatter.groups

  if not group or group == "" then
    group = "all"
  end

  if group == "all" then
    local group_names = Chatter.glu.table:map(
      Chatter.glu.table:values(groups),
      function(k, v) return v.group end
    )
    groups = Chatter.glu.table:distinct(group_names)
  else
    groups = {group}
  end

  for _, g in spairs(groups) do
    local channels = {}
    for channel, element in pairs(Chatter.groups) do
      if element.group == g then
        Chatter.glu.table:push(channels, channel)
      end
    end

    table.sort(channels, function(a, b) return a < b end)

    channels = Chatter.glu.table:map(channels, function(_, v)
      if Chatter.groups[v].muted then
        return "[" .. v .. "]"
      end
      return v
    end)

    cecho(f"Channels in group <b>{g}</b>:\n")
    local channel_names = table.concat(channels, ", ")
    cecho(f"  {channel_names}\n")
  end
end

function Chatter.fade(widget, direction, immediate)
  local tab_styles = Chatter.style.tabs
  local widget_name = widget.name

  local curr_fg, target_fg, curr_bg, target_bg

  if direction == "in" then
    curr_fg = tab_styles.colours.fg.unselected
    target_fg = tab_styles.colours.fg.selected
    curr_bg = tab_styles.colours.bg.unselected
    target_bg = tab_styles.colours.bg.selected
  elseif direction == "out" then
    curr_fg = tab_styles.colours.fg.selected
    target_fg = tab_styles.colours.fg.unselected
    curr_bg = tab_styles.colours.bg.selected
    target_bg = tab_styles.colours.bg.unselected
  else
    return
  end

  local delay = .025
  local step = immediate and 100 or 5
  local state = 0

  local timer_name = f"{Chatter.config.prefix}Fade_{widget_name}"
  if not table.index_of(getNamedTimers(Chatter.config.name), timer_name) then
    deleteNamedTimer(Chatter.config.name, timer_name)
  end

  registerNamedTimer(Chatter.config.name, timer_name, delay, function()
    state = state + step
    local style_string
    local fg_colour_string, bg_colour_string
    if state >= 100 then
      style_string = Chatter.style.tabs.selected
      fg_colour_string = "rgb(" .. table.concat(target_fg, ",") .. ")"
      bg_colour_string = "rgb(" .. table.concat(target_bg, ",") .. ")"
    else
      curr_fg = Chatter.glu.colour:interpolate(curr_fg, target_fg, state)
      curr_bg = Chatter.glu.colour:interpolate(curr_bg, target_bg, state)
      style_string = Chatter.style.tabs.unselected
      fg_colour_string = "rgb(" .. table.concat(curr_fg, ",") .. ")"
      bg_colour_string = "rgb(" .. table.concat(curr_bg, ",") .. ")"
    end

    local style = f"{style_string} color: {fg_colour_string}; background-color: {bg_colour_string};"
    widget:setStyle(style)

    if state >= 100 then
      deleteNamedTimer(Chatter.config.name, timer_name)
    end
  end, true)
end

function Chatter.click(tab_name, force)
  if not Chatter.tabs[tab_name] then return end

  -- Hide the current tab
  local current_tab_name = Chatter.current
  local current_tab = Chatter.tabs[current_tab_name].tab
  local current_console = Chatter.tabs[current_tab_name].console

  if current_tab_name == tab_name and not force then
    return
  end

  Chatter.fade(current_tab, "out")
  current_console:hide()

  -- Show the new tab
  local new_tab = Chatter.tabs[tab_name].tab
  Chatter.fade(new_tab, "in")

  local new_console = Chatter.tabs[tab_name].console
  new_console:show()

  -- Set the new tab
  Chatter.current = tab_name
end

-- Echo to the console
function Chatter.echo(groups, msg)
  for _, name in pairs(groups) do
    Chatter.tabs[name].console:decho(msg)

    -- Enable the scrollbar if the number of lines exceeds the height
    if Chatter.tabs[name].console:getLineCount() > Chatter.tabs[name].console:getRowCount() then
      Chatter.tabs[name].console:enableScrollBar()
    else
      Chatter.tabs[name].console:disableScrollBar()
    end
  end
end

-- Event Handlers
-- Register/Deregister event handlers
function Chatter.registerEventHandlers()
  registerNamedEventHandler(Chatter.config.name,
    f"{Chatter.config.prefix}ReceiveComm",
    "gmcp.Comm.Channel.Text",
    function(event)
      Chatter.receiveComm(event)
    end
  )
  registerNamedEventHandler(
    Chatter.config.name,
    f "{Chatter.config.prefix}ConnectionScript",
    "sysConnectionEvent",
    Chatter.connectionScript
  )
  registerNamedEventHandler(
    Chatter.config.name,
    f "{Chatter.config.prefix}Uninstall",
    "sysUninstall",
    Chatter.uninstall
  )
  registerNamedEventHandler(
    Chatter.config.name,
    "chatter_command",
    "chatter_command",
    Chatter.chatterCommand
  )
end

function Chatter.unregisterEventHandlers()
  deleteNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}ReceiveComm")
end

-- This connection handler announces to Threshold that we would like to receive Comm GMCP information
function Chatter.connectionScript()
  Chatter.unregisterEventHandlers()
  Chatter.registerEventHandlers()
  local prefix = Chatter.config.prefix

  if not resumeNamedTimer(Chatter.config.name, f"{prefix}ConnectionTimer") then
    registerNamedTimer(Chatter.config.name, f"{prefix}ConnectionTimer", 1, function()
      sendGMCP([[Core.Supports.Add ["Comm 1"] ]])
      deleteNamedTimer(Chatter.config.name, f"{prefix}ConnectionTimer")
    end)
  end
end

function Chatter.clearConsole(event, menu, window, startCol, startRow, endCol, endRow)
  clearWindow(window)
end
addMouseEvent(
  "Clear Console",
  "ClearConsole",
  "Clear Console",
  "Clear the entire history of this console"
)
registerNamedEventHandler(
  Chatter.config.name,
  "ClearConsole",
  "Clear Console",
  function(...) Chatter.clearConsole(...) end
)

-- This is the uninstall routine. Cleans everything up!
function Chatter.uninstall(event, package)
  if package ~= Chatter.config.name then return end

  deleteAllNamedTimers(Chatter.config.name)
  Chatter.unregisterEventHandlers()
  deleteNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}Uninstall")
  Chatter.dismantleUi()
  Chatter.glu = nil
  Chatter = nil
  cecho("<red>You have uninstalled Chatter.\n")
end

function Chatter.start(event, package)
  if package and package ~= Chatter.config.name then return end

  local host, port, connected = getConnectionInfo()

  if event == "sysInstall" then
    if package ~= Chatter.config.name then return end
    Chatter.first_time = true

    deleteNamedEventHandler(Chatter.config.name, f "{Chatter.config.prefix}Install")
    if connected then
      Chatter.connectionScript()
    end
  end

  Chatter.glu.dependency:load_dependencies(
    Chatter.config.package_name,
    Chatter.config.dependencies,
    function(status, message)
      if not status then
        if message then
          cecho(f"<red>{message}\n")
        else
          cecho(f"<red>Failed to load dependencies for {Chatter.config.package_name}\n")
        end
        return
      end

      Chatter.loadPrefs()
      Chatter.loadGroups()
      Chatter.buildStyles()
      Chatter.buildUi()
      Chatter.registerEventHandlers()

      local host, port, connected = getConnectionInfo()
      if connected then
        Chatter.connectionScript()
      end

      if Chatter.first_time == true then
        tempTimer(0.1, function() raiseEvent("chatter_command", "") end)
        Chatter.first_time = false
      end
    end
  )
end

-- ----------------------------------------------------------------------------
-- Help
-- ----------------------------------------------------------------------------

Chatter.help_styles = {
  h1 = "sea_green",
  h2 = "dark_sea_green",
}

Chatter.help = {
  name = Chatter.config.package_name,
  topics = {
    usage = f[[
<h1><u>{Chatter.config.package_name} v{Chatter.config.package_version}</u></h1>

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
]],
  }
}

registerNamedEventHandler(
  Chatter.config.name,
  f "{Chatter.config.prefix}Install",
  "sysInstall",
  Chatter.start
)

registerNamedEventHandler(
  Chatter.config.name,
  f"{Chatter.config.prefix}LoadEvent",
  "sysLoadEvent",
  Chatter.start
)
