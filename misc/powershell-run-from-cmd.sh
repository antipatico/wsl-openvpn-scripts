#!/usr/bin/bash
#
# Run powershell scripts from bash.
# Be careful about user input in these.
#
# Author: antipatico (github.com/antipatico)
# All wrongs reversed 2019

# Run method1
powershell.exe -Command "Write-Host \"hello wsl!\""

# Run method2
echo "Write-Host \"hello wsl!\"" | powershell.exe -Command -
