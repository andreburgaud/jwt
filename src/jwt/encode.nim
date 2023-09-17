import std/[base64, json, os, strutils, strformat, terminal]

import nimcrypto

import fmt
import command

type
  EncodeCommand* = ref object of Command
    ## Object containing the decode options and arguments.

    key*: string
      ## Secret key used to create the signature of the token.
    str*: string
      ## JSON representation of the JWT as a string.
    files*: seq[string]
      ## An array of JWT file (JSON format).

proc help*(c: EncodeCommand) =
  ## Displays the help (usage) for the encode command.

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

proc encodeUrlSafe[T: byte | char](data: openArray[T]): string =
  ## b64 encode with URL safe and strip the trailing '=' signs.
  encode(data, safe = true).strip(leading = false, trailing = true, chars = {'='})

proc sha2EncodedHmac(algo: string, key: string, data: string): string =
  ## Create the signature of the JWT based on the provided algorithm and key.

  case algo:
    of "HS256":
      return encodeUrlSafe(sha256.hmac(key, data).data)
    of "HS384":
      return encodeUrlSafe(sha384.hmac(key, data).data)
    of "HS512":
      return encodeUrlSafe(sha512.hmac(key, data).data)
    else:
      raise newException(JwtException, &"Found algorithm '{algo}' (only 'HS256', 'HS384' and 'HS512' are supported for now)")

proc encodeJwtStr(data: string, key: string): string =
  ## Encode a JWT token using the HS256 algorithm and a key.

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
  ## Encode a JSON file into a JSON Web Token (base64 encoded).
  ## The decoded JSON file should have the following format:
  ## {
  ## "header": {
  ##   "alg": "HS256",
  ##   "typ": "JWT"
  ## },
  ## "payload": {
  ##   "sub": "1234567890",
  ##   "name": "John Doe",
  ##   "iat": 1516239022
  ## },
  ## "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  ## }

  if not os.fileExists(file):
    printError &"file {file} does not exist"
    return
  let data = readFile file
  echo encodeJwtStr(data, key)

method execute*(c: EncodeCommand) =
  ## Encode command execute function.

  # Secret key is required
  if c.key.len == 0:
    printError "A Secret key (option '--key') is required to encode a JWT token"
    quit QuitFailure

  if c.str.len == 0 and c.files.len == 0: # stdin
    c.str = stdin.readAll()
    echo()
    if c.str.len == 0:
      printError "JWT cannot be empty"
      quit QuitFailure

  if c.str.len > 0:
    try:
      echo encodeJwtStr(c.str, c.key)
    except JwtException as e:
      printError e.msg
      quit QuitFailure
    finally:
      quit QuitSuccess

  # arguments are one or more files
  let multiFiles = c.files.len > 1
  for file in c.files:
    if multiFiles:
      styledWriteLine stderr, styleBright, &"\n{file}:"
    try:
      encodeJwtFile(file, c.key)
    except JwtException as e:
      printError e.msg
    if not multiFiles:
      quit QuitFailure
