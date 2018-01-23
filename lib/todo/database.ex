defmodule Todo.Database do
  use GenServer

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder, name: :database_server)
  end

  def store(key, data) do
    pid = GenServer.call(:database_server, {:get_worker, key})
    IO.puts "#{inspect(pid)}: storing #{key}"
    GenServer.cast(pid, {:store, key, data})
  end

  def get(key) do
    pid = GenServer.call(:database_server, {:get_worker, key})
    IO.puts "#{inspect(pid)}: getting #{key}"
    GenServer.call(pid, {:get, key})
  end

  def init(db_folder) do
    File.mkdir_p(db_folder)
    {:ok, worker_one} = Todo.DatabaseWorker.start(db_folder)
    {:ok, worker_two} = Todo.DatabaseWorker.start(db_folder)
    {:ok, worker_three} = Todo.DatabaseWorker.start(db_folder)
    workers = %{0 => worker_one, 1 => worker_two, 2 => worker_three}
    {:ok, {db_folder, workers}}
  end

  def handle_call({:get_worker, key}, _, {db_folder, workers}) do
    worker = Map.get(workers, :erlang.phash2(key, 3))
    {:reply, worker, {db_folder, workers}}
  end
end
