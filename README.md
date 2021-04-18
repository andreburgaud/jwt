# JSON Web Token (JWT)

The initial version of this tool takes a command **extract**, `--extract` or `-x`, and a [JSON Web Token](https://jwt.io/) (JWT), either as a string with option `--string`, or as one or multiple files passed as arguments, then prints the content of the header and payload to the output in valid JSON format.

## Usage Examples

### JWT File

```
$ jwt --extract tokens/hs256.token
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
$ jwt --extract --string eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
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
$ jwt --extract tokens/hs256.token | jq
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
$ cat tokens/hs256.token | jwt -x | jq
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

## TODO

### Commands

- [ ] create
- [ ] check/validate

### Options

- [ ] debug

## Development

### Build

```
$ nimble build --verbose
```

### Test

```
$ nimble test
```

### Release

```
$ nimble build --d:release --opt:size
$ strip jwt
$ upx jwt # optional
```

## Resources

* https://tools.ietf.org/html/rfc7519
* https://jwt.io/
* https://stedolan.github.io/jq/