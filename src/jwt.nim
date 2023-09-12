import std/parseopt as po
import base64, json, os, strformat, strutils, terminal, times
import nimcrypto
import jwt/common

const
  NAME = "JWT Command Line"
  COPYRIGHT = "Copyright (c) 2021-2023 - Andre Burgaud"
  LICENSE = "MIT License"

type JwtException* = object of ValueError

proc appName: string =
  ## Retrieves the application name from the executable
  getAppFilename().extractFilename().splitFile()[1]

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
  styledEcho fgGreen, center(&"{NAME} {VERSION}{SUFFIX}", width - 10)
  styledEcho fgGreen, center(COPYRIGHT, width - 10)
  styledEcho fgGreen, center(LICENSE, width - 10)

proc writeVersion =
  ## Write the app version
  printSuccess &"{appName()} {VERSION}{SUFFIX}"

proc writeHelp =
  ## Displays the help (usage) for the command line tool

  writeInfo()
  let app = appName()

  printInfo "Description:"
  echo "  Manipulate (encode, or decode) JSON Web Tokens (JWT)."
  echo()
  printInfo "Usage:"
  printField &"  {app}", " [OPTIONS]"
  printField &"  {app}", " [COMMAND] [OPTIONS] [ARGS]]"
  echo()
  printInfo "Options:"
  printField &"  -h, --help   ", "    Print help"
  printField &"  -v, --version", "    Print version info"
  echo()
  printInfo "Commands:"
  printField "  decode, d  ", "    Decode a b64 encoded JWT token into a valid JSON string"
  printField "  encode, e  ", "    Encode a JWT JSON file or string into a b64 encoded JWT token"
  echo()
  printField &"  {app} [COMMAND] --help", " for more information on a specific command."

proc writeEncodeHelp =
  ## Displays the help (usage) for the command line tool
  writeInfo()
  let app = appName()
  echo()
  styledWriteLine stdout, styleBright, "Encode a JSON Web Token", resetStyle
  echo()
  printInfo "Description:"
  echo "  Encode a JSON Web Token into a b64 encoded token."
  echo "  The JSON argument can be passed via standard input, file or string."
  echo()
  printInfo "Usage:"
  printField &"  {app} encode", " [OPTIONS] [ARGUMENTS]"
  echo()
  printInfo "Options:"
  printField "  -h | --help    ", " Print help"
  printField "  -k | --key     ", " Take a secret key string as argument (required)"
  printField "  -s | --string  ", " Take a JWT string as argument instead of a file"
  echo()
  printInfo "Examples:"
  printField &"  {app} encode", " --key <secret> --string <json_string>  | k=<secret> -s=<json_string>"
  printField &"  {app} encode", " --key <secret> <json_file>             | k=<secret> <json_file>"
  printField &"  {app} encode", " --help                                 | -h"

proc writeDecodeHelp =
  ## Decode Help
  writeInfo()
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

proc decodeJwtStr*(data: string): string =
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

proc encodeUrlSafe[T: byte | char](data: openArray[T]): string =
  ## b64 encode with URL safe and strip the trailing '=' signs
  encode(data, safe = true).strip(leading = false, trailing = true, chars = {'='})

# proc hmacEncoded(HashType: typedesc, toHash: string, key: string): string =
#   encodeUrlSafe(HashType.hmac(key, toHash).data)

proc sha2EncodedHmac(algo: string, key: string, data: string): string =
  case algo:
    of "HS256":
      return encodeUrlSafe(sha256.hmac(key, data).data)
    of "HS384":
      return encodeUrlSafe(sha384.hmac(key, data).data)
    of "HS512":
      return encodeUrlSafe(sha512.hmac(key, data).data)
    else:
      raise newException(JwtException, &"Found algorithm '{algo}' (only 'HS256', 'HS384' and 'HS512' are supported for now)")

