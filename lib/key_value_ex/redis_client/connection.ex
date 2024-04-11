defmodule Transport do
  def connect(host, port, opts), do: :gen_tcp.connect(host, port, opts)
  def send(socket, data), do: :gen_tcp.send(socket, data)
  def recv(socket, length, timeout), do: :gen_tcp.recv(socket, length, timeout)
end

defmodule KeyValueEx.RedisClient.Connection do
  require Logger
  alias Transport
  # Handles connecting to the Redis server
  def connect(host \\ ~c"localhost", port \\ 6379) do
    case Transport.connect(to_charlist(host), port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, _} = error ->
        error
    end
  end

  # Handles receiving responses from the Redis server
  def handle_response(socket, acc \\ "") do
    case Transport.recv(socket, 0, 5000) do
      {:ok, response} ->
        new_acc = acc <> response

        if full_response_received?(new_acc) do
          {:ok, new_acc}
        else
          handle_response(socket, new_acc)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp full_response_received?(response) do
    Logger.info("Raw response: #{inspect(response)}")
    handler_completeness(response)
  end

  defp handler_completeness("+" <> _rest), do: true
  defp handler_completeness("$-1" <> _rest), do: true
  defp handler_completeness("$" <> rest), do: handle_bulk_string("$" <> rest)

  defp handler_completeness("-" <> rest) do
    Logger.error("Error response #{inspect(rest)}")
    raise "Error response"
  end

  defp handler_completeness(_), do: raise("Unhandled response")

  defp handle_bulk_string(response) do
    case String.split(response, "\r\n", parts: 3) do
      ["$" <> length_string, _payload_part | _] when length_string != "" ->
        try do
          length = String.to_integer(length_string)
          # $, length, \r\n, payload, \r\n
          expected_length = byte_size(length_string) + length + 5
          current_length = byte_size(response)

          if current_length >= expected_length do
            Logger.info("Full response received")
            true
          else
            Logger.info("Waiting for more data")
            false
          end
        rescue
          ArgumentError ->
            Logger.error("Failed to convert length string to integer")
            false
        end

      _ ->
        Logger.error("Length string is empty or parts are insufficient")
        false
    end
  end

  # function to send command and receive raw response
  # command is mus be valid RESP command
  def send_and_receive(socket, command) do
    :ok = Transport.send(socket, command)
    handle_response(socket)
  end
end
