import base64, json, os, parseopt, strformat, strutils, terminal, times
import jwt/common

const
  NAME = "JWT Command Line"
  COPYRIGHT = "Copyright (c) 2021-2023 - Andre Burgaud"
  LICENSE = "MIT License"

type JwtException* = object of ValueError

proc appName: string =
  ## Retrieves the application name from the executable
  getAppFilename().extractFilename()

proc printInfo(msg: string) =
  ## Print information message with a predefined style (default yellow)
  styledEcho fgYellow, styleBright, msg

proc printSuccess(msg: string) =
  ## Print success message with a predefined style (default greed)
  styledEcho fgGreen, styleBright, msg

proc printError(msg: string) =
  ## Print error message with a predefined styled (default red) header "Error:"
  styledWriteLine stderr, fgRed, styleBright, "Error: ", resetStyle, msg

proc printField(key: string, value: string) =
  ## Print a key in bright style followed by a value in default style
  styledWriteLine stdout, styleBright, key, resetStyle, value

proc writeInfo =
  ## Write a genereric information with author, version, copyright and license
  let width = terminalWidth()
  styledEcho fgGreen, center(&"{NAME} {VERSION}", width - 10)
  styledEcho fgGreen, center(COPYRIGHT, width - 10)
  styledEcho fgGreen, center(LICENSE, width - 10)

proc writeVersion =
  ## Write the app version
  printSuccess &"{appName()} version {VERSION}"

proc writeHelp =
  ## Displays the help (usage) for the command line tool
  writeInfo()
  let app = appName()
  echo()
  printInfo "Description:"
  echo "  Parses an encoded JSON Web Token (JWT) and decode the "
  echo "  JWT Header and Payload into a valid JSON content."
  echo "  Converts dates (iat, exp) into human readable format unless "
  echo "  the option '--raw' is passed at the command line."
  echo()
  echo "  The JWT token can be passed via standard input, a file or a string."
  echo()

  printInfo "Usage:"
  printField &"  {app}", " --decode <jwt_file>                  | -d <jwt_file>"
  printField &"  {app}", " --decode --string <jwt_string>       | -d -s=<jwt_string>"
  printField &"  {app}", " --decode --raw --string <jwt_string> | -d -r -s=<jwt_string>"
  printField &"  {app}", " --version                            | -v"
  printField &"  {app}", " --help                               | -h"
  echo()
  printInfo "Commands:"
  printField "  -h | --help    ", ": show this screen"
  printField "  -v | --version ", ": show version"
  printField "  -d | --decode  ", ": decode JWT token into a valid JSON string"
  echo()
  printInfo "Options:"
  printField "  -s | --string  ", ": take a JWT token string as argument instead of file"
  printField "  -r | --raw     ", ": keep the dates (iat, exp) as numeric values (epoch time)"
  echo()

proc splitJwt*(data: string): (string, string, string) {.raises: [JwtException,
    ValueError, IOError].} =
  ## Splits a JWT in 3 parts. A JWT contains 3 parts, a header, a payload and a signature. Each part
  ## is separated by a dot ``.``

  let fields = data.split(".")
  if fields.len != 3:
    let msg = &"JWT token with {fields.len} parts instead of 3 (encoded: '{data}')"
    printError msg
    raise newException(JwtException, msg)
  (fields[0], fields[1], fields[2])

proc extractJwtStr*(data: string): string =
  ## Extracts the 3 sections of the JWT and base64-decodes them before
  ## concatenating them into a valid JSON payload: a list of 3 objects
  ## with the first object containing the JWT header, the second object
  ## representing the JWT payload and the third object, the signature.
  ## For example:
  ## .. code-block:: json
  ##   [{"alg":"HS256","typ":"JWT"},
  ##    {"sub":"1234567890","name":"John Doe","iat":1516239022},
  ##    {"sig":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}]

  let (header, payload, sig) = splitJwt data
  let jsonHeader = decode header
  let jsonPayload = decode payload
  let jsonSig = fmt"""{{"sig":"{sig}"}}"""
  &"[{jsonHeader},{jsonPayload},{jsonSig}]"

proc convertTime(intNode: JsonNode): JsonNode =
  ## Convert time from a JsonNode (epoch time) to a formatted time as JSON Date
  let value = getInt(intNode).int64
  let dt = format(initTime(value, 0), "yyyy-MM-dd'T'HH:mm:sszzz")
  return %dt

proc writeJwtStr(data: string, raw: bool) =
  ## Writes a prettyfied JSON output to stdout, given a JWT string

  var jsonData: JsonNode
  let jsonStr = extractJwtStr data

  try:
    jsonData = parseJson(jsonStr)
  except JsonParsingError:
    printError &"invalid JWT (encoded: '{data}')"
    printError &"invalid JWT (decoded: '{jsonStr}')"
    raise

  if raw:
    # -r or --raw option was passed at the command line
    echo pretty jsonData
  else:
    # converts dates into human readable dates
    # For example 1627425118 is converted to "2021-07-27T17:31:58-05:00"
    if jsonData[1].hasKey("exp"):
      jsonData[1]["exp"] = convertTime(jsonData[1]["exp"])
    if jsonData[1].hasKey("iat"):
      jsonData[1]["iat"] = convertTime(jsonData[1]["iat"])
    echo pretty jsonData

proc writeJwtFile(file: string, raw: bool) =
  ## Write a prettified JSON output to stdout, given a JWT file

  if not os.fileExists(file):
    printError &"file {file} does not exist"
    return
  let data = readFile file
  writeJwtStr data.strip(), raw

proc main* =
  ## Handles the command line argements parsing and dispatches the
  ## to the proper function based on the commands and options
  ## extracted from the command line.

  # Commands / Options
  var cmdDecode = false
  var isRaw = false

  # Arguments
  var args: seq[string] = @[]

  # Values
  var jwtStr: string

  var errorOption = false
  for kind, key, val in getopt(shortNoVal = {'h', 'v', 'd'},
                               longNoVal = @["help", "version", "decode"]):
    case kind
    of cmdEnd: break
    of cmdArgument:
      args.add key
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": writeHelp(); return
      of "version", "v": writeVersion(); return
      of "string", "s": jwtStr = val
      of "decode", "d": cmdDecode = true
      of "raw", "r": isRaw = true
      else: printError &"unexpected option '{key}'"; errorOption = true

  if errorOption:
    quit QuitFailure

  # Decode (option -d | --decode)
  if cmdDecode:

    if jwtStr.len == 0 and args.len == 0: # stdin
      jwtStr = stdin.readAll()
      echo()
      if jwtStr.len == 0:
        printError "JWT cannot be empty"
        quit QuitFailure

    if jwtStr.len > 0: # argument is a string
      try:
        writeJwtStr jwtStr.strip(), isRaw
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
        writeJwtFile arg, isRaw
      except:
        if not multiFiles:
          quit QuitFailure

  else:
    printError "No command were given. Existing commands are: "
    printField "  --decode (-d)", ": to decode a JWT Header and Payload"
    printField "  --help (-h)   ", ": to display the usage"
    printField "  --version (-v)", ": to display the version"
    echo()
    writeHelp()

when isMainModule:
  main()