proc encodeJwtStr*(data: string, key: string): string =
  ## Encode a JWT token using the HS256 algorithm and the key

  var jsonNode: JsonNode

  try:
    jsonNode = parseJson(data)
  except JsonParsingError:
    raise newException(JwtException, &"invalid JWT: '{data}'")

  let algo = jsonNode["header"]["alg"].getStr
  let encodedHeader = encodeUrlSafe($(jsonNode["header"]))
  let encodedPayload = encodeUrlSafe($(jsonNode["payload"]))
  let toHash = &"""{encodedHeader}.{encodedPayload}"""
  let encodedSignature = sha2EncodedHmac(algo, key, toHash)

  &"""{toHash}.{encodedSignature}"""

proc encodeJwtfile*(file: string, key: string) =
  if not os.fileExists(file):
    printError &"file {file} does not exist"
    return
  let data = readFile file
  echo encodeJwtStr(data, key)

proc flattenJwtStr*(data: string): string =
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
  ## Convert time from a JsonNode (epoch time) to a UTC formatted time as JSON Date
  let value = getInt(intNode).int64
  let dt = format(initTime(value, 0), "yyyy-MM-dd'T'HH:mm:sszzz")
  return %dt

proc writeFlatJwtStr(data: string) =
  ## Write a flatten Jwt

  var jsonData: JsonNode
  let jsonStr = flattenJwtStr data

  try:
    jsonData = parseJson(jsonStr)
  except JsonParsingError:
    printError &"invalid JWT (encoded: '{data}')"
    printError &"invalid JWT (decoded: '{jsonStr}')"
    raise

  echo pretty jsonData

proc writeJwtStr(data: string, raw: bool) =
  ## Writes a prettyfied JSON output to stdout, given a JWT string

  var jsonData: JsonNode
  let jsonStr = decodeJwtStr data

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
    let payloadNode = jsonData["payload"]
    if payloadNode.hasKey("exp"):
      payloadNode["exp"] = convertTime(payloadNode["exp"])
    if payloadNode.hasKey("iat"):
      payloadNode["iat"] = convertTime(payloadNode["iat"])
    echo pretty jsonData

proc writeJwtFile(file: string, flat: bool, raw: bool) =
  ## Write a prettified JSON output to stdout, given a JWT file

  if not os.fileExists(file):
    printError &"file {file} does not exist"
    return
  let data = readFile file
  if flat:
    writeFlatJwtStr data.strip()
  else:
    writeJwtStr data.strip(), raw

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
  for kind, key, val in po.getopt(shortNoVal = {'h', 'v'},
                                  longNoVal = @["help", "version"]):
    case kind
    of po.cmdEnd: break
    of po.cmdArgument:
      if firstArg:
        case key
        of "decode", "d": cmdDecode = true
        of "encode", "e": cmdEncode = true
        else:
          printError &"unexpected command '{key}'"; quit QuitFailure
      else:
        args.add key
    of po.cmdLongOption, po.cmdShortOption:
      case key
      of "help", "h":
        if firstArg:
          writeHelp()
          return
        elif cmdDecode:
          writeDecodeHelp()
          return
        elif cmdEncode:
          writeEncodeHelp()
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
        writeJwtFile arg, isFlat, isRaw
      except:
        if not multiFiles:
          quit QuitFailure

  # Command encode
  elif cmdEncode:

    ## Secret key is required
    if secretKey.len == 0:
      printError "A Secret key (option '--key') is required to encode a JWT token"
      quit QuitFailure

    if jwtStr.len == 0 and args.len == 0: # stdin
      jwtStr = stdin.readAll()
      echo()
      if jwtStr.len == 0:
        printError "JWT cannot be empty"
        quit QuitFailure

    if jwtStr.len > 0: # argument is a string
      try:
        echo encodeJwtStr(jwtStr.strip(), secretKey)
      except JwtException as e:
        printError e.msg
        quit QuitFailure
      finally:
        quit QuitSuccess

    # arguments are files
    let multiFiles = args.len > 1
    for arg in args:
      if multiFiles:
        styledWriteLine stderr, styleBright, &"\n{arg}:"
      try:
        encodeJwtFile(arg, secretKey)
      except JwtException as e:
        printError e.msg
        if not multiFiles:
          quit QuitFailure

  else:
    printError "No command or options given."
    echo()
    writeHelp()

when isMainModule:
  main()
