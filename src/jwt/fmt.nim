import std/[json, tables, terminal, strformat, strutils]

template handleColor(msg: string) =
  if not isatty(stdout):
    stdout.write msg
    return

proc printInfo*(msg: string) =
  ## Print information message with a predefined style (default yellow).
  handleColor(msg & "\p")
  styledEcho fgYellow, styleBright, msg

proc printSuccess*(msg: string) =
  ## Print success message with a predefined style (default green).
  handleColor(msg & "\p")
  styledEcho fgGreen, styleBright, msg

proc printError*(msg: string) =
  ## Print error message with a predefined styled (default red) header "Error:".
  handleColor(&"Error: {msg}\p")
  styledWriteLine stderr, fgRed, styleBright, "Error: ", resetStyle, msg

proc printField*(key: string, value: string) =
  ## Print a key in bright style followed by a value in default style.
  handleColor(key & value & "\p")
  styledWriteLine stdout, styleBright, key, resetStyle, value

# =======================
# JSON Specific functions
# =======================

proc printJsonSep(token: string) =
  handleColor(token & "\p")
  styledEcho styleBright, token

proc writeJsonSep(token: string) =
  handleColor(token)
  writeStyled token

proc writeJsonInt(token: string) =
  stdout.write token

proc writeJsonBool(token: string) =
  stdout.write token

proc writeJsonString(token: string) =
  handleColor(token)
  #writeStyled(token, {fgGreen})
  stdout.styledWrite(fgGreen, token)

proc writeJsonKey(token: string) =
  handleColor(token)
  stdout.styledWrite(styleBright, fgBlue, token)

proc writeIndent(indent: int) =
  stdout.write " ".repeat(indent)

# From nim json
proc newIndent(curr, indent: int, ml: bool): int =
  if ml: return curr + indent
  else: return indent

proc toColorJson(node: JsonNode, indent = 2, ml = true, lstArr = false,
    currIndent = 0) =
  ## Modification of toPretty function https://github.com/nim-lang/Nim/blob/version-2-0/lib/pure/json.nim
  case node.kind
  of JObject:
    if lstArr:
      writeIndent(currIndent)
    if node.fields.len > 0:
      printJsonSep "{"
      var i = 0
      for key, val in node.fields.pairs:
        if i > 0:
          printJsonSep ","
        inc i
        # Need to indent more than {
        writeIndent(newIndent(currIndent, indent, ml))
        writeJsonKey(escapeJson(key))
        writeJsonSep(": ")
        toColorJson(val, indent, ml, false, newIndent(currIndent, indent, ml))
      echo()
      writeIndent(currIndent)
      writeJsonSep("}")
    else:
      writeJsonSep("{}")
  of JString:
    if lstArr:
      writeIndent(currIndent)
    #toUgly(result, node)
    writeJsonString(&"\"{node.str}\"")
  of JInt:
    if lstArr:
      writeIndent(currIndent)
    writeJsonInt(&"{node.num}")
  of JFloat:
    if lstArr:
      writeIndent(currIndent)
    writeJsonInt(&"{node.fnum}")
  of JBool:
    if lstArr:
      writeIndent(currIndent)
    if node.bval:
      writeJsonBool "true"
    else:
      writeJsonBool "false"
  of JArray:
    if lstArr:
      writeIndent(currIndent)
    if len(node.elems) != 0:
      printJsonSep("[")
      for i in 0..len(node.elems)-1:
        if i > 0:
          printJsonSep(",")
        toColorJson(node.elems[i], indent, ml, true, newIndent(currIndent,
            indent, ml))
      echo()
      writeIndent(currIndent)
      writeJsonSep("]")
    else:
      writeJsonSep("[]")
  of JNull:
    if lstArr:
      writeIndent(currIndent)
    stdout.write "null"

proc colorJson*(node: JsonNode) =
  toColorJson(node)
  echo()
