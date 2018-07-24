defmodule Todo.Web do
  use Plug.Router

  plug :match
  plug :dispatch

  def start_server do
    case Application.get_env(:todo, :port) do
      nil -> raise("Todo port not specified")
      port -> Plug.Adapters.Cowboy.http(__MODULE__, nil, port: port)
    end
  end

  post "/add_entry" do
    conn
    |> Plug.Conn.fetch_query_params
    |> add_entry
    |> respond
  end

  get "/entries" do
    conn
    |> Plug.Conn.fetch_query_params
    |> entries
    |> respond
  end

  defp add_entry(conn) do
    conn.params["list"]
    |> Todo.Cache.server_process
    |> Todo.Server.add_entry(
      %{
        date: parse_date(conn.params["date"]),
        title: conn.params["title"]
      }
    )

    Plug.Conn.assign(conn, :response, "OK")
  end

  defp entries(conn) do
    entries =
      conn.params["list"]
      |> Todo.Cache.server_process
      |> Todo.Server.entries(parse_date(conn.params["date"]))

    response = Enum.map(entries, fn (entry) -> entry_to_string(entry) end)

    Plug.Conn.assign(conn, :response, response)
  end

  defp respond(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, conn.assigns[:response])
  end

  defp parse_date(string) do
    {year, month_and_day} = String.split_at(string, 4)
    {month, day} = String.split_at(month_and_day, 2)
    {year, month, day}
  end

  defp entry_to_string(entry) do
    "#{elem(entry.date, 0)}-#{elem(entry.date, 1)}-#{elem(entry.date, 2)}    #{entry.title}\n"
  end
end
