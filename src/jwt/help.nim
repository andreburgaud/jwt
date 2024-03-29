import std/strformat

import command
import fmt

type
  HelpCommand* = ref object of Command
    ## Object containing the decode options and arguments.

proc usage() =
  ## Displays the help (usage) for the jwt CLI

  writeAppInfo()
  let app = appName()
  printInfo "Description:"
  echo "  Manipulate (encode, or decode) JSON Web Tokens (JWT)."
  echo()
  printInfo "Usage:"
  printField &"  {app}", " [OPTIONS]"
  printField &"  {app}", " [COMMAND] [OPTIONS] [ARGS]"
  echo()
  printInfo "Options:"
  printField "  -h, --help   ", "    Print help"
  printField "  -v, --version", "    Print version info"
  echo()
  printInfo "Commands:"
  printField "  decode", "    Decode a Base64 encoded JWT into a valid JSON string"
  printField "  encode", "    Encode a JSON file or string into a Base64 encoded JWT"
  echo()
  printField &"  {app} [COMMAND] --help", " for more information on a specific command."

method execute*(c: HelpCommand) =
  ## Help command execute function.
  usage()
