import base64, json, os, parseopt, strformat, strutils, terminal

const
  NAME = "JWT Command Line"
  COPYRIGHT = "Copyright (c) 2021 - Andre Burgaud"
  LICENSE = "MIT License"
  NimblePkgVersion {.strdefine.} = "Unknown"
  
type JwtException* = object of ValueError

proc appName: string =
  getAppFilename().extractFilename()

proc printInfo(msg: string) =
  styledEcho fgYellow, styleBright, msg

proc printSuccess(msg: string) =
  styledEcho fgGreen, styleBright, msg

proc printError(msg: string) =
  styledWriteLine stderr, fgRed, "Error: ", resetStyle, msg

proc printField(key: string, value: string) =
  styledWriteLine stdout, styleBright, key, resetStyle, value

proc writeInfo = 
  let width = terminalWidth()
  styledEcho fgGreen, center(&"{NAME} {NimblePkgVersion}", width - 10)
  styledEcho fgGreen, center(COPYRIGHT, width - 10)
  styledEcho fgGreen, center(LICENSE, width - 10)

proc writeVersion =
  printSuccess &"{appName()} version {NimblePkgVersion}"

proc writeHelp =
  writeInfo()
  let app = appName()
  echo()
  printInfo "Usage:"
  printField  &"  {app}", " --extract <jwt_file>"
  printField  &"  {app}", " -x <jwt_file>"
  printField  &"  {app}", " --extract --string <jwt_string>"
  printField  &"  {app}", " -x -s<jwt_string>"
  printField  &"  {app}", " -v | --version"
  printField  &"  {app}", " -h | --help"
  echo()
  printInfo "Options:"
  printField "  -x | --extract ",  ": extract JWT token into a valid JSON string"
  printField "  -s | --string  ",  ": take a JWT token string as argument"
  printField "  -h | --help    ",  ": show this screen"
  printField "  -v | --version ",  ": show version"
  echo()

proc splitJwt*(data: string): (string, string, string) =
  let fields = data.split(".")
  let lenFields = len(fields)
  if lenFields != 3:
    let msg = &"JWT token with {lenFields} parts (expected: 3) '{data}'"
    printError msg
    raise newException(JwtException, msg)
  (fields[0], fields[1], fields[2])

proc extractJwtStr(data: string) =
  try:
    let (header, payload, _) = splitJwt(data)
    let jsonHeader = decode(header)
    let jsonPayload = decode(payload)
    let jsonStr = &"[{jsonHeader},{jsonPayload}]"
    echo pretty(parseJson(jsonStr))
  except JsonParsingError:
    printError &"invalid JWT '{data}'"

  except JwtException:
    return # Continue processing other files

proc extractJwtFile(file: string) =
  if not os.fileExists(file):
    printError &"file {file} does not exist"
    return

  let data = readFile(file)
  extractJwtStr(data)

proc main* =

  # Options
  var optExtract = false

  # Arguments
  var args: seq[string] = @[]

  # Values
  var jwtStr: string

  var errorOption = false
  for kind, key, val in getopt(shortNoVal = {'h', 'v', 'x'}, 
                               longNoVal = @["help", "version", "extract"]):
    case kind
    of cmdEnd: break
    of cmdArgument:
      args.add(key)
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": writeHelp(); return
      of "version", "v": writeVersion(); return
      of "string", "s": jwtStr = val
      of "extract", "x": optExtract = true
      else: printError &"unexpected option '{key}'"; errorOption = true

  if errorOption:
    quit QuitFailure

  # Extract (option -x | --extract)
  if optExtract:

    if len(jwtStr) == 0 and len(args) == 0: # stdin
      jwtStr = stdin.readAll()
      echo()
      if len(jwtStr) == 0:
        printError "JWT cannot be empty"
        quit QuitFailure

    if len(jwtStr) > 0: # argument is a string
      extractJwtStr jwtStr.strip()
      return

    # arguments are files 
    let multiFiles = len(args) > 1
    for arg in args:
      if multiFiles:
        styledWriteLine stderr, styleBright, &"\n{arg}:"
      extractJwtFile arg

  else:
    writeHelp()
  
when isMainModule:
  main()
