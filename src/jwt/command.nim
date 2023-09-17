import std/[os, strformat]
import fmt

type
  Command* = ref object of RootObj
    ## Abstract base class for a command

  JwtException* = object of ValueError
    ## Custom exception for the jwt CLI

proc appName*: string =
  ## Retrieves the application name from the executable
  getAppFilename().extractFilename().splitFile()[1]

method execute*(c: Command) {.base.} =
  ## Base execute method
  raise newException(CatchableError, "Method without override")

proc help* =
  ## Displays the help (usage) for the jwt CLI
  let app = appName()

  printInfo "Description:"
  echo "  Manipulate (encode, or decode) JSON Web Tokens (JWT)."
  echo()
  printInfo "Usage:"
  printField &"  {app}", " [OPTIONS]"
  printField &"  {app}", " [COMMAND] [OPTIONS] [ARGS]"
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

