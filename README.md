# EventDashboard

			 

<!-- MDOC !-->

A Phoenix LiveView app.

EventDashboard allows to visualize, display statistics and do multi-variables queries on events.

Events are added to the dashboard (in memory, for a configured time) like this:

```elixir

%EventDashboard{
           id: "vehicle_1",              # binary, the source of the event
      	   at: DateTime.utc_now(),       # must support inspect(timestamp)
	   ev: "ALARM_1",                # binary, the event name
	   ev_detail: %{km_maint: -133}  # map,
  } |> EventDashboard.add()


```

![screenshot](https://github.com/bougueil/event_dashboard/raw/master/screenshot.png)

## Installation

To start using EventDashboard, you will need three steps:

  1. Add the `event_dashboard` dependency
  2. Configure EventDashboard, like Phoenix LiveDashboard 
  3. Add dashboard access

### 1. Add the `phoenix_live_dashboard` dependency

Add the following to your `mix.exs` and run `mix deps.get`:

```elixir
def deps do
  [
    {:event_dashboard, git: "git://github.com/bougueil/event_dashboard"}
  ]
end
```

### 2. Configure EventDashboard

add in config.ex the time in ms for an event to stay in EventDashboard.

default is 30 minutes.

```elixir
# config.ex

config :event_dashboard,
  ttl_ms: :timer.minutes(60)
```

### 3. Add event dashboard access

EventDashboard routing scheme is similar to the one of Phoenix LiveDashboard

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router
import EventDashboard.Router

...

scope "/" do
  pipe_through :browser
  live_event "/edb"
end
```

This is all. Run mix phx.server and access the "/edb" for live events.

EventDashboard may be filled with demo events like this:

```elixir
EventDashboard.test()
```

<!-- MDOC !-->
