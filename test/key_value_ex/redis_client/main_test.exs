defmodule KeyValueEx.RedisClient.MainTest do
  use ExUnit.Case
  import Mimic

  describe "init/1" do
    test "initializes with a successful connection and authentication" do
      # Mocking the Connection.connect/2 function to return a successful connection
      stub(KeyValueEx.RedisClient.Connection, :connect, fn _host, _port ->
        {:ok, :socket}
      end)

      stub(KeyValueEx.RedisClient.Connection, :send_and_receive, fn _, _ ->
        {:ok, ""}
      end)

      assert {:ok, _state} =
               KeyValueEx.RedisClient.Main.init(%{
                 config: [host: "localhost2", port: 6399, username: "user", password: "pass"]
               })
    end

    test "initializes with a connection error" do
      stub(KeyValueEx.RedisClient.Connection, :connect, fn _, _ ->
        {:error, :connection_failed}
      end)

      assert {:stop, :connection_failed} = KeyValueEx.RedisClient.Main.init(%{config: []})
    end
  end

  describe "command/2" do
    test "sends and receives a command" do
      Mimic.copy(KeyValueEx.RedisClient.Connection)

      stub(KeyValueEx.RedisClient.Parser, :build_command, fn _command_list ->
        ""
      end)

      stub(KeyValueEx.RedisClient.Connection, :send_and_receive, fn _socket, _command ->
        {:ok, "OKE"}
      end)

      stub(KeyValueEx.RedisClient.Parser, :parse_response, fn response ->
        response
      end)

      assert {:ok, "OKE"} = KeyValueEx.RedisClient.Main.command(:socket, ["SET", "key", "value"])
    end

    test "failed sends and receives a command" do
      stub(KeyValueEx.RedisClient.Connection, :send_and_receive, fn _socket, _command ->
        {:error, "something went wrong"}
      end)

      assert {:error, "something went wrong"} =
               KeyValueEx.RedisClient.Main.command(:socket, ["SET", "key", "value"])
    end
  end
end
