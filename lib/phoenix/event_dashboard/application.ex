defmodule EventDashboard.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    Logger.add_backend(EventDashboard.LoggerPubSubBackend)
    ttl_ms = Application.get_env(:event_dashboard, :ttl_ms, :timer.minutes(30))

    children = [
      Memory.Event.child_spec(ttl_ms),
      {DynamicSupervisor, name: EventDashboard.DynamicSupervisor, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
