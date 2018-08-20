defmodule Todo.SystemSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    processes = [
      supervisor(Todo.Database, ["./#{node_name()}/persist"]),
      supervisor(Todo.ServerSupervisor, [])
    ]
    supervise(processes, strategy: :one_for_one)
  end

  defp node_name do
    Node.self |> Atom.to_string |> String.split("@") |> List.first
  end
end
