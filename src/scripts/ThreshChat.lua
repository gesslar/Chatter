ThreshChat = ThreshChat or {}
ThreshChat.AppName = "ThreshChat"
ThreshChat.widget = {}
ThreshChat.Categories = ThreshChat.Categories or {"all", "say", "org", "ooc", "question", }
ThreshChat.Current = ThreshChat.Current or "all"
ThreshChat.Groups = ThreshChat.Groups or {
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

-- Styles
local MainBGColour = "rgba(15, 15, 15, 1)"
local Center = f[[ qproperty-alignment: 'AlignCenter | AlignVCenter'; ]]; -- Center text
local Normal = f[[ font-weight: normal; ]]; -- Normal text
local Bold = f[[ font-weight: bold; ]]; -- Bold text
local LabelBG = f[[ background-color: {MainBGColour}; ]]

ThreshChat.Styles = {
    Tabs = {
        selected = f[[ {LabelBG} {Center} {Bold} text-decoration: underline; text-decoration-color: red; ]],
        unselected = f[[ {LabelBG} {Center} {Normal}]],
        -- selected = f[[ border-bottom: 2px solid #9a9aff; border-radius: 3px; background-color: #202020; ]],
        -- unselected = f[[ border-bottom: 2px solid #202020; border-radius: 3px; background-color: #202020; ]],
    },
    Console = {
        backgroundColor = f[[ ]],
    }
}

-- Metrics
ThreshChat.Metrics = {
    Tabs = {
        height = 25,
    }
}

-- Utility Functions
function ThreshChat:InArray(list, x)
  for _, v in pairs(list) do
    if v == x then return true end
  end
  return false
end

function ThreshChat:StripLineBreaks(x)
    local result, count = string.gsub(x, "%c+%s*", " ")
    result, count = string.gsub(result, "%s*$", "")
    display(result)
    return result
end

function ThreshChat:Capitalize(str)
    return (str:gsub("^%l", string.upper))
end

-- Channel management
function ThreshChat:GetGroups(channel)
    local result = {"all"}
    if self.Groups[channel] ~= nil then
        table.insert(result, self.Groups[channel])
    end
    return result
end

function ThreshChat:ReceiveComm(event)
    local channel = gmcp.Comm.Channel.Text.channel
    local talker = gmcp.Comm.Channel.Text.talker
    local text = gmcp.Comm.Channel.Text.text
    local last

    text, last = ansi2decho(text)
    text = self:StripLineBreaks(text)
    text = "<128,128,128>○ " .. text .. "\n"
    local groups = self:GetGroups(channel)
    self:Echo(groups, text)
    decho("<128,128,128>○ " .. text .. "\n")
    display(last)
end

function ThreshChat:addWidget(name, widget)
    if self.widget == nil then
        self.widget = {}
    end

    for name, widget in pairs(self.widget) do
        if widget ~= nil then
            return
        end
    end

    self.widget[name] = widget
end

function ThreshChat:BuildUI()
    self.MainWindow = self.MainWindow or Geyser.UserWindow:new({
        name = "ThreshChat.MainWindow",
        x = 1200,
        padding = 0,
        titleText = "ThreshChat - " .. getProfileName()
    })
    self:addWidget(self.MainWindow)
    self.MainWindow:show()

    -- This is the container that holds all of the widgets
    self.HeaderLabel = self.HeaderLabel or Geyser.Label:new({
        name = "ThreshChat.HeaderLabel",
        x = "0%", y = "0%",
        width = "100%", height = "100%"
    }, self.MainWindow)
    self:addWidget(self.HeaderLabel.name, self.HeaderLabel)

    -- This is the header that contains all of the "tabs"
    self.Header = self.Header or Geyser.HBox:new({
        name = "ThreshChat.Header",
        x = 0, y = 0,
        width = "100%", height = self.Metrics.Tabs.height
    }, self.HeaderLabel)
    self:addWidget(self.Header.name, self.Header)

    -- This a label that contains all of the miniconsoles
    self.Body = self.Body or Geyser.Label:new({
        name = "ThreshChat.Body",
        x = 0, y = self.Metrics.Tabs.height,
        width = "100%",
        height = f"100%-{self.Metrics.Tabs.height}"
    }, self.HeaderLabel)
    self:addWidget(self.Body.name, self.Body)

    -- Add the tabs
    self.Tabs = self.Tabs or {}
    for k, v in pairs(self.Categories) do
        self.Tabs[v] = self.Tabs[v] or {}
        self.Tabs[v]["tab"] = Geyser.Label:new({
            name = "ThreshChat.Tabs." .. v,
            message = self:Capitalize(v),
            stylesheet = self.Styles.Tabs.unselected,
        }, self.Header)
        self.Tabs[v]["tab"]:echo(nil, "nocolor", nil) -- This is a hack to get the label to display properly
        self.Tabs[v]["tab"]:setClickCallback("ThreshChat:Click", v)
        self:addWidget(self.Tabs[v]["tab"].name, self.Tabs[v]["tab"])

        self.Tabs[v]["console"] = self.Tabs[v]["console"] or
        Geyser.MiniConsole:new({
            x = 0, y = 0, width = "100%", height = "100%",
            autoWrap = true,
            scrollBar = true,
            fontSize = 9,
        }, self.Body)
        self.Tabs[v]["console"]:setBackgroundImage(self.Styles.Console.backgroundColor, 4)

        self:addWidget(self.Tabs[v]["console"].name, self.Tabs[v]["console"])

        self.Tabs[v]["console"]:hide()
        tempTimer(0.1, function() self:Click("all") end)
    end
end

function ThreshChat:DismantleUI()
    for k, v in pairs(self.widget) do
        if k[v] ~= nil then
            k[v]:hide()
            k[v] = nil
        end
    end
    self.widget = {}
    if self.MainWindow then
        self.MainWindow:hide()
        self.MainWindow = nil
    end
end

function ThreshChat:Click(tab)
    display(tab)
    self.Tabs[self.Current]["console"]:hide()
    self.Tabs[self.Current]["tab"]:setStyleSheet(self.Styles.Tabs.unselected)
    self.Current = tab
    self.Tabs[self.Current]["tab"]:setStyleSheet(self.Styles.Tabs.selected)
    self.Tabs[self.Current]["console"]:show()
end

function ThreshChat:Echo(groups, msg)
    for _, g in pairs(groups) do
        self.Tabs[g]["console"]:decho(msg)
    end
end

-- Event Handlers
-- Register/Deregister event handlers
function ThreshChat:RegisterEventHandlers()
    registerNamedEventHandler(self.AppName, "ThreshChat:ReceiveComm", "gmcp.Comm.Channel.Text", function(event) self:ReceiveComm(event) end)
end

function ThreshChat:UnregisterEventHandlers()
    deleteNamedEventHandler(self.AppName, "ThreshChat:ReceiveComm")
end

-- This connection handler announces to Threshold that we would like to receive Comm GMCP information
function ThreshChat:ConnectionScript()
    self:UnregisterEventHandlers()
    self:RegisterEventHandlers()
    if not resumeNamedTimer(self.AppName, "ThreshChat.ConnectionTimer") then
        registerNamedTimer(self.AppName, "ThreshChat.ConnectionTimer", 1, function()
            sendGMCP([[Core.Supports.Add ["Comm 1"] ]])
            deleteNamedTimer(self.AppName, "ThreshChat.ConnectionTimer")
        end)
    end
end

-- This is the install routine
function ThreshChat:Install(event, package, file)
    if package ~= self.AppName then return end

    deleteNamedEventHandler(self.AppName, "ThreshChat.Install")
    self:ConnectionScript()
    print("Thank you for installing ThreshChat!\nInitializing GMCP in Threshold.\n")
    tempTimer(1, function() send("gmcp reset", false) end)
end

-- This is the uninstall routine. Cleans everything up!
function ThreshChat:Uninstall(event, package)
    if package ~= self.AppName then return end

    self:UnregisterEventHandlers()
    deleteNamedEventHandler(self.AppName, "ThreshChat.Uninstall")
    self:DismantleUI()
    ThreshChat = {}
    cecho("\n<red>You have uninstalled ThreshChat.\n")
end

function ThreshChat:Start()
    self:BuildUI()
    self:RegisterEventHandlers()
    registerNamedEventHandler("ThreshChat", "ThreshChat.ConnectionScript", "sysConnectionEvent", function() self:ConnectionScript() end)
    registerNamedEventHandler("ThreshChat", "ThreshChat.Install", "sysInstallPackage", function(event,package,file) self:Install(event,package,file) end)
    registerNamedEventHandler("ThreshChat", "ThreshChat.Uninstall", "sysUninstallPackage", function(event,package) self:Uninstall(event,package) end)
end

ThreshChat:Start()
