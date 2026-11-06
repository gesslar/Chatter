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
    local real_tempTimer, widget, pending_timers

    -- Runs queued timer callbacks until none are left, including any they queue.
    local function drain()
      while #pending_timers > 0 do
        table.remove(pending_timers, 1)()
      end
    end

    before_each(function()
      real_tempTimer = _G.tempTimer
      pending_timers = {}
      _G.tempTimer = function(_, code)
        pending_timers[#pending_timers + 1] = code
        return #pending_timers
      end

      widget = {
        name = "Chatter.Tabs.spec",
        styles = {},
        setStyle = function(self, style) self.styles[#self.styles + 1] = style end,
      }
    end)

    after_each(function()
      _G.tempTimer = real_tempTimer
      glu.timer.kill_multi(C.fadeTimerName(widget))
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
      pending_timers = {}  -- the "in" fade's next tick never fires
      C.fade(widget, "out")
      drain()

      assert.are.equal(20, #widget.styles)
      assert.are.equal(C.tabStyle("unselected", c.fg.unselected, c.bg.unselected), widget.styles[20])
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
end)
