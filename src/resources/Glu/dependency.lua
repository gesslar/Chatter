---@diagnostic disable-next-line: undefined-global
local mod = mod or {}
local script_name = "dependency"
function mod.new(parent)
  local instance = { parent = parent }

  --- dependency:load_dependency(pkg, dependency)
  --- Loads a dependency.
  ---@param pkg string - The package name.
  ---@param dependency table - The dependency.
  ---@return nil
  function instance:load_dependency(pkg, dependency)
    self.parent.valid:type(dependency, "table", 1, false)
    self.parent.valid:type(pkg, "string", 2, false)
    self.parent.valid:not_empty(dependency.name, 2, false)
    self.parent.valid:not_empty(dependency.url, 2, false)
    self.parent.valid:regex(dependency.url, self.parent.regex.http_url, 2, false)

    local packages = getPackages()
    if not table.index_of(packages, dependency.name) then
      cecho(f "<b>{pkg}</b> is installing a dependent package: <b>{dependency.name}</b>\n")
      installPackage(dependency.url)
    end
  end

  instance.parent.valid = instance.parent.valid or setmetatable({}, {
    __index = function(_, k) return function(...) end end
  })

  --- dependency:load_dependencies(pkg, dependencies)
  --- Loads dependencies.
  ---@param pkg string - The package name.
  ---@param dependencies table - The dependencies.
  ---@return nil
  function instance:load_dependencies(pkg, dependencies)
    for _, dependency in ipairs(dependencies) do
      self:load_dependency(pkg, dependency)
    end
  end

  return instance
end

-- Let Glu know we're here
raiseEvent("glu_module_loaded", script_name, mod)

return mod
