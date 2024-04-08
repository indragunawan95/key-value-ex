defmodule KeyValueEx.Repo do
  use Ecto.Repo,
    otp_app: :key_value_ex,
    adapter: Ecto.Adapters.Postgres
end
