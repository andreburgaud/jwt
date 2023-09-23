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

proc indent(s: var string, i: int) =
  s.add(spaces(i))

proc newIndent(curr, indent: int, ml: bool): int =
  if ml: return curr + indent
  else: return indent

proc nl(s: var string, ml: bool) =
  s.add(if ml: "\n" else: " ")

proc toColorJson(result: var string, node: JsonNode, indent = 2, ml = true,
              lstArr = false, currIndent = 0) =
  ## Modification of function toPretty https://github.com/nim-lang/Nim/blob/version-2-0/lib/pure/json.nim
  case node.kind
  of JObject:
    if lstArr:
      result.indent(currIndent) # Indentation
      writeIndent(currIndent)
    if node.fields.len > 0:
      result.add("{")
      result.nl(ml) # New line
      printJsonSep "{"
      var i = 0
      for key, val in node.fields.pairs:
        if i > 0:
          result.add(",")
          result.nl(ml) # New Line
          printJsonSep ","
        inc i
        # Need to indent more than {
        result.indent(newIndent(currIndent, indent, ml))
        writeIndent(newIndent(currIndent, indent, ml))
        escapeJson(key, result)
        writeJsonKey(escapeJson(key))
        result.add(": ")
        writeJsonSep(": ")
        toColorJson(result, val, indent, ml, false,
                 newIndent(currIndent, indent, ml))
      result.nl(ml)
      echo()
      result.indent(currIndent) # indent the same as {
      writeIndent(currIndent)
      result.add("}")
      writeJsonSep("}")
    else:
      result.add("{}")
      writeJsonSep("{}")
  of JString:
    if lstArr:
      result.indent(currIndent)
      writeIndent(currIndent)
    toUgly(result, node)
    writeJsonString(&"\"{node.str}\"")
  of JInt:
    if lstArr:
      result.indent(currIndent)
      writeIndent(currIndent)
    result.addInt(node.num)
    writeJsonInt(&"{node.num}")
  of JFloat:
    if lstArr:
      result.indent(currIndent)
      writeIndent(currIndent)
    result.addFloat(node.fnum)
  of JBool:
    if lstArr:
      result.indent(currIndent)
      writeIndent(currIndent)
    result.add(if node.bval: "true" else: "false")
    if node.bval:
      writeJsonBool "true"
    else:
      writeJsonBool "false"
  of JArray:
    if lstArr:
      result.indent(currIndent)
      writeIndent(currIndent)
    if len(node.elems) != 0:
      result.add("[")
      result.nl(ml)
      printJsonSep("[")
      for i in 0..len(node.elems)-1:
        if i > 0:
          result.add(",")
          result.nl(ml) # New Line
          printJsonSep(",")
        toColorJson(result, node.elems[i], indent, ml,
            true, newIndent(currIndent, indent, ml))
      result.nl(ml)
      echo()
      result.indent(currIndent)
      writeIndent(currIndent)
      result.add("]")
      writeJsonSep("]")
    else:
      result.add("[]")
      writeJsonSep("[]")
  of JNull:
    if lstArr:
      result.indent(currIndent)
      writeIndent(currIndent)
    result.add("null")
    stdout.write "null"

proc colorJson*(node: JsonNode) =
  var res = ""
  toColorJson(res, node)
  echo()
