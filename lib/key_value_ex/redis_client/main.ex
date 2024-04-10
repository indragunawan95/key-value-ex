defmodule KeyValueEx.RedisClient.Main do
  use GenServer
  alias KeyValueEx.RedisClient.Parser
  alias KeyValueEx.RedisClient.Connection

  require Logger

  # Starts the GenServer
  def start_link(config \\ []) do
    GenServer.start_link(__MODULE__, %{config: config}, name: __MODULE__)
  end

  def init(%{config: config} = state) do
    host = Keyword.get(config, :host)
    port = Keyword.get(config, :port)
    username = Keyword.get(config, :username)
    password = Keyword.get(config, :password)

    Connection.connect(host, port)
    |> case do
      {:ok, socket} ->
        case authenticate(socket, username, password) do
          {:ok, socket} -> {:ok, Map.put(state, :socket, socket)}
          {:error, _} = error -> error
        end

      {:error, msg} ->
        Logger.error("failed to connect redis server because #{inspect(msg)}")
        {:stop, msg}
    end
  end

  def command(command_list) do
    GenServer.call(__MODULE__, {:command, command_list})
  end

  # Server Callbacks
  def handle_call({:command, command_list}, _from, %{socket: socket} = state) do
    response = command(socket, command_list)
    {:reply, response, state}
  end

  def handle_call({:set, key, value}, _from, %{socket: socket} = state) do
    response = set(socket, key, value)
    {:reply, response, state}
  end

  def handle_call({:get, key}, _from, %{socket: socket} = state) do
    response = get(socket, key)
    {:reply, response, state}
  end

  def command(socket, command_list) do
    parsed_command = Parser.build_command(command_list)

    case Connection.send_and_receive(socket, parsed_command) do
      {:ok, raw_response} ->
        {:ok, Parser.parse_response(raw_response)}

      {:error, msg} ->
        {:error, msg}
    end
  end

  def authenticate(_socket, nil, nil), do: :ok

  def authenticate(socket, username, password) do
    command_list =
      if username do
        # Assuming `username` and `password` are always strings.
        ["AUTH", username, password]
      else
        ["AUTH", password]
      end

    command(socket, command_list)
    |> case do
      {:ok, _} -> {:ok, socket}
      {:error, _} = error -> error
    end
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, key, value})
  end

  defp set(socket, key, value) do
    command(socket, ["SET", key, value])
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  defp get(socket, key) do
    command(socket, ["GET", key])
  end
end
