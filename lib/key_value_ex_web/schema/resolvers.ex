defmodule KeyValueExWeb.Schema.Resolvers do
  alias KeyValueExWeb.API.KeyValue

  def store_key_value(_parent, args, _context) do
    KeyValue.store_key_value(args)
  end

  def fetch_key_value(_parent, args, _context) do
    KeyValue.fetch_key_value(args)
  end
end
