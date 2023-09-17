# JSON Web Token (JWT)

`jwt` is a command line (CLI) tool that encode or decode [JSON Web Tokens](https://jwt.io/) (JWT).

## Usage

### JWT Decode Token File

```
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
    "iat": "2018-01-17T19:30:22-06:00"
  },
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

### JWT Decode Token String

```
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
    "iat": "2018-01-17T19:30:22-06:00"
  },
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

### Piping with jq

```
jwt decode tokens/hs256.token | jq
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
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

The command line [jq](https://stedolan.github.io/jq/) highlights the syntax of the JSON data. On Windows, add option `-C` (colorize JSON) to the `jq` command, as follows:

```
jwt d tokens\hs256.token | jq -C
```

### From stdin

```
cat tokens/hs256.token | jwt decode | jq
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
  "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}
```

### JWT Encode JSON File

```
jwt encode --key secret_key tokens/hs256.json
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts
```

### JWT Encode JSON String

```
export JWT_JSON='{"header":{"alg":"HS256","typ":"JWT"},"payload":{"sub":"1234567890","name":"John Doe","iat":1516239022},"signature":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}'
jwt encode --key secret_key --string "$JWT_JSON"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts
```

### Pipe Encode, Decode, and Jq

```
jwt encode --key secret_key tokens/hs256.json | jwt decode | jq
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

```
jwt --help
```
```
                             JWT Command Line 0.8.0
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
  decode, d      Decode a b64 encoded JWT token into a valid JSON string
  encode, e      Encode a JWT JSON file or string into a b64 encoded JWT token

  jwt [COMMAND] --help for more information on a specific command.

```

## Resources

* https://tools.ietf.org/html/rfc7519
* https://jwt.io/
* https://stedolan.github.io/jq/