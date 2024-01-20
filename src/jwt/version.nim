import std/strformat

import command
import common
import fmt
import system

type
  VersionCommand* = ref object of Command
    ## Object containing the decode options and arguments.

method execute*(c: VersionCommand) =
  ## Print the app version
  printSuccess &"{appName()} {ver}{suffix} (compiled with Nim {NimVersion})"
