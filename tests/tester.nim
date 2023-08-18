import json, unittest
import jwt

const
  ENCODED_JWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  JSON_JWT = """[{"alg":"HS256","typ":"JWT"},{"sub":"1234567890","name":"John Doe","iat":1516239022},{"signature":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}]"""

  BAD_TWO_PARTS_JWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQSflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  
  # JWT with header and pyaload truncated by 1 character (corresponding JSON below) 
  BAD_JWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyf.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
  BAD_JSON = """[{"alg":"HS256","typ":"JWT",{"sub":"1234567890","name":"John Doe","iat":1516239022,{"signature":"SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"}]"""

suite "jwt":

  test "split jwt 3 fields":
    let (header, payload, signature) = splitJwt "un.deux.trois"
    check header == "un"
    check payload == "deux"
    check signature == "trois"

  test "split jwt empty signature":
    let (header, payload, signature) = splitJwt "un.deux."
    check header == "un"
    check payload == "deux"
    check signature == ""

  test "split jwt 2 fields (exception)":
    expect JwtException:
      discard splitJwt "un.deux"

  test "extract valid JWT":
    let jsonStr = decodeJwtStr ENCODED_JWT
    check jsonStr == JSON_JWT

  test "extract bad two part JWT":
    expect JwtException:
      discard decodeJwtStr BAD_TWO_PARTS_JWT

  test "extract bad JWT":
    # Altered good JWT by removing last b64 chars of the header and payload
    # The corresponding JSON would fail in the tool when attempting to run parseJson
    # See next test
    let jsonStr = decodeJwtStr BAD_JWT
    check jsonStr == BAD_JSON

  test "JSON parse error":
    expect JsonParsingError:
        discard parseJson BAD_JSON
