defmodule KeyValueEx.RedisClient do

  @crlf "\r\n"
  def connect(host \\ 'localhost', port \\ 6379, username \\ nil, password \\ nil) do
    case :gen_tcp.connect(to_charlist(host), port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        case authenticate(socket, username, password) do
          {:ok, _} -> {:ok, socket}
          {:error, _} = error -> error
        end
      {:error, _} = error -> error
    end
  end

  defp authenticate(_socket, nil, nil), do: :ok
  defp authenticate(socket, username, password) do
    command =
      if username do
        ["*3\r\n", "$4\r\nAUTH\r\n", "$#{byte_size(username)}\r\n#{username}\r\n", "$#{byte_size(password)}\r\n#{password}\r\n"]
      else
        ["*2\r\n", "$4\r\nAUTH\r\n", "$#{byte_size(password)}\r\n#{password}\r\n"]
      end
    |> Enum.join()

    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end

  def set(socket, key, value) do
    command =
      ["*3\r\n", "$3\r\nSET\r\n", "$#{byte_size(key)}\r\n#{key}\r\n", "$#{byte_size(value)}\r\n#{value}\r\n"]
    |> Enum.join()

    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end

  def get(socket, key) do
    command =
      ["*2\r\n", "$3\r\nGET\r\n", "$#{byte_size(key)}\r\n#{key}\r\n"]
    |> Enum.join()

    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end

  def ping(socket) do
     command = "*1\r\n$4\r\nPING\r\n"
     :ok = :gen_tcp.send(socket, command)

     receive_response(socket)

  end

  defp receive_response(socket, acc \\ "") do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, response} ->
        new_acc = acc <> response
        IO.inspect(new_acc)
        # Determine if we've received the full response
        case full_response_received?(new_acc) do
          true ->
            {:ok, parse_response(new_acc)}
          false ->
            receive_response(socket, new_acc)
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp full_response_received?(response) do
  # Check if response starts with the bulk string indicator
    if String.starts_with?(response, "$") do
      parts = String.split(response, "\r\n", parts: 3)
      # Ensure parts list is long enough and length string is not empty
      if length(parts) > 1 and parts |> Enum.at(1) != "" do
        [_, length_string | _rest] = parts
        # Safely attempt to convert the length string to an integer
        try do
          IO.inspect("here")
          IO.inspect(length_string)
          length = String.to_integer(length_string)

          # Calculate the expected length of the complete response
          expected_length = byte_size(length_string) + length + 5 # Adjust for CRLFs and length prefix
          # IO.inspect("size response: #{inspect(byte_size(response))}")
          # IO.inspect("expected_length: #{inspect(expected_length)}")
          # IO.inspect("length_string: #{inspect(length_string)}")
          # IO.inspect("byte_size: #{inspect(byte_size(length_string))}")
          byte_size(response) >= expected_length
        rescue
          ArgumentError -> false # If conversion fails, assume the response is incomplete
        end
      else
        false # If the length string is empty, the response is incomplete
      end
    else
      true # Non-bulk string responses are assumed to be complete
    end
  end

  defp parse_response(response) do
    IO.puts("Raw response: #{inspect(response)}")
    # Your existing parse logic, assuming it now receives the full response
    parts = String.split(response, "\r\n", trim: true)
    handle_response_parts(parts)
  end

  defp handle_response_parts(["+OK"]), do: :ok
  defp handle_response_parts(["$-1"]), do: nil
  defp handle_response_parts(["$0", ""]), do: ""
  defp handle_response_parts(["+PONG"]), do: "PONG"
  defp handle_response_parts(["$" <> length_string, value | _rest]) do
    length = String.to_integer(length_string)
    if byte_size(value) == length, do: value, else: handle_incomplete_bulk_string(length, value)
  end
  defp handle_response_parts(_), do: "Unknown response format"

  # Handle cases where the full bulk string value might not have been received
  defp handle_incomplete_bulk_string(expected_length, partial_value) do
    if byte_size(partial_value) < expected_length, do: "Incomplete response"
  end

end
