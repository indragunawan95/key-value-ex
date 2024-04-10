defmodule KeyValueEx.RedisClient.Connection do
  # Handles connecting to the Redis server
  def connect(host \\ ~c"localhost", port \\ 6379) do
    case :gen_tcp.connect(to_charlist(host), port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, _} = error ->
        error
    end
  end

  # Handles receiving responses from the Redis server
  def receive_response(socket, acc \\ "") do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, response} ->
        new_acc = acc <> response

        if full_response_received?(new_acc) do
          {:ok, new_acc}
        else
          receive_response(socket, new_acc)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # TODO: Need to refactor this
  def full_response_received?(response) do
    IO.inspect(response, label: "Raw response")

    if String.starts_with?(response, "$") do
      case String.split(response, "\r\n", parts: 3) do
        ["$" <> length_string, _payload_part | _] when length_string != "" ->
          try do
            length = String.to_integer(length_string)
            # $, length, \r\n, payload, \r\n
            expected_length = byte_size(length_string) + length + 5
            current_length = byte_size(response)

            if current_length >= expected_length do
              IO.puts("Full response received")
              true
            else
              IO.puts("Waiting for more data")
              false
            end
          rescue
            ArgumentError ->
              IO.puts("Failed to convert length string to integer")
              false
          end

        _ ->
          IO.puts("Length string is empty or parts are insufficient")
          false
      end
    else
      IO.puts("Response does not start with bulk string indicator")

      # This assumes non-bulk responses are complete, may need adjustment based on your protocol handling needs
      true
    end
  end

  # function to send command and receive raw response
  # command is mus be valid RESP command
  def send_and_receive(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end
end
