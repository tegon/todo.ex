defmodule Todo.ProcessRegistry do
  import Kernel, except: [send: 2]
  use GenServer

  def start_link do
    IO.puts "Starting process registry"

    GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def register_name(key, pid) do
    GenServer.call(:process_registry, {:register_name, key, pid})
  end

  def unregister_name(key) do
    GenServer.cast(:process_registry, {:unregister_name, key})
  end

  def whereis_name(key) do
    case :ets.lookup(:process_registry, key) do
      [{^key, value}] -> value
      _ -> :undefined
    end
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined -> {:badarg, {key, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def init(_) do
    :ets.new(:process_registry, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def handle_call({:register_name, key, pid}, _from, state) do
    Process.monitor(pid)
    :ets.insert(:process_registry, {key, pid})
    {:reply, :yes, state}
  end

  def handle_cast({:unregister_name, key}, state) do
    :ets.delete(:process_registry, key)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    deregister_pid(pid)
    {:noreply, state}
  end

  defp deregister_pid(pid) do
    :ets.match_delete(:process_registry, {:_, pid})
  end
end
