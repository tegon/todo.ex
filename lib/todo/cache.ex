defmodule Todo.Cache do
  use GenServer

  def start_link do
    IO.puts "Starting to-do cache."

    GenServer.start_link(Todo.Cache, nil, name: :todo_cache)
  end

  def server_process(todo_list_name) do
    case Todo.Server.whereis(todo_list_name) do
      :undefined -> GenServer.call(:todo_cache, {:server_process, todo_list_name})
      pid -> pid
    end
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:server_process, todo_list_name}, _, todo_servers) do
    case Todo.Server.whereis(todo_list_name) do
      :undefined ->
        {:ok, new_server} = Todo.ServerSupervisor.start_child(todo_list_name)
        {:reply, new_server, Map.put(todo_servers, todo_list_name, new_server)}
      todo_server ->
        {:reply, todo_server, todo_servers}
    end
  end
end
