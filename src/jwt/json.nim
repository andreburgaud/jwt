import std/[json, os, parseopt, strformat, strutils, terminal]

import command
import fmt

type
  JsonCommand* = ref object of Command
    ## Object containing the decode options and arguments.
    args*: var seq[string] = @[]

proc usage() =
  ## Displays the help (usage) for the jwt CLI

  writeAppInfo()
  let app = appName()
  echo()
  styledWriteLine stdout, styleBright, "Pretty print JSON", resetStyle
  echo()
  printInfo "Description:"
  echo "  Pretty format a JSON file or string with syntax highlighting."
  echo()
  printInfo "Usage:"
  printField &"  {app}", " [OPTIONS]"
  printField &"  {app}", " [COMMAND] [OPTIONS] [ARGS]"
  echo()
  printInfo "Options:"
  printField "  -h, --help   ", "    Print help"
  printField "  -s, --string ", "    Take a JSON string as argument instead of a JSON file"
  echo()
  printInfo "Examples:"
  printField &"  {app} json", "<json_file>"
  printField &"  {app} json", " --string <json_string>  | -s=<json_string>"
  printField &"  {app} json", " --help                  | -h"

proc printJsonStr(str: string) =
  var jsonData: JsonNode

  try:
    jsonData = parseJson(str)
  except JsonParsingError:
    raise

  colorJson jsonData

proc printJsonFile(file: string) =
  if not fileExists(file):
    raise newException(JwtException, &"file '{file}' does not exist")

  let data = readFile file
  printJsonStr data.strip()

method execute*(c: JsonCommand) =
  var files: seq[string] = @[]
  var str = ""

  if c.args.len > 0:
    for kind, key, val in getopt(c.args,
                                 shortNoVal = {'h'},
                                 longNoVal = @["help"]):
      case kind
      of cmdEnd: break
      of cmdArgument:
        files.add key
      of cmdLongOption, cmdShortOption:
        case key
        of "help", "h": usage(); return
        of "string", "s": str = val
        else:
          raise newException(JwtException,
              &"unexpected option '{key}' for command '{jsonCmd}'")

  if str.len == 0 and files.len == 0: # stdin
    str = stdin.readAll().strip()
    if str.len == 0:
      raise newException(JwtException, "JSON data cannot be empty")

  if str.len > 0:
    printJsonStr str

  # arguments are files
  let multiFiles = files.len > 1
  for file in files:
    if multiFiles:
      styledWriteLine stderr, styleBright, &"\n{file}:"
    try:
      printJsonFile file
    except:
      if not multiFiles:
        raise
      else:
        # If multifiles print error and continue processing other files
        printError getCurrentExceptionMsg()
