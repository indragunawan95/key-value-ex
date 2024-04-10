defmodule KeyValueEx.RedisClient.Parser do
  @clrf "\r\n"

  # Helper function to build commands using the @clrf constant.
  def build_command(parts) when is_list(parts) do
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

  def parse_response(response) do
    parts = String.split(response, @clrf, trim: true)
    handle_response_parts(parts)
  end

  defp handle_response_parts(["+OK"]), do: "OK"
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
