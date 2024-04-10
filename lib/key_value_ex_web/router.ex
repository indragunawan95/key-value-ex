defmodule KeyValueExWeb.Router do
  use KeyValueExWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  forward "/graphql", Absinthe.Plug, schema: KeyValueExWeb.Schema
  forward "/graphiql", Absinthe.Plug.GraphiQL, schema: KeyValueExWeb.Schema, interface: :simple
end
