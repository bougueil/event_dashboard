Application.put_env(:event_dashboard, EventDashboardTest.Endpoint,
  url: [host: "localhost", port: 4000],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  render_errors: [view: EventDashboardTest.ErrorView],
  check_origin: false,
  pubsub_server: EventDashboardTest.PubSub
)

defmodule EventDashboardTest.ErrorView do
  use Phoenix.View, root: "test/templates"

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule EventDashboardTest.Telemetry do
  import Telemetry.Metrics

  def metrics do
    [
      counter("phx.b.c"),
      counter("phx.b.d"),
      counter("ecto.f.g"),
      counter("my_app.h.i")
    ]
  end
end

defmodule EventDashboardTest.Router do
  use Phoenix.Router
  import EventDashboard.Router

  pipeline :browser do
    plug :fetch_session
  end

  scope "/", ThisWontBeUsed, as: :this_wont_be_used do
    pipe_through :browser
    live_dashboard("/dashboard", metrics: EventDashboardTest.Telemetry)
  end
end

defmodule EventDashboardTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :event_dashboard

  plug EventDashboard.RequestLogger,
    param_key: "request_logger_param_key",
    cookie_key: "request_logger_cookie_key"

  plug Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"

  plug EventDashboardTest.Router
end

Application.ensure_all_started(:os_mon)

Supervisor.start_link(
  [
    {Phoenix.PubSub, name: EventDashboardTest.PubSub, adapter: Phoenix.PubSub.PG2},
    EventDashboardTest.Endpoint
  ],
  strategy: :one_for_one
)

ExUnit.start()
