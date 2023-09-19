import std/[cmdline, parseopt, strformat]
import jwt/[command, decode, encode, fmt, help, version]

proc main* =
  ## Handles the command line argements parsing and dispatches the
  ## to the proper function based on the commands and options
  ## extracted from the command line.
  ## The options parsing is delegrated to each command execution implementation

  var cmd: Command

  var p = initOptParser(commandLineParams(), shortNoVal = {'h', 'v'},
      longNoVal = @["help", "version"])
  p.next() # Only parse the first arguments for either a global option (-v, -h) or a command (decode, encode, help, version)
  case p.kind
  of parseopt.cmdEnd:
    printError "No command or options given."
    HelpCommand().execute()
    return
  of parseopt.cmdArgument:
    case p.key
    of decodeCmd, "d": cmd = DecodeCommand()
    of encodeCmd, "e": cmd = EncodeCommand()
    of helpCmd: cmd = HelpCommand() # Global help works as a command or option (--help, -h)
    of versionCmd: cmd = VersionCommand() # Version works as a command or option (--version, -v)
    else:
      printError &"unexpected command '{p.key}'"; quit QuitFailure
  of parseopt.cmdLongOption, parseopt.cmdShortOption:
    case p.key
    of helpCmd, "h": cmd = HelpCommand() # Global help works as a command or option (--help, -h)
    of versionCmd, "v": cmd = VersionCommand() # Version works as a command or option (--version, -v)
    else: printError &"unexpected option '{p.key}'"; quit QuitFailure

  try:
    cmd.execute(p.remainingArgs())
  except:
    printError getCurrentExceptionMsg()
    quit QuitFailure

when isMainModule:
  main()
