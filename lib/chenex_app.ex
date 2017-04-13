defmodule ChenEx.App do
  use Application
  def start(_type, _args) do
    Supervisor.start_link([
                            Plug.Adapters.Cowboy.child_spec(:http, ChenEx.HTTP,[], port: 4242),
                          ], strategy: :one_for_one)
  end
end

defmodule ChenEx.API.Exceptions do
  defmacro __using__(_opts) do
    quote do @before_compile ChenEx.API.Exceptions end
  end
  defmacro __before_compile__(_) do
    quote location: :keep do
      defoverridable [call: 2]
      def call(conn, opts) do
        try do
          super(conn, opts)
        catch
          kind, reason ->
            stack = System.stacktrace
            reason = Exception.normalize(kind, reason, stack)
          status = case kind do x when x in [:error,:throw]-> Plug.Exception.status(reason); _-> 500 end
            conn |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(status,Poison.encode!(%{state: "exception", reason: Exception.message(reason), trace: Exception.format(kind,reason,stack)}))
            :erlang.raise kind,reason,stack
        end
      end
    end
  end
end

defmodule ChenEx.API.Common do
  use Ewebmachine.Builder.Handlers
  plug :add_handlers
  content_types_provided do: ["application/json": :to_json]
  defh to_json, do: Poison.encode!(state[:json_obj])
end

defmodule ChenEx.ErrorRoutes do
  use Ewebmachine.Builder.Resources
  resources_plugs

  resource "/error/:status" do %{s: elem(Integer.parse(status), 0)} after 
    content_types_provided do: ['text/html': :to_html, 'application/json': :to_json]
    defh to_html, do: "<h1> Error ! : '#{Ewebmachine.Core.Utils.http_label(state.s)}'</h1>"
    defh to_json, do: ~s/{"error": #{state.s}, "label": "#{Ewebmachine.Core.Utils.http_label(state.s)}"}/
    finish_request do: {:halt, state.s}
  end
end

defmodule ChenEx.HTTP do
  use Plug.Router
  require Logger
  plug Ewebmachine.Plug.Debug
  plug Plug.Logger
  plug :fetch_cookies
  plug :fetch_query_params
  plug :match
  plug :dispatch

  match "/.well-known/*_", do: ChenEx.WebFinger.API.call(conn, ChenEx.WebFinger.API.init(%{}))
  match "/api/v1/*_", do: ChenEx.API.HTTP.call(conn, ChenEx.API.HTTP.init(%{}))
  match _, do: conn |> send_resp(404, "Not Found")
end
