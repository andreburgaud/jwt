import std/[base64, json, os, parseopt, strformat, strutils, terminal, times]

import command
import fmt

type
  DecodeCommand* = ref object of Command
    args*: var seq[string] = @[]

proc usage() =
  ## Displays the help (usage) for the decode command.

  writeAppInfo()
  let app = appName()
  echo()
  styledWriteLine stdout, styleBright, "Decode a JSON Web Token", resetStyle
  echo()
  printInfo "Description:"
  echo "  Parse a Base64 encoded JSON Web Token (JWT) and decode the"
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
  printField "  -h, --help         ", " Print help"
  printField "  -s, --string       ", " Take the JWT string as argument instead of file"
  printField "      --flatten      ", " Render a JSON representation of the token with raw data for each field"
  printField "      --format-dates ", " Format dates (iat, exp, nbf) into a UTC formatted time"
  echo()
  printInfo "Examples:"
  printField &"  {app} decode", " --string <token_string>  | -s=<token_string>"
  printField &"  {app} decode", " --help                   | -h"

proc splitJwt(data: string): (string, string, string) {.raises: [JwtException,
    ValueError].} =

  ## Splits a JWT in 3 parts. A JWT contains 3 parts, a header, a payload and a signature. Each part
  ## is separated by a dot ``.``.

  let fields = data.split(".")
  if fields.len != 3:
    raise newException(JwtException, &"JWT token with {fields.len} parts instead of 3 (encoded: '{data}')")

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

  colorJson jsonData

proc writeJwtStr(data: string, isFlatten: bool, isFormatDates: bool) =
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

  if isFormatDates:
    # converts dates into human readable dates
    # For example 1627425118 is converted to "2021-07-27T17:31:58-05:00"
    let payloadNode = jsonData["payload"]
    if payloadNode.hasKey("exp"):
      payloadNode["exp"] = convertTime(payloadNode["exp"])
    if payloadNode.hasKey("iat"):
      payloadNode["iat"] = convertTime(payloadNode["iat"])
    colorJson jsonData
  else:
    colorJson jsonData

proc writeJwtFile(file: string, isFlatten: bool, isFormatDates: bool) =
  ## Write a prettified JSON output to stdout, given a JWT file.

  if not fileExists(file):
    raise newException(JwtException, &"file '{file}' does not exist")

  let data = readFile file
  writeJwtStr data.strip(), isFlatten, isFormatDates

method execute*(c: DecodeCommand) =
  ## Decode command execute function.

  var files: seq[string] = @[]
  var isFlatten = false
  var isFormatDates = false
  var str = ""

  if c.args.len > 0:
    for kind, key, val in getopt(c.args,
                                 shortNoVal = {'h'},
                                 longNoVal = @["help", "flatten",
                                     "format-dates"]):
      case kind
      of cmdEnd: break
      of cmdArgument:
        files.add key
      of cmdLongOption, cmdShortOption:
        case key
        of "help", "h": usage(); return
        of "string", "s": str = val
        of "flatten": isFlatten = true
        of "format-dates": isFormatDates = true
        else:
          raise newException(JwtException,
              &"unexpected option '{key}' for command '{decodeCmd}'")

  if str.len == 0 and files.len == 0: # stdin
    str = stdin.readAll().strip()
    if str.len == 0:
      raise newException(JwtException, "JWT cannot be empty")

  if isFlatten and isFormatDates:
    raise newException(JwtException,
      &"do not use '--format-dates' with option '--flatten'")

  if str.len > 0:
    writeJwtStr str, isFlatten, isFormatDates

  # arguments are files
  let multiFiles = files.len > 1
  for file in files:
    if multiFiles:
      styledWriteLine stderr, styleBright, &"\n{file}:"
    try:
      writeJwtFile file, isFlatten, isFormatDates
    except:
      if not multiFiles:
        raise
      else:
        # If multifiles print error and continue processing other files
        printError getCurrentExceptionMsg()
