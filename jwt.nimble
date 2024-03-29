import strformat
import src/jwt/common

# Package
version = ver
author = "Andre"
description = "JWT Command Line"
license = lic
srcDir = "src"
bin = @["jwt"]

let app = "jwt"
let distDir = "dist"
let testsDir = "tests"
let relDir = "bin/release"
let buildDir = "bin/debug"
let winAmd64 = "winamd64"

# Dependencies
requires "nim >= 2.0.0"
requires "nimcrypto"

# Tasks
task test, "Run the test suite":
  exec &"nim c -r {testsDir}/test_decode.nim"
  exec &"nim c -r {testsDir}/test_encode.nim"

task debug, "Build for development":
  exec &"nim c --colors:on -o:{buildDir}/jwt {srcDir}/{app}.nim"

task dist_xc_win64, "Linux Cross Compile for Windows x64":
  # Cross compilation of jwt on Linux to target Windows x64
  # MinGW64 toolchain needs to be installed on Linux
  if not exists &"{distDir}":
    mkDir &"{distDir}"
  if not exists &"{relDir}/{winAmd64}":
    mkDir &"{relDir}/{winAmd64}"
  exec &"nim c -d:release -d:mingw --cpu:amd64 --opt:size -o:{relDir}/{winAmd64}/{app}.exe {srcDir}/{app}.nim"
  exec &"strip {relDir}/{winAmd64}/{app}.exe"
  let packageName = &"{app}_{ver}_windows_amd64"
  exec &"zip -j {packageName}.zip {relDir}/{winAmd64}/{app}.exe LICENSE README.md"
  mvFile &"{packageName}.zip", &"{distDir}/{packageName}.zip"

task release, "Build for prod":
  exec "nimble test"
  exec "nimble cleanup"
  exec "nimble fmt"
  exec &"nim c -d:release --opt:size -o:{relDir}/{app} {srcDir}/{app}.nim"

  when not defined windows:
    exec &"strip {relDir}/{app}"

task clean, "Ignore":
  echo "Use cleanup instead"

task cleanup, "Delete generated files":
  rmDir "bin"
  rmDir "dist"
  rmDir "htmldocs"
  rmFile &"{app}"
  rmFile "tests/test_decode"
  rmFile "tests/test_encode"

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

  let packageName = &"{app}_{ver}_{osName}_{archName}"

  if defined windows:
    exec &"pwsh -Command Get-ChildItem -Path {relDir}/{app}.exe, LICENSE, README.md | Compress-Archive -Destination {distDir}/{packageName}.zip"
  else:
    exec &"zip -j {packageName}.zip {relDir}/{app} LICENSE README.md"
    mvFile &"{packageName}.zip", &"{distDir}/{packageName}.zip"

task fmt, "Format Nim source files (https://nim-lang.org/docs/nep1.html)":
  exec &"nimpretty {app}.nimble src/{app}.nim src/jwt/*.nim"

task tag, "Push the commits to repo and generate a new tag":
  exec "git push"
  exec &"git tag -a {ver} -m 'Version {ver}'"
  exec "git push --tags"

task htmldoc, "Generate the code documentation":
  exec &"nim doc --project --index:on --outdir:htmldocs {srcDir}/{app}.nim"

task servedoc, "Serve the code documentation":
  exec "python3 -m http.server 7029 --directory htmldocs"
