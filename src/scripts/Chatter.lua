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

-- Chatter.glu = Glu.new(Chatter.config.package_name)

--[[
Chatter.Groups = Chatter.Groups or {
  -- say
  bloodoath = "say",
  mindlink = "say",
  party = "say",
  rsay = "say",
  say = "say",
  tell = "say",
  whisper = "say",
  -- org
  clan = "org",
  guild = "org",
  lodge = "org",
  religion = "org",
  -- question
  heritage = "question",
  question = "question",
  -- ooc
  citizen = "ooc",
  court = "ooc",
  politics = "ooc",
  sports = "ooc",
  trivia = "ooc",
}
]]--

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
    text = f"{Chatter.config.intro} {Chatter.config.style.console.default_fg}{text}\n"
  else
    text = f"{Chatter.config.style.console.default_fg}{text}\n"
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
  local center = f[[ qproperty-alignment: 'AlignCenter | AlignVCenter'; ]] -- Center text
  local normal = f[[ font-weight: normal; ]] -- Normal text
  local bold = f[[ font-weight: bold; ]] -- Bold text
  local label_fg = f[[ color: rgb(175, 215, 0); ]] -- Label foreground color
  local label_bg_selected = f[[ background-color: rgb(82, 100, 0); ]] -- Label selected background color
  local label_bg_unselected = f[[ background-color: rgb(0, 50, 0); ]] -- Label unselected background color
  local default_fg = "<180,180,180>" -- Default foreground color
  local title_colour = "<82,100,0>"
  local title_format = "l13b"

  Chatter.config.style = {
    header = {
      background = f [[ {label_bg_unselected} ]],
    },
    tabs = {
      selected = f[[ {label_bg_selected} {center} {bold} {label_fg} text-decoration: underline; text-decoration-color: red; ]],
      unselected = f[[ {label_bg_unselected} {center} {normal} {label_fg}]],
    },
    console = {
      default_fg = default_fg,
      background = f[[ ]],
    },
    title = {
      colour = title_colour,
      format = title_format,
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
    width = 200,
    padding = 10,
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
  Chatter.MainWindow:setTitle(f"{Chatter.config.name}", Chatter.config.style.title.colour, Chatter.config.style.title.format)
  Chatter.addWidget(Chatter.MainWindow)
  Chatter.MainWindow:show()

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
    stylesheet = f[[ background-color: rgb(0, 50, 0); ]],
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
    Chatter.tabs[name].tab:setStyle(Chatter.config.style.tabs.unselected)
    Chatter.addWidget(Chatter.tabs[name].tab)

    -- Create the console
    Chatter.tabs[name].console = Chatter.tabs[name].console or
      Geyser.MiniConsole:new({
        x = 0, y = 5, width = "100%", height = "100%-2",
        autoWrap = true,
        fontName = "Ubuntu",
        fontSize = 9,
      }, Chatter.Body)
    Chatter.tabs[name].console:setBackgroundImage(Chatter.config.style.console.background, 4)
    Chatter.addWidget(Chatter.tabs[name].console)
    Chatter.tabs[name].console:hide()
  end

  -- Show the default tab
  tempTimer(0.1, function() Chatter.tabs["all"]["tab"]:press() end)
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
        table.insert(channels, channel)
      end
    end

    table.sort(channels, function(a, b) return a < b end)

    cecho(f"Channels in group <b>{g}</b>:\n")
    local channel_names = table.concat(channels, ", ")
    cecho(f"  {channel_names}\n")
  end
end

function Chatter.click(tab_name)
  if not Chatter.tabs[tab_name] then return end

  -- Hide the current tab
  local current_tab_name = Chatter.current
  local current_tab = Chatter.tabs[current_tab_name].tab
  local current_console = Chatter.tabs[current_tab_name].console

  current_tab:setStyle(Chatter.config.style.tabs.unselected)
  current_console:hide()

  -- Show the new tab
  local new_tab = Chatter.tabs[tab_name].tab
  new_tab:setStyle(Chatter.config.style.tabs.selected)

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
addMouseEvent("Clear Console", "ClearConsole", "Clear Console", "Clear the entire history of this console")
registerNamedEventHandler(Chatter.config.name, "ClearConsole", "Clear Console", function(...) Chatter.clearConsole(...) end)

-- This is the install routine
function Chatter.install(event, package, file)
  if package ~= Chatter.config.name then return end

  deleteNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}Install")
  Chatter.connectionScript()

  tempTimer(1, function() raiseEvent("chatter_command", "") end)
end

-- This is the uninstall routine. Cleans everything up!
function Chatter.uninstall(event, package)
  if package ~= Chatter.config.name then return end

  deleteAllNamedTimers(Chatter.config.name)
  Chatter.unregisterEventHandlers()
  deleteNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}Uninstall")
  Chatter.dismantleUi()
  Chatter.glu = nil
  Chatter = nil
  cecho("\n<red>You have uninstalled Chatter.\n")
end

function Chatter.start()
  Chatter.glu.dependency:load_dependencies(Chatter.config.package_name, Chatter.config.dependencies)
  Chatter.loadPrefs()
  Chatter.loadGroups()
  Chatter.buildStyles()
  Chatter.buildUi()
  Chatter.registerEventHandlers()
  registerNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}ConnectionScript", "sysConnectionEvent", function() Chatter.connectionScript() end)
  registerNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}Install", "sysInstallPackage", function(event,package,file) Chatter.install(event,package,file) end)
  registerNamedEventHandler(Chatter.config.name, f"{Chatter.config.prefix}Uninstall", "sysUninstallPackage", function(event,package) Chatter.uninstall(event,package) end)
  registerNamedEventHandler(Chatter.config.name, "chatter_command", "chatter_command", function(event, input) Chatter.chatterCommand(event, input) end)
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
]],
  }
}

Chatter.start()
