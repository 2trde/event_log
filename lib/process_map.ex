defmodule EventLog.ProcessMap do
  use GenServer

  def start(key) do
    GenServer.cast(__MODULE__, {:start, self(), key})
    :ok
  end

  def finish() do
    GenServer.cast(__MODULE__, {:finish, self()})
  end

  def get_key() do
    GenServer.call(__MODULE__, {:get_key, self()})
  rescue
    _ -> nil
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:start, proc, key}, acc) do
    {:noreply, Map.put(acc, proc, key)}
  end

  @impl true
  def handle_cast({:finish, proc}, acc) do
    {:noreply, Map.delete(acc, proc)}
  end

  @impl true
  def handle_call({:get_key, proc}, _, acc) do
    {:reply, Map.get(acc, proc), acc}
  end

  def _now(), do: :erlang.system_time / 1_000_000
end
