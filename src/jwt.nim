import std/[cmdline, strformat, strutils]
import jwt/[command, decode, encode, fmt, json, help, version]

proc main* =
  ## Handles the command line argements parsing and dispatches the
  ## to the proper function based on the commands and options
  ## extracted from the command line.
  ## The options parsing is delegrated to each command execution implementation

  var cmd: Command
  var params = commandLineParams()

  if params.len == 0:
    printError "No command or options given."
    quit QuitFailure

  let arg: string = params[0]
  let rest = params[1..params.high]

  case arg
  of "-h", "--help": cmd = HelpCommand()
  of "-v", "--version": cmd = VersionCommand()
  of "decode": cmd = DecodeCommand(args: rest)
  of "encode": cmd = EncodeCommand(args: rest)
  of "json": cmd = JsonCommand(args: rest)
  else:
    if arg.startsWith('-'):
      printError &"unexpected option '{arg}'"
    else:
      printError &"unexpected command '{arg}'"
    quit QuitFailure

  try:
    cmd.execute()
  except:
    printError getCurrentExceptionMsg()
    quit QuitFailure

when isMainModule:
  main()
