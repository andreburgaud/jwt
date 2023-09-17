import std/[base64, json, os, parseopt, strformat, strutils, terminal, times]

import command
import fmt

type
  DecodeCommand* = ref object of Command

proc usage() =
  ## Displays the help (usage) for the decode command.

  writeAppInfo()
  let app = appName()
  echo()
  styledWriteLine stdout, styleBright, "Decode a JSON Web Token", resetStyle
  echo()
  printInfo "Description:"
  echo "  Parse a b64 encoded JSON Web Token (JWT) and decode the"
  echo "  JWT Header and Payload into a valid JSON content."
  echo "  Convert dates (iat, exp) into human readable format,"
  echo "  unless the option '--raw' is passed at the command line."
  echo "  The encoded JWT can be passed via standard input, file"
  echo "  or string."
  echo()
  printInfo "Usage:"
  printField &"  {app} decode", " [OPTIONS] [ARGUMENTS]"
  echo()
  printInfo "Options:"
  printField "  -h | --help    ", " Print help"
  printField "  -s | --string  ", " Take the JWT string as argument instead of file"
  printField "  -f | --flatten ", " Render a JSON representation of the token with raw data for each field"
  printField "  -r | --raw     ", " Keep the dates (iat, exp) as numeric values"
  echo()
  printInfo "Examples:"
  printField &"  {app} decode", " --string <token_string>  | -s=<token_string>"
  printField &"  {app} decode", " --help                   | -h"

proc splitJwt(data: string): (string, string, string) {.raises: [JwtException,
    ValueError, IOError].} =
  ## Splits a JWT in 3 parts. A JWT contains 3 parts, a header, a payload and a signature. Each part
  ## is separated by a dot ``.``.

  let fields = data.split(".")
  if fields.len != 3:
    let msg = &"JWT token with {fields.len} parts instead of 3 (encoded: '{data}')"
    printError msg
    raise newException(JwtException, msg)
  (fields[0], fields[1], fields[2])

proc decodeJwtStr(data: string): string =
  ## Extracts the 3 sections of the JWT and base64-decodes them before
  ## concatenating them into a valid JSON payload: a list of 3 objects
  ## with the first object containing the JWT header, the second object
  ## representing the JWT payload and the third object, the signature.
  ## For example:
  ## .. code-block:: json
  ##   [{"alg":"HS256","typ":"JWT"},
  ##    {"sub":"1234567890","name":"John Doe","iat":1516239022},
  ##    {"signature":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}]

  let (header, payload, signature) = splitJwt data
  let jsonHeader = decode header
  let jsonPayload = decode payload
  &"""{{"header":{jsonHeader},"payload":{jsonPayload},"signature":"{signature}"}}"""

proc flattenJwtStr(data: string): string =
  ## Extracts the 3 sections of the JWT and concatenating them into a valid
  ## JSON payload: a object with 3 properties, with the first property
  ## containing the encoded JWT header, the second property
  ## representing the JWT payload and the third property, the signature.
  ## For example:
  ## .. code-block:: json
  ## {"header": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
  ##  "payload": "eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ",
  ##  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}]

  let (header, payload, signature) = splitJwt data
  &"""{{"header":"{header}","payload":"{payload}","signature":"{signature}"}}"""

proc convertTime(intNode: JsonNode): JsonNode =
  ## Convert time from a JsonNode (epoch time) to a UTC formatted time as JSON Date.

  let value = getInt(intNode).int64
  let dt = format(initTime(value, 0), "yyyy-MM-dd'T'HH:mm:sszzz")
  return %dt

proc writeFlattenJwtStr(data: string) =
  ## Write a flatten JWT.

  var jsonData: JsonNode
  let jsonStr = flattenJwtStr data

  try:
    jsonData = parseJson(jsonStr)
  except JsonParsingError:
    printError &"invalid JWT (encoded: '{data}')"
    printError &"invalid JWT (decoded: '{jsonStr}')"
    raise

  echo pretty jsonData

proc writeJwtStr(data: string, isFlatten: bool, isRaw: bool) =
  ## Writes a prettyfied JSON output to stdout, given a JWT string.

  if isFlatten:
    writeFlattenJwtStr data
    return

  var jsonData: JsonNode
  let jsonStr = decodeJwtStr data

  try:
    jsonData = parseJson(jsonStr)
  except JsonParsingError:
    printError &"invalid JWT (encoded: '{data}')"
    printError &"invalid JWT (decoded: '{jsonStr}')"
    raise

  if isRaw:
    # -r or --raw option was passed at the command line
    echo pretty jsonData
  else:
    # converts dates into human readable dates
    # For example 1627425118 is converted to "2021-07-27T17:31:58-05:00"
    let payloadNode = jsonData["payload"]
    if payloadNode.hasKey("exp"):
      payloadNode["exp"] = convertTime(payloadNode["exp"])
    if payloadNode.hasKey("iat"):
      payloadNode["iat"] = convertTime(payloadNode["iat"])
    echo pretty jsonData

proc writeJwtFile(file: string, isFlatten: bool, isRaw: bool) =
  ## Write a prettified JSON output to stdout, given a JWT file.

  if not fileExists(file):
    printError &"file {file} does not exist"
    return
  let data = readFile file
  writeJwtStr data.strip(), isFlatten, isRaw

method execute*(c: DecodeCommand, params: seq[string]) =
  ## Decode command execute function.
  var files: seq[string] = @[]
  var isFlatten = false
  var isRaw = false
  var str = ""
  var errorOption = false

  for kind, key, val in getopt(params,
                               shortNoVal = {'h', 'r', 'f'},
                               longNoVal = @["help", "raw", "flatten"]):
    case kind
    of parseopt.cmdEnd: break
    of parseopt.cmdArgument: files.add key
    of parseopt.cmdLongOption, parseopt.cmdShortOption:
      case key
      of "help", "h": usage(); return
      of "string", "s": str = val
      of "flatten", "f": isFlatten = true
      of "raw", "r": isRaw = true
      else: printError &"unexpected option '{key}'"; errorOption = true

  if str.len == 0 and files.len == 0: # stdin
    str = stdin.readAll()
    echo()
    if str.len == 0:
      printError "JWT cannot be empty"
      quit QuitFailure

  if str.len > 0:
    try:
      writeJwtStr str, isFlatten, isRaw
    except JwtException:
      quit QuitFailure
    finally:
      quit QuitSuccess

  # arguments are files
  let multiFiles = files.len > 1
  for file in files:
    if multiFiles:
      styledWriteLine stderr, styleBright, &"\n{file}:"
    try:
      writeJwtFile file, isFlatten, isRaw
    except:
      if not multiFiles:
        quit QuitFailure
