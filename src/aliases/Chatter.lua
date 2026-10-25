local input = matches[2] and matches[2]:trim() or ""

raiseEvent("__PKGNAME__:command", input)
