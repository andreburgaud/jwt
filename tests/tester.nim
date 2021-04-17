import unittest
import jwt

suite "jwt":

  test "split jwt 3 fields":
    let (header, payload, signature) = splitJwt("un.deux.trois")
    check header == "un"
    check payload == "deux"
    check signature == "trois"

  test "split jwt empty signature":
    let (header, payload, signature) = splitJwt("un.deux.")
    check header == "un"
    check payload == "deux"
    check signature == ""

  test "split jwt 2 fields (exception)":
    expect JwtException:
      discard splitJwt("un.deux")
