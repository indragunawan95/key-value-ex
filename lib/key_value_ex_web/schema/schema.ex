defmodule KeyValueExWeb.Schema do
  use Absinthe.Schema
  alias KeyValueExWeb.Schema.Resolvers

  import_types(KeyValueExWeb.Schema.Types)

  query do
    @desc "Fetch from key-value redis using specific key"

    field :fetch_key_value, :key_val do
      arg(:key, non_null(:string))

      resolve(&Resolvers.fetch_key_value/3)
    end
  end

  mutation do
    @desc "Store value redis using specific key"
    field :store_key_value, :key_val do
      arg(:key, non_null(:string))
      arg(:value, non_null(:string))

      resolve(&Resolvers.store_key_value/3)
    end
  end
end
