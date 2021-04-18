import strformat

# Package

version       = "0.2.0"
author        = "Andre"
description   = "JWT Command Line"
license       = "MIT"
srcDir        = "src"
bin           = @["jwt"]

let distDir = "dist"
let testsDir = "tests"
let relDir = "bin/release"
let buildDir = "bin/debug"

# Dependencies
requires "nim >= 1.4.6"

# Tasks
task test, "Run the test suite":
    exec &"nim c -r {testsDir}/tester"

task dev, "Build for development":
    exec &"nim c --colors:on -o:{buildDir}/jwt {srcDir}/jwt.nim"

task release, "Build for prod":
    exec "nimble test"
    exec "nimble clean"
    exec &"nim c --d:release --opt:size -o:{relDir}/jwt {srcDir}/jwt.nim"
    exec &"strip {relDir}/jwt"
    exec &"upx {relDir}/jwt"

task clean, "Delete generated files":
    exec "rm -rf bin dist"

task dist, "Create distribution":
    exec "nimble release"
    if not existsDir distDir:
        mkDir distDir
    withDir relDir:
        exec &"zip jwt_{version}_macosx.zip jwt"
    mvFile &"{relDir}/jwt_{version}_macosx.zip", &"{distDir}/jwt_{version}_macosx.zip"
