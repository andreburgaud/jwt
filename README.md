# JSON Web Token (JWT)

The initial version of this tool takes a command **decode**, `--decode` or `-d`, and a [JSON Web Token](https://jwt.io/) (JWT), either as a string with option `--string`, or as one or multiple files passed as arguments, then prints the content of the header and payload to the output in valid JSON format.

## Usage Examples

### JWT File

```
jwt --decode tokens/hs256.token
```
```json
[
  {
    "alg": "HS256",
    "typ": "JWT"
  },
  {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  }
]
```

### JWT String

```
jwt --decode --string eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```
```json
[
  {
    "alg": "HS256",
    "typ": "JWT"
  },
  {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  }
]
```

### Piping with jq

```
jwt --decode tokens/hs256.token | jq
```
```json
[
  {
    "alg": "HS256",
    "typ": "JWT"
  },
  {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  }
]
```

The command line [jq](https://stedolan.github.io/jq/) highlights the syntax of the JSON data.

### From stdin

```
cat tokens/hs256.token | jwt -d | jq
```
```json
[
  {
    "alg": "HS256",
    "typ": "JWT"
  },
  {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  }
]
```

### Help

```
jwt
```
```
                              JWT Command Line 0.5.0
                      Copyright (c) 2021-2023 - Andre Burgaud
                                    MIT License

Description:
  Parses an encoded JSON Web Token (JWT) and decode the
  JWT Header and Payload into a valid JSON content.
  Converts dates (iat, exp) into human readable format
  unless the option '--raw' is passed at the command line.

  The JWT token can be passed via standard input, a file or a string.

Usage:
  jwt --decode <jwt_file>                  | -d <jwt_file>
  jwt --decode --flatten <jwt_file>        | -d -f <jwt_file>
  jwt --decode --string <jwt_string>       | -d -s=<jwt_string>
  jwt --decode --raw --string <jwt_string> | -d -r -s=<jwt_string>
  jwt --version                            | -v
  jwt --help                               | -h

Commands:
  -h | --help    : show this screen
  -v | --version : show version
  -d | --decode  : decode JWT token into a valid JSON string

Options:
  -s | --string  : take a JWT token string as argument instead of file
  -f | --flatten : render a JSON representation of the token with raw data for each field
  -r | --raw     : keep the dates (iat, exp) as numeric values (epoch time)
```

## TODO

### Commands

- [ ] create
- [ ] check/validate

### Options

- [ ] debug

## Development

### Build

```
nimble dev
```

### Test

```
nimble test
```

### Release

```
nimble release
```

### Dist

```
nimble dist
```

## Resources

* https://tools.ietf.org/html/rfc7519
* https://jwt.io/
* https://stedolan.github.io/jq/