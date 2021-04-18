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
  ## Displays the help (usage) for the command line tool
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
  printInfo "Commands:"
  printField "  -x | --extract ",  ": extract JWT token into a valid JSON string"
  printField "  -h | --help    ",  ": show this screen"
  printField "  -v | --version ",  ": show version"
  echo()
  printInfo "Options:"
  printField "  -s | --string  ",  ": take a JWT token string as argument instead of file"
  echo()

proc splitJwt*(data: string): (string, string, string) {.raises: [JwtException, ValueError, IOError].} =
  ## Splits a JWT in 3 parts. A JWT contains 3 parts, a header, a payload and a signature. Each part
  ## is separated by a dot ``.``

  let fields = data.split(".")
  if fields.len != 3:
    let msg = &"JWT token with {fields.len} parts instead of 3 (encoded: '{data}')"
    printError msg
    raise newException(JwtException, msg)
  (fields[0], fields[1], fields[2])

proc extractJwtStr*(data: string): string =
  ## Extracts the 2 first parts of the JWT and base64-decodes them before
  ## concatenating them into a valid JSON payload: a list of 2 objects
  ## with the first object containing the JWT header and the second object
  ## representing the JWT payload. For example:
  ## .. code-block:: json
  ##   [{"alg":"HS256","typ":"JWT"},{"sub":"1234567890","name":"John Doe","iat":1516239022}]
  ##

  let (header, payload, _) = splitJwt data
  let jsonHeader = decode header
  let jsonPayload = decode payload
  &"[{jsonHeader},{jsonPayload}]"
 
proc writeJwtStr(data: string) =
  ## Writes a prettyfied JSON output to stdout, given a JWT string

  let jsonStr = extractJwtStr data
  try:
    echo pretty parseJson(jsonStr)
  except JsonParsingError:
    printError &"invalid JWT (encoded: '{data}')"
    printError &"invalid JWT (decoded: '{jsonStr}')"
    raise

proc writeJwtFile(file: string) =
  ## Write a prettified JSON output to stdout, given a JWT file

  if not os.fileExists(file):
    printError &"file {file} does not exist"
    return
  let data = readFile file
  writeJwtStr data.strip()

proc main* =
  ## Handles the command line argements parsing and dispatches the
  ## to the proper function based on the commands and options
  ## extracted from the command line.

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
      args.add key
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

    if jwtStr.len == 0 and args.len == 0: # stdin
      jwtStr = stdin.readAll()
      echo()
      if jwtStr.len == 0:
        printError "JWT cannot be empty"
        quit QuitFailure

    if jwtStr.len > 0: # argument is a string
      try:
        writeJwtStr jwtStr.strip()
      except JwtException:
        quit QuitFailure
      finally:
        quit QuitSuccess

    # arguments are files 
    let multiFiles = args.len > 1
    for arg in args:
      if multiFiles:
        styledWriteLine stderr, styleBright, &"\n{arg}:"
      try:
        writeJwtFile arg
      except:
        if not multiFiles:
          quit QuitFailure

  else:
    writeHelp()
  
when isMainModule:
  main()
