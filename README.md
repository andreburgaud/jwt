# JSON Web Token (JWT)

`jwt` is a command line (CLI) tool to encode or decode [JSON Web Tokens](https://jwt.io/) (JWT).

## Usage

### JWT Decode Token File

```bash
jwt decode tokens/hs256.token
```
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  },
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

### JWT Decode Token String

```bash
jwt decode --string eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  },
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

### From stdin

```bash
cat tokens/hs256.token | jwt decode
```
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022
  },
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

### JWT Encode JSON File

```bash
jwt encode --key secret_key tokens/hs256.json
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts
```

### JWT Encode JSON String

```bash
export JWT_JSON='{"header":{"alg":"HS256","typ":"JWT"},"payload":{"sub":"1234567890","name":"John Doe","iat":1516239022},"signature":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}'
jwt encode --key secret_key --string "$JWT_JSON"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts
```

### Pipe Encode and Decode

```bash
jwt encode --key secret_key tokens/hs256.json | jwt decode
```
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": "2018-01-17T19:30:22-06:00"
  },
  "signature": "-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts"
}
```

### Help

```bash
jwt --help
```
```
                             JWT Command Line 0.10.0
                       Copyright (c) 2021-2023 - Andre Burgaud
                                     MIT License
Description:
  Manipulate (encode, or decode) JSON Web Tokens (JWT).

Usage:
  jwt [OPTIONS]
  jwt [COMMAND] [OPTIONS] [ARGS]

Options:
  -h, --help       Print help
  -v, --version    Print version info

Commands:
  decode    Decode a b64 encoded JWT token into a valid JSON string
  encode    Encode a JWT JSON file or string into a b64 encoded JWT token

  jwt [COMMAND] --help for more information on a specific command.

```

## Development

`jwt` is written in [Nim](https://nim-lang.org/), which needs to be installed to build `jwt`.

### Debug Build

To build a debug version of `jwt`, execute the following command:

```bash
nimble build
```

The executable will be available at the root of the project. For a simple test, on Linux or Mac OS, you can run:

```bash
./jwt decode tokens/hs256.token
```

### Release Build

To build a debug version of `jwt`, execute the following command:

```bash
nimble release
```

The executable will be available in `bin/release`.

### Test

To execute the unit tests, execute the following command:

```bash
nimble test
```

### Build a Windows package on Linux

to build a windows distribution on Linux:

```bash
nimble dist_xc_win64
```

The nimbe task `dist_xc_win64` will create a 64-bit release version and a zip package under `dist`.

## License

`jwt` is release under the [MIT License](/LICENSE)

## Resources

* [JSON Web Token (JWT) - RFC 7519](https://tools.ietf.org/html/rfc7519)
* [JWT](https://jwt.io/)
* [Nim](https://nim-lang.org/)