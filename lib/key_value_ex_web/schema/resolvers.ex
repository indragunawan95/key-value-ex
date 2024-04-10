defmodule KeyValueExWeb.Schema.Resolvers do
  alias KeyValueEx.RedisClient.Main, as: Client

  def store_key_value(_parent, %{key: key, value: value} = _args, _context) do
    Client.set(key, value)
  end

  def fetch_key_value(_parent, %{key: key} = _args, _context) do
    Client.get(key)
  end
end
