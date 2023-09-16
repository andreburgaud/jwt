import json, unittest
include jwt/encode

const
  KEY = "secret_key"

  JSON_JWT_HS256 = """{
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
  }"""
  ENCODED_JWT_HS256 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.-31VfEDt_2aatZ0NIjznd27ruqyeMC4zus1J3hjZlts"

  JSON_JWT_HS384 = """{
    "header": {
      "alg": "HS384",
      "typ": "JWT"
    },
    "payload": {
      "sub": "1234567890",
      "name": "John Doe",
      "iat": 1516239022
    },
    "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  }"""
  ENCODED_JWT_HS384 = "eyJhbGciOiJIUzM4NCIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.4OilFwcl08oaQsXOK5UMiC5iX2bLoVwIakf04kjPpz3DcBDowQE3ZFOfuDRwaKrE"

  JSON_JWT_HS512 = """{
    "header": {
      "alg": "HS512",
      "typ": "JWT"
    },
    "payload": {
      "sub": "1234567890",
      "name": "John Doe",
      "iat": 1516239022
    },
    "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  }"""
  ENCODED_JWT_HS512 = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.TgpsaNeRrZ0Q2tqbHc69QncTjIb3_qqwIf1e4-2DRzDgiVJDveurj5yukPO6TduGKiI65Okr01-eEsuhWsPDCw"

  JSON_JWT_RS256 = """{
    "header": {
      "alg": "RS256",
      "typ": "JWT"
    },
    "payload": {
      "sub": "1234567890",
      "name": "John Doe",
      "iat": 1516239022
    },
    "signature": "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  }"""


suite "encode":

  test "encode HS256 JSON":
    let result = encodeJwtStr(JSON_JWT_HS256, KEY)
    check result == ENCODED_JWT_HS256

  test "encode HS384 JSON":
    let result = encodeJwtStr(JSON_JWT_HS384, KEY)
    check result == ENCODED_JWT_HS384

  test "encode HS512 JSON":
    let result = encodeJwtStr(JSON_JWT_HS512, KEY)
    check result == ENCODED_JWT_HS512

  test "encode unsupported RS256 JSON":
    expect JwtException:
      discard encodeJwtStr(JSON_JWT_RS256, KEY)
