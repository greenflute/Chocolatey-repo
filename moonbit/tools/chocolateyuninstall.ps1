$ErrorActionPreference = 'Stop'

# MoonBit is installed portably inside Chocolatey's package directory. Chocolatey
# removes that directory and the generated command shims during uninstall. User
# caches and credentials under ~/.moon are intentionally left untouched.
