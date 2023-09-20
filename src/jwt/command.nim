import std/[os, strformat, strutils, terminal]
import common

type
  Command* = ref object of RootObj
  JwtException* = object of ValueError
    ## Custom exception for the jwt CLI

const
  decodeCmd* = "decode"
  encodeCmd* = "encode"
  helpCmd* = "help"
  versionCmd* = "version"

method execute*(c: Command) {.base.} =
  ## Base execute method
  raise newException(CatchableError, "Method without override")

proc writeAppInfo* =
  ## Write a genereric information with author, version, copyright and license
  let width = terminalWidth()
  styledEcho fgGreen, styleBright, center(&"{name} {ver}{suffix}", width - 10)
  styledEcho fgGreen, styleBright, center(copyright, width - 10)
  styledEcho fgGreen, styleBright, center(lic, width - 10)

proc appName*: string =
  ## Retrieves the application name from the executable
  getAppFilename().extractFilename().splitFile()[1]

