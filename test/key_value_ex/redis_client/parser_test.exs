defmodule KeyValueEx.RedisClient.ParserTest do
  use ExUnit.Case

  alias KeyValueEx.RedisClient.Parser

  describe "build_command/1" do
    test "builds a valid Redis command from a list of parts" do
      assert Parser.build_command(["SET", "key", "value"]) ==
               "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n"
    end
  end

  describe "parse_response/1" do
    test "parses a simple 'OK' response" do
      assert Parser.parse_response("+OK\r\n") == "OK"
    end

    test "parses a nil response" do
      assert Parser.parse_response("$-1\r\n") == nil
    end

    test "parses an empty string response" do
      assert Parser.parse_response("$0\r\n\r\n") == ""
    end

    test "parses a 'PONG' response" do
      assert Parser.parse_response("+PONG\r\n") == "PONG"
    end

    test "parses a valid bulk string response" do
      assert Parser.parse_response("$5\r\nhello\r\n") == "hello"
    end

    test "returns 'Incomplete response' for a partial bulk string" do
      assert Parser.parse_response("$5\r\nhel\r\n") == "Incomplete response"
    end

    test "handles unknown response formats" do
      assert Parser.parse_response("+UNKNOWN\r\n") == "Unknown response format"
    end
  end
end
