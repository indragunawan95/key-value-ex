defmodule KeyValueExWeb.Schema.Types do
  use Absinthe.Schema.Notation

  object :test do
    field :id, :id
    field :name, :string
    field :email, :string
  end
end
