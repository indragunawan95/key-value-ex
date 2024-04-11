defmodule KeyValueExWeb.Schema.Types do
  use Absinthe.Schema.Notation

  object :key_val do
    field :key, :string
    field :value, :string
  end
end
