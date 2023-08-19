import strformat
import src/jwt/common

# Package
version = VERSION
author = "Andre"
description = "JWT Command Line"
license = "MIT"
srcDir = "src"
bin = @["jwt"]

let app = "jwt"
let distDir = "dist"
let testsDir = "tests"
let relDir = "bin/release"
let buildDir = "bin/debug"

# Dependencies
requires "nim >= 2.0.0"

# Tasks
task test, "Run the test suite":
    exec &"nim c -r {testsDir}/tester"

task debug, "Build for development":
    exec &"nim c --colors:on -o:{buildDir}/jwt {srcDir}/jwt.nim"

task release, "Build for prod":
    exec "nimble test"
    exec "nimble cleanup"
    exec "nimble fmt"
    exec &"nim c --d:release --opt:size -o:{relDir}/jwt {srcDir}/{app}.nim"

    when not defined windows:
        exec &"strip {relDir}/{app}"

task clean, "Ignore":
    echo "Use cleanup instead"

task cleanup, "Delete generated files":
    rmDir "bin"
    rmDir "dist"

task dist, "Create distribution":
    exec "nimble release"

    var osName = ""
    var archName = ""

    if not exists distDir:
        mkDir distDir

    when defined windows:
        osName = "windows"
    elif defined linux:
        osName = "linux"
    elif defined osx:
        osName = "osx"
    else:
        echo "unexpected os"
        quit QuitFailure

    when defined amd64:
        archName = "amd64"
    elif defined arm64:
        archName = "arm64"
    else:
        echo "unexpected architecture"
        quit QuitFailure

    let packageName = &"{app}_{version}_{osName}_{archName}"

    if defined windows:
        exec &"pwsh -Command Get-ChildItem -Path {relDir}/jwt.exe, LICENSE, README.md | Compress-Archive -Destination {distDir}/{packageName}.zip"
    else:
        exec &"zip -j {packageName}.zip {relDir}/jwt LICENSE README.md"
        mvFile &"{packageName}.zip", &"{distDir}/{packageName}.zip"

task fmt, "Format Nim source files (https://nim-lang.org/docs/nep1.html)":
    exec "nimpretty jwt.nimble src/jwt.nim src/jwt/common.nim"

task tag, "Push the commits to repo and generate a new tag":
    exec "git push"
    exec &"git tag -a {version} -m 'Version {version}'"
    exec "git push --tags"
