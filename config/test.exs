import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# config :key_value_ex, KeyValueEx.Repo,
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   database: "key_value_ex_test#{System.get_env("MIX_TEST_PARTITION")}",
#   pool: Ecto.Adapters.SQL.Sandbox,
#   pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :key_value_ex, KeyValueExWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "SmM8VaBaRA+6IPeQg8Z9e2xrPtIM1ahd+FhnqyUIZhK8F+kYtIgs4myRUpIGmMCG",
  server: false

config :key_value_ex, KeyValueEx.RedisClient.Main,
  host: System.get_env("REDIS_HOST_TEST"),
  port: System.get_env("REDIS_PORT_TEST", "0") |> String.to_integer(),
  username: System.get_env("REDIS_USERNAME_TEST"),
  password: System.get_env("REDIS_PASSWORD_TEST")

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
