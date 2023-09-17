import std/strformat

import command
import common
import fmt

type
  VersionCommand* = ref object of Command
    ## Object containing the decode options and arguments.

method execute*(c: VersionCommand, params: seq[string] = @[]) =
  ## Print the app version
  printSuccess &"{appName()} {ver}{suffix}"
