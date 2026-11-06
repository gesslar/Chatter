describe("Chatter", function()
  local C, glu

  setup(function()
    C = Chatter
    glu = C.glu
    C.buildStyles()
  end)

  -- ========================================================================
  -- Colour formatting
  -- ========================================================================

  describe("dtag", function()
    it("should format an RGB table as a decho tag", function()
      assert.are.equal("<82,100,0>", C.dtag({ 82, 100, 0 }))
    end)
  end)

  describe("css", function()
    it("should format as hex without alpha", function()
      assert.are.equal("#526400", C.css({ 82, 100, 0 }))
    end)

    it("should format as rgba() with alpha", function()
      assert.are.equal("rgba(82,100,0,50%)", C.css({ 82, 100, 0 }, 50))
    end)

    it("should error on an invalid colour", function()
      assert.has_error(function() C.css({ 256, 0, 0 }) end)
    end)

    it("should error on an invalid colour with alpha", function()
      assert.has_error(function() C.css({ 256, 0, 0 }, 50) end)
    end)
  end)

  -- ========================================================================
  -- Styles
  -- ========================================================================

  describe("buildStyles", function()
    local palette

    setup(function()
      palette = C.config.palette
    end)

    it("should use the palette for tab backgrounds", function()
      assert.are.same(palette.accent, C.style.tabs.colours.bg.selected)
      assert.are.same(palette.tab, C.style.tabs.colours.bg.unselected)
    end)

    it("should give tab text readable contrast against its background", function()
      local c = C.style.tabs.colours
      assert.is_true(glu.colour.contrast_ratio(c.fg.selected, c.bg.selected) >= 3)
      assert.is_true(glu.colour.contrast_ratio(c.fg.unselected, c.bg.unselected) >= 3)
    end)

    it("should derive the header background from the palette", function()
      assert.are.equal("background-color: " .. C.css(palette.tab) .. ";", C.style.header.background)
    end)

    it("should derive the body background from the palette", function()
      assert.are.equal("background-color: " .. C.css(palette.base) .. ";", C.style.body.background)
    end)

    it("should colour the title and intro with the accent", function()
      assert.are.equal(C.dtag(palette.accent), C.style.title.colour)
      assert.are.equal(C.dtag(palette.accent) .. C.config.intro, C.style.intro)
    end)

    it("should colour console text with the unselected tab text colour", function()
      assert.are.equal(C.dtag(C.style.tabs.colours.fg.unselected), C.style.console.default_fg)
    end)

    it("should follow palette changes", function()
      local original = palette.accent
      palette.accent = { 200, 0, 0 }
      C.buildStyles()
      local selected = C.style.tabs.colours.bg.selected
      palette.accent = original
      C.buildStyles()

      assert.are.same({ 200, 0, 0 }, selected)
    end)
  end)

  -- ========================================================================
  -- Fading
  -- ========================================================================

  describe("fadeSteps", function()
    local from, to = { 0, 50, 0 }, { 82, 100, 0 }

    it("should return the requested number of steps", function()
      assert.are.equal(20, #C.fadeSteps(from, to, 20))
    end)

    it("should end exactly on the target colour", function()
      local steps = C.fadeSteps(from, to, 20)
      assert.are.same(to, steps[20])
    end)

    it("should pass through colours between source and target", function()
      local mid = C.fadeSteps(from, to, 20)[10]
      assert.are_not.same(from, mid)
      assert.are_not.same(to, mid)
    end)

    it("should move steadily toward the target", function()
      -- Each step is interpolated from the fixed start, so lightness never
      -- reverses and never overshoots.
      local steps = C.fadeSteps(from, to, 20)
      local last = glu.colour.rgb_to_hsl(from)[3]
      for i = 1, #steps do
        local l = glu.colour.rgb_to_hsl(steps[i])[3]
        assert.is_true(l >= last, "step " .. i .. " went backwards")
        last = l
      end
    end)

    it("should match a single interpolation at each step", function()
      local steps = C.fadeSteps(from, to, 4)
      assert.are.same(glu.colour.interpolate(from, to, 50), steps[2])
    end)
  end)

  describe("fade", function()
    local real_register, real_delete, widget, timers

    -- Fires registered timers until none are left, including any they register.
    local function drain()
      for _ = 1, 1000 do
        local _, fire = next(timers)
        if not fire then return end
        fire()
      end
      error("fade timers never finished")
    end

    before_each(function()
      real_register, real_delete = _G.registerNamedTimer, _G.deleteNamedTimer
      timers = {}
      _G.registerNamedTimer = function(_, name, _, code)
        timers[name] = code
        return true
      end
      _G.deleteNamedTimer = function(_, name)
        local had = timers[name] ~= nil
        timers[name] = nil
        return had
      end

      widget = {
        name = "Chatter.Tabs.spec",
        styles = {},
        setStyle = function(self, style) self.styles[#self.styles + 1] = style end,
      }
    end)

    after_each(function()
      _G.registerNamedTimer, _G.deleteNamedTimer = real_register, real_delete
    end)

    it("should set the target style at once when immediate", function()
      local c = C.style.tabs.colours
      C.fade(widget, "in", true)

      assert.are.equal(1, #widget.styles)
      assert.are.equal(C.tabStyle("selected", c.fg.selected, c.bg.selected), widget.styles[1])
    end)

    it("should step through the fade and finish on the target", function()
      local c = C.style.tabs.colours
      C.fade(widget, "out")
      drain()

      assert.are.equal(20, #widget.styles)
      assert.are.equal(C.tabStyle("unselected", c.fg.unselected, c.bg.unselected), widget.styles[20])
    end)

    it("should cancel a running fade when a new one starts", function()
      local c = C.style.tabs.colours
      C.fade(widget, "in")
      timers[C.fadeTimerName(widget)]()  -- one tick of "in", then it's replaced
      C.fade(widget, "out")
      drain()

      assert.are.equal(21, #widget.styles)
      assert.are.equal(C.tabStyle("unselected", c.fg.unselected, c.bg.unselected), widget.styles[21])
    end)

    it("should ignore an unknown direction", function()
      C.fade(widget, "sideways")
      assert.are.equal(0, #widget.styles)
    end)
  end)

  -- ========================================================================
  -- Font size
  -- ========================================================================

  describe("setFontSize", function()
    local real_tabs, real_savePrefs, real_size, applied

    before_each(function()
      real_tabs, real_savePrefs, real_size = C.tabs, C.savePrefs, C.prefs.size
      applied = nil
      C.tabs = { all = { console = { setFontSize = function(_, n) applied = n end } } }
      C.savePrefs = function() end
    end)

    after_each(function()
      C.tabs, C.savePrefs, C.prefs.size = real_tabs, real_savePrefs, real_size
    end)

    it("should apply a size within limits", function()
      C.setFontSize("14")
      assert.are.equal(14, applied)
      assert.are.equal(14, C.prefs.size)
    end)

    it("should clamp a size below the minimum", function()
      C.setFontSize("0")
      assert.are.equal(C.config.font_size.min, applied)
    end)

    it("should clamp a size above the maximum", function()
      C.setFontSize("500")
      assert.are.equal(C.config.font_size.max, applied)
    end)

    it("should round down a fractional size", function()
      C.setFontSize("10.7")
      assert.are.equal(10, applied)
    end)

    it("should reject a non-number", function()
      C.setFontSize("big")
      assert.is_nil(applied)
    end)
  end)

  -- ========================================================================
  -- Incoming messages
  -- ========================================================================

  describe("receiveComm", function()
    local real_gmcp, real_echo, real_groups, real_tabs, real_intro
    local sent_to, sent_text

    local function receive(channel, text)
      _G.gmcp = { Comm = { Channel = { Text = { channel = channel, text = text } } } }
      C.receiveComm()
    end

    before_each(function()
      real_gmcp, real_echo = _G.gmcp, C.echo
      real_groups, real_tabs = C.groups, C.tabs
      real_intro = C.config.enable_intro
      sent_to, sent_text = nil, nil
      C.echo = function(groups, text) sent_to, sent_text = groups, text end
      C.tabs = { all = {}, say = {}, ooc = {} }
      C.groups = {
        chat = { group = "ooc" },
        everywhere = { group = "all" },
        orphan = { group = "org" },  -- org has no tab here
        hush = { group = "say", muted = true },
      }
      C.config.enable_intro = false
    end)

    after_each(function()
      _G.gmcp, C.echo = real_gmcp, real_echo
      C.groups, C.tabs = real_groups, real_tabs
      C.config.enable_intro = real_intro
    end)

    it("should send a grouped channel to all and its group", function()
      receive("chat", "hello")
      assert.are.same({ "all", "ooc" }, sent_to)
    end)

    it("should send an ungrouped channel to all only", function()
      receive("stranger", "hello")
      assert.are.same({ "all" }, sent_to)
    end)

    it("should send a channel grouped under all to all once", function()
      receive("everywhere", "hello")
      assert.are.same({ "all" }, sent_to)
    end)

    it("should send a channel whose group has no tab to all only", function()
      receive("orphan", "hello")
      assert.are.same({ "all" }, sent_to)
    end)

    it("should send a muted channel nowhere", function()
      receive("hush", "hello")
      assert.are.same({}, sent_to)
    end)

    it("should replace line breaks with spaces", function()
      receive("chat", "one\r\ntwo")
      assert.are.equal(C.style.console.default_fg .. "one  two\n", sent_text)
    end)

    it("should colour the text with the console colour without the intro", function()
      receive("chat", "hello")
      assert.are.equal(C.style.console.default_fg .. "hello\n", sent_text)
    end)

    it("should put the intro before the same coloured text", function()
      C.config.enable_intro = true
      receive("chat", "hello")
      assert.are.equal(C.style.intro .. "<r> " .. C.style.console.default_fg .. "hello\n", sent_text)
    end)
  end)

  -- ========================================================================
  -- Listing channels
  -- ========================================================================

  describe("listChannels", function()
    local real_groups, real_echo, real_cecho, printed

    before_each(function()
      real_groups, real_echo, real_cecho = C.groups, _G.echo, _G.cecho
      printed = {}
      _G.echo = function(text) printed[#printed + 1] = text end
      _G.cecho = function(text) printed[#printed + 1] = text end
      C.groups = {
        b = { group = "say" },
        a = { group = "say", muted = true },
        c = { group = "ooc" },
        d = { group = "help" },
      }
    end)

    after_each(function()
      C.groups, _G.echo, _G.cecho = real_groups, real_echo, real_cecho
    end)

    it("should list the groups in sorted order", function()
      C.listChannels("all")
      assert.are.same({
        "Channels in group <b>help</b>:\n", "  d\n",
        "Channels in group <b>ooc</b>:\n", "  c\n",
        "Channels in group <b>say</b>:\n", "  [a], b\n",
      }, printed)
    end)

    it("should treat no group as all", function()
      C.listChannels("")
      assert.are.equal(6, #printed)
    end)

    it("should list one group", function()
      C.listChannels("say")
      assert.are.same({ "Channels in group <b>say</b>:\n", "  [a], b\n" }, printed)
    end)

    it("should report an unknown group", function()
      C.listChannels("foo")
      assert.are.same({ "Invalid group: foo\n" }, printed)
    end)
  end)

  -- ========================================================================
  -- Preferences
  -- ========================================================================

  describe("loadPrefs", function()
    local real_load, real_save, real_prefs, stored

    before_each(function()
      real_load, real_save, real_prefs = glu.preferences.load, glu.preferences.save, C.prefs
      glu.preferences.load = function() return stored end
      glu.preferences.save = function() end
    end)

    after_each(function()
      glu.preferences.load, glu.preferences.save, C.prefs = real_load, real_save, real_prefs
    end)

    it("should keep a size within limits", function()
      stored = { size = 14 }
      C.loadPrefs()
      assert.are.equal(14, C.prefs.size)
    end)

    it("should clamp a saved size above the maximum", function()
      stored = { size = 100 }
      C.loadPrefs()
      assert.are.equal(C.config.font_size.max, C.prefs.size)
    end)

    it("should clamp a saved size below the minimum", function()
      stored = { size = 2 }
      C.loadPrefs()
      assert.are.equal(C.config.font_size.min, C.prefs.size)
    end)

    it("should fall back to the default for a non-number", function()
      stored = { size = "big" }
      C.loadPrefs()
      assert.are.equal(C.config.defaults.size, C.prefs.size)
    end)
  end)

  -- ========================================================================
  -- Window menu
  -- ========================================================================

  describe("patchMenu", function()
    local raised

    local function item(name, children)
      local label = {
        name = name,
        displayNest = function(self) self.displayed = true return "shown" end,
        raise = function() raised[#raised + 1] = name end,
      }
      if children then
        label.MenuLabels, label.nestedLabels = {}, {}
        for _, child in ipairs(children) do
          label.MenuLabels[child.name] = child
          label.nestedLabels[#label.nestedLabels + 1] = child
        end
      end
      return label
    end

    before_each(function()
      raised = {}
    end)

    it("should raise the items a label displays, after displaying them", function()
      local menu = item("menu", { item("lock"), item("attach") })
      C.patchMenu(menu)

      assert.are.equal("shown", menu:displayNest())
      assert.is_true(menu.displayed)
      assert.are.same({ "lock", "attach" }, raised)
    end)

    it("should raise a submenu's items when the submenu displays", function()
      local lockstyle = item("lockstyle", { item("standard"), item("border") })
      local menu = item("menu", { item("lock"), lockstyle })
      C.patchMenu(menu)

      lockstyle:displayNest()
      assert.are.same({ "standard", "border" }, raised)
    end)

    it("should raise whatever a label holds when it displays", function()
      -- Attach rebuilds its items each time it opens.
      local attach = item("attach", { item("top") })
      C.patchMenu(item("menu", { attach }))

      attach.nestedLabels = { item("left"), item("bottom") }
      attach:displayNest()
      assert.are.same({ "left", "bottom" }, raised)
    end)

    -- WORKAROUND(Mudlet 5.1.0-5.1.1): these two specs go with the auto_hidden
    -- block in patchMenu, once Mudlet/Mudlet#12460 is released.
    it("should clear a stale auto_hidden on the items of a visible label", function()
      local standard = item("standard")
      local lockstyle = item("lockstyle", { standard })
      C.patchMenu(item("menu", { lockstyle }))

      standard.auto_hidden = true
      lockstyle:displayNest()
      assert.is_false(standard.auto_hidden)
    end)

    it("should leave auto_hidden alone while the label is itself hidden", function()
      local standard = item("standard")
      local lockstyle = item("lockstyle", { standard })
      C.patchMenu(item("menu", { lockstyle }))

      standard.auto_hidden, lockstyle.auto_hidden = true, true
      lockstyle:displayNest()
      assert.is_true(standard.auto_hidden)
    end)

    it("should wrap a label only once", function()
      local menu = item("menu", { item("lock") })
      C.patchMenu(menu)
      C.patchMenu(menu)

      menu:displayNest()
      assert.are.same({ "lock" }, raised)
    end)
  end)
end)
