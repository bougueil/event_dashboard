defmodule EventDashboard.Router do
  @moduledoc """
  Provides LiveView routing for LiveDashboard.
  """

  @doc """
  Defines a LiveDashboard route.

  It expects the `path` the dashboard will be mounted at
  and a set of options.

  ## Options

    * `:metrics` - Configures the module to retrieve metrics from.
      It can be a `module` or a `{module, function}`. If nothing is
      given, the metrics functionality will be disabled.

    * `:env_keys` - Configures environment variables to display.
      It is defined as a list of string keys. If not set, the environment
      information will not be displayed.

    * `:live_socket_path` - Configures the socket path. it must match
      the `socket "/live", Phoenix.LiveView.Socket` in your endpoint.

  ## Examples

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import EventDashboard.Router

        scope "/", MyAppWeb do
          pipe_through [:browser]
          live_event "/edb"
        end
      end

  """
  defmacro live_event(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4]

        opts = EventDashboard.Router.__options__(opts)
        live "/", EventDashboard.HomeLive, :home, opts
        live "/:node/home", EventDashboard.HomeLive, :home, opts
        live "/:node/event_ids", EventDashboard.EventLive, :event_ids, opts

        # Catch-all for URL generation
        live "/:node/:page", EventDashboard.HomeLive, :page, opts
      end
    end
  end

  @doc false
  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    backend =
      case options[:backend] do
        nil ->
          nil

        mod when is_atom(mod) ->
          mod
	  
       other ->
          raise ArgumentError,
                ":backend must be a tuple with {Mod, fun}, " <>
                  "such as {MyAppWeb.Telemetry, :backend}, got: #{inspect(other)}"
      end

    env_keys =
      case options[:env_keys] do
        nil ->
          nil

        keys when is_list(keys) ->
          keys

        other ->
          raise ArgumentError,
                ":env_keys must be a list of strings, got: #{inspect(other)}"
      end

    [
      session: {__MODULE__, :__session__, [backend, env_keys]},
      private: %{live_socket_path: live_socket_path},
      layout: {EventDashboard.LayoutView, :dash},
      as: :live_event
    ]
  end

  @doc false
  def __session__(conn, backend, env_keys) do
    %{
      "backend" => backend,
      "env_keys" => env_keys,
      "request_logger" => EventDashboard.RequestLogger.param_key(conn)
    }
  end
end
