defmodule KeyValueEx.Mycoba do
  alias KeyValueEx.RedisClient.Main, as: RedisClient

  def set_value(key, value) do
    # Call the set function on RedisClient.
    # This assumes your RedisClient is started and supervised with the name `KeyValueEx.RedisClient.Main`
    RedisClient.set(key, value)
  end

  def get_value(key) do
    # Call the get function on RedisClient.
    RedisClient.get(key)
  end
end
