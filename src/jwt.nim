import std/[parseopt, strformat]
import jwt/[command, decode, encode, fmt, help, version]

proc main* =
  ## Handles the command line argements parsing and dispatches the
  ## to the proper function based on the commands and options
  ## extracted from the command line.
  ## The options parsing is delegrated to each command execution implementation

  var cmd: Command

  var p = initOptParser(shortNoVal = {'h', 'v'},
                        longNoVal = @["help", "version"])
  p.next() # Only parse the first arguments for either a global option (-v, -h) or a command (decode, encode, help, version)
  case p.kind
  of cmdEnd:
    printError "No command or options given."
    HelpCommand().execute()
    quit QuitFailure
  of cmdArgument:
    case p.key
    of decodeCmd, "d": cmd = DecodeCommand(p: p)
    of encodeCmd, "e": cmd = EncodeCommand(p: p)
    of helpCmd: cmd = HelpCommand() # Global help works as a command or option (--help, -h)
    of versionCmd: cmd = VersionCommand() # Version works as a command or option (--version, -v)
    else:
      printError &"unexpected command '{p.key}'"; quit QuitFailure
  of cmdLongOption, cmdShortOption:
    case p.key
    of helpCmd, "h": cmd = HelpCommand() # Global help works as a command or option (--help, -h)
    of versionCmd, "v": cmd = VersionCommand() # Version works as a command or option (--version, -v)
    else: printError &"unexpected option '{p.key}'"; quit QuitFailure

  try:
    cmd.execute()
  except:
    printError getCurrentExceptionMsg()
    quit QuitFailure

when isMainModule:
  main()
