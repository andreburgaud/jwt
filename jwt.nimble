# Package

version       = "0.1.0"
author        = "Andre"
description   = "JWT Command Line"
license       = "MIT"
srcDir        = "src"
bin           = @["jwt"]


# Dependencies
requires "nim >= 1.4.6"

# Tasks
task test, "Run the test suite":
    exec "nim c -r tests/tester"