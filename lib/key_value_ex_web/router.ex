defmodule KeyValueExWeb.Router do
  use KeyValueExWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KeyValueExWeb do
    pipe_through :api
  end
end
