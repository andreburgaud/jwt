import std/[terminal, strformat]

template handleColor(msg: string) =
  if not isatty(stdout):
    echo msg
    return

proc printInfo*(msg: string) =
  ## Print information message with a predefined style (default yellow).
  handleColor(msg)
  styledEcho fgYellow, styleBright, msg

proc printSuccess*(msg: string) =
  ## Print success message with a predefined style (default green).
  handleColor(msg)
  styledEcho fgGreen, styleBright, msg

proc printError*(msg: string) =
  ## Print error message with a predefined styled (default red) header "Error:".
  handleColor(&"Error: {msg}")
  styledWriteLine stderr, fgRed, styleBright, "Error: ", resetStyle, msg

proc printField*(key: string, value: string) =
  ## Print a key in bright style followed by a value in default style.
  handleColor(key & value)
  styledWriteLine stdout, styleBright, key, resetStyle, value
