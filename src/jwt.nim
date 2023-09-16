import std/[parseopt, strformat, strutils, terminal]
import jwt/[command, common, encode, decode, fmt]

const
  NAME = "JWT Command Line"
  COPYRIGHT = "Copyright (c) 2021-2023 - Andre Burgaud"
  LICENSE = "MIT License"

proc writeAppInfo =
  ## Write a genereric information with author, version, copyright and license
  let width = terminalWidth()
  styledEcho fgGreen, strutils.center(&"{NAME} {VERSION}{SUFFIX}", width - 10)
  styledEcho fgGreen, strutils.center(COPYRIGHT, width - 10)
  styledEcho fgGreen, strutils.center(LICENSE, width - 10)

proc writeVersion* =
  ## Write the app version
  printSuccess &"{appName()} {VERSION}{SUFFIX}"

proc main* =
  ## Handles the command line argements parsing and dispatches the
  ## to the proper function based on the commands and options
  ## extracted from the command line.

  # Commands / Options
  var cmdEncode = false
  var cmdDecode = false
  var isRaw = false
  var isFlat = false

  # Arguments
  var args: seq[string] = @[]

  # Values
  var jwtStr: string
  var secretKey: string

  var firstArg = true
  var errorOption = false
  for kind, key, val in parseopt.getopt(shortNoVal = {'h', 'v'},
                                        longNoVal = @["help", "version"]):
    case kind
    of parseopt.cmdEnd: break
    of parseopt.cmdArgument:
      if firstArg:
        case key
        of "decode", "d": cmdDecode = true
        of "encode", "e": cmdEncode = true
        else:
          printError &"unexpected command '{key}'"; quit QuitFailure
      else:
        args.add key
    of parseopt.cmdLongOption, parseopt.cmdShortOption:
      case key
      of "help", "h":
        writeAppInfo()
        if firstArg:
          command.help()
          return
        elif cmdDecode:
          DecodeCommand().help()
          return
        elif cmdEncode:
          EncodeCommand().help()
          return
      of "version", "v":
        if firstArg:
          writeVersion()
          return
      of "string", "s": jwtStr = val
      of "key", "k": secretKey = val
      of "decode", "d": cmdDecode = true
      of "encode", "e": cmdEncode = true
      of "flatten", "f": isFlat = true
      of "raw", "r": isRaw = true
      else: printError &"unexpected option '{key}'"; errorOption = true

    firstArg = false

  if errorOption:
    quit QuitFailure

  # Command decode
  if cmdDecode:
    DecodeCommand(raw: isRaw, flatten: isFlat, str: jwtStr.strip(),
        files: args).execute()

  # Command encode
  elif cmdEncode:
    EncodeCommand(key: secretKey, str: jwtStr.strip(), files: args).execute()

  else:
    printError "No command or options given."
    echo()
    command.help()

when isMainModule:
  main()
