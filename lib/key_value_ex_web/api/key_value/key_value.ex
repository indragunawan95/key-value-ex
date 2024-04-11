defmodule KeyValueExWeb.API.KeyValue do
  alias KeyValueEx.RedisClient.Main, as: Client

  def store_key_value(%{key: key, value: value} = _args) do
    # Validation step
    with false <- String.trim(key) == "",
         false <- String.trim(value) == "" do
      Client.set(key, value)
      |> case do
        {:ok, _} ->
          {:ok, %{key: key, value: value}}

        {:error, msg} ->
          {:error, msg}
      end
    else
      _ -> {:error, "Key and value must not be empty"}
    end
  end

  def fetch_key_value(%{key: key} = _args) do
    with false <- String.trim(key) == "" do
      Client.get(key)
      |> case do
        {:ok, val} ->
          {:ok, %{key: key, value: val}}

        {:error, msg} ->
          {:error, msg}
      end
    else
      _ -> {:error, "Key must not be empty"}
    end
  end
end
