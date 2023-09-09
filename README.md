# JSON Web Token (JWT)

The initial version of this tool takes a command **decode**, `--decode` or `-d`, and a [JSON Web Token](https://jwt.io/) (JWT), either as a string with option `--string`, or as one or multiple files passed as arguments, then prints the content of the header and payload to the output in valid JSON format.

## Usage

### JWT Decode Token File

```
jwt --decode tokens/hs256.token
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
jwt --decode --string eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
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
jwt --decode tokens/hs256.token | jq
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
jwt -d tokens\hs256.token | jq -C
```

### From stdin

```
cat tokens/hs256.token | jwt -d | jq
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
./jwt --encode --key secret_key tokens/hs256.json
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts
```

### JWT Encode JSON String

```
export JWT_JSON='{"header":{"alg":"HS256","typ":"JWT"},"payload":{"sub":"1234567890","name":"John Doe","iat":1516239022},"signature":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}'
jwt --encode --key secret_key --string "$JWT_JSON"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts
```

### Pipe Encode, Decode, and Jq

```
jwt --encode --key secret_key tokens/hs256.json | ./jwt --decode | jq
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
                                       JWT Command Line 0.6.0
                              Copyright (c) 2021-2023 - Andre Burgaud
                                            MIT License

Description:
  Parses an encoded JSON Web Token (JWT) and decode the
  JWT Header and Payload into a valid JSON content.
  Converts dates (iat, exp) into human readable format
  unless the option '--raw' is passed at the command line.

  The JWT token can be passed via standard input, a file or a string.

Usage:
  jwt --decode <token_file>                           | -d <token_file>
  jwt --decode --flatten <token_file>                 | -d -f <token_file>
  jwt --decode --string <token_string>                | -d -s=<token_string>
  jwt --decode --raw --string <token_string>          | -d -r -s=<token_string>
  jwt --encode --key <secret> --string <json_string>  | -e k=<secret> -s=<json_string>
  jwt --encode --key <secret> <json_file>             | -e k=<secret> <json_file>
  jwt --version                                       | -v
  jwt --help                                          | -h

Commands:
  -h | --help    : show this screen
  -v | --version : show version
  -d | --decode  : decode JWT token into a valid JSON string
  -e | --encode  : encode a JWT Header and Payload (option key is required)

Options:
  -k | --key     : take a secret key string as argument (required with 'encode')
  -s | --string  : take a JWT token string as argument instead of file
  -f | --flatten : render a JSON representation of the token with raw data for each field (only with 'decode')
  -r | --raw     : keep the dates (iat, exp) as numeric values (only with 'decode')
```

## Resources

* https://tools.ietf.org/html/rfc7519
* https://jwt.io/
* https://stedolan.github.io/jq/