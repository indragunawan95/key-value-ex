defmodule KeyValueEx.RedisClient do

  @clrf "\r\n"
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

  # Helper function to build commands using the @clrf constant.
  defp build_command(parts) when is_list(parts) do
    # Calculate the total number of parts
    total_parts = Enum.count(parts)

    # Prepend the total count and reassemble the parts
    full_command =
      ["*#{total_parts}"] ++ Enum.flat_map(parts, fn part ->
        ["$#{byte_size(part)}", part]
      end)

    # Join all parts using CRLF and append a final CRLF
    Enum.join(full_command, @clrf) <> @clrf
  end

  defp authenticate(_socket, nil, nil), do: :ok
  defp authenticate(socket, username, password) do
    parts = if username do
      ["AUTH", username, password] # Assuming `username` and `password` are always strings.
    else
      ["AUTH", password]
    end

    command = build_command(parts)

    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end

  def set(socket, key, value) do
    command = build_command(["SET", key, value])
    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end

  def get(socket, key) do
    command = build_command(["GET", key])
    :ok = :gen_tcp.send(socket, command)
    receive_response(socket)
  end

  def ping(socket) do
     command = build_command(["PING"])
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

  # TODO: Need to refactor this
  defp full_response_received?(response) do
    IO.inspect(response, label: "Raw response")

    if String.starts_with?(response, "$") do
      case String.split(response, "\r\n", parts: 3) do
        ["$" <> length_string, _payload_part | _] when length_string != "" ->
          try do
            length = String.to_integer(length_string)
            expected_length = byte_size(length_string) + length + 5 # $, length, \r\n, payload, \r\n
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
      true # This assumes non-bulk responses are complete, may need adjustment based on your protocol handling needs
    end
  end

  defp parse_response(response) do
    IO.puts("Raw response: #{inspect(response)}")
    # Your existing parse logic, assuming it now receives the full response
    parts = String.split(response, "\r\n", trim: true)
    handle_response_parts(parts)
  end

  #TODO: Refactor this
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
