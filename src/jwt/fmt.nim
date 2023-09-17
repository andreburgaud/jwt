import std/terminal

proc printInfo*(msg: string) =
  ## Print information message with a predefined style (default yellow).
  styledEcho fgYellow, styleBright, msg

proc printSuccess*(msg: string) =
  ## Print success message with a predefined style (default green).
  styledEcho fgGreen, styleBright, msg

proc printError*(msg: string) =
  ## Print error message with a predefined styled (default red) header "Error:".
  styledWriteLine stderr, fgRed, styleBright, "Error: ", resetStyle, msg

proc printField*(key: string, value: string) =
  ## Print a key in bright style followed by a value in default style.
  styledWriteLine stdout, styleBright, key, resetStyle, value
