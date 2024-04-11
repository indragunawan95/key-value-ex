defmodule KeyValueEx.RedisClient.ConnectionTest do
  use ExUnit.Case
  import Mimic

  describe "connect/2" do
    setup do
      # Stub the Transport.connect function to return {:ok, :socket} by default
      stub(Transport, :connect, fn _host, _port, _options -> {:ok, :socket} end)
      # Ensure other functions have a reasonable default if not explicitly expected
      stub(Transport, :send, fn _socket, _command -> :ok end)
      stub(Transport, :recv, fn _socket, _length, _timeout -> {:ok, "+OK\r\n"} end)
      :ok
    end

    test "successfully connects to the server" do
      assert KeyValueEx.RedisClient.Connection.connect() == {:ok, :socket}
    end

    test "can override stub with specific behavior" do
      # Override the stub for a specific test case
      expect(Transport, :connect, fn _host, _port, _options -> {:error, :econnrefused} end)

      assert KeyValueEx.RedisClient.Connection.connect() == {:error, :econnrefused}
    end
  end

  describe "handle_response/2" do
    test "handles a complete simple string response successfully" do
      stub(Transport, :recv, fn _socket, _length, _timeout -> {:ok, "+OK\r\n"} end)
      assert KeyValueEx.RedisClient.Connection.handle_response(:socket) == {:ok, "+OK\r\n"}
    end

    test "handles an error response and raises" do
      expect(Transport, :recv, fn _socket, _length, _timeout -> {:ok, "-Error message\r\n"} end)

      assert_raise RuntimeError, "Error response", fn ->
        KeyValueEx.RedisClient.Connection.handle_response(:socket)
      end
    end

    test "handles an incomplete bulk string response and fetches the rest" do
      expect(Transport, :recv, 1, fn _socket, _length, _timeout -> {:ok, "$3\r\nfo"} end)
      expect(Transport, :recv, 2, fn _socket, _length, _timeout -> {:ok, "o\r\n"} end)

      assert KeyValueEx.RedisClient.Connection.handle_response(:socket) == {:ok, "$3\r\nfoo\r\n"}
    end

    test "handles network errors gracefully" do
      expect(Transport, :recv, fn _socket, _length, _timeout -> {:error, :timeout} end)

      assert KeyValueEx.RedisClient.Connection.handle_response(:socket) == {:error, :timeout}
    end
  end
end
