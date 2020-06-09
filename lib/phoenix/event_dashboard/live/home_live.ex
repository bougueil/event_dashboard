defmodule EventDashboard.HomeLive do
  use EventDashboard.Web, :live_view

  alias EventDashboard.{
    SystemInfo,
    ColorBarComponent,
    ColorBarLegendComponent
  }

  @temporary_assigns [system_info: nil, system_usage: nil, common_events: nil, common_log_event_ids: nil]

  @versions_sections [
    {:elixir, "Total Events"},
    {:phoenix, "Largest Event"},
    {:dashboard, "Least Event"}
  ]

  @common_colors ["purple", "blue",  "green", "orange", "yellow", "dark-gray",
		  "purple", "blue",  "green", "orange"]


  @impl true
  def mount(%{"node" => _} = params, session, socket) do
    socket = assign_mount(socket, :home, params, session, true)

    %{
      # Read once
      system_info: system_info,
      backend: backend,
      # Kept forever
      system_limits: system_limits,
      # Updated periodically
      common_events: common_events,
      common_log_event_ids: common_log_event_ids,
      system_usage: system_usage
    } = SystemInfo.fetch_system_info(socket.assigns.menu.node, session["backend"])

    socket =
      assign(socket,
        system_info: system_info,
        system_limits: system_limits,
        system_usage: system_usage,
	common_events: common_events,
	common_log_event_ids: common_log_event_ids,
	events_rate: "-",
        backend: backend
      )

    {:ok, _} = Registry.register(EventDashboard.Registry, "edb", [])
    {:ok, socket, temporary_assigns: @temporary_assigns}
  end

  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: live_event_path(socket, :home, node()))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign_params(socket, params)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="row">
      <!-- Left column with system/version information -->
      <div class="col-sm-6">
        <h5 class="card-title">System information</h5>

        <div class="card mb-4">
          <div class="card-body rounded">
            <%= @system_info.banner %> [<%= @system_info.system_architecture %>]
          </div>
        </div>

        <!-- Row with colorful version banners -->
        <div class="row">

         <div class="col-lg-4 mb-4">
            <div class="banner-card">
              <h6 class="banner-card-title">Uptime
                <%= hint do %>
                  Time this dashboard is running.
                <% end %>
	      </h6>
              <div class="banner-card-value"><%= format_uptime(@system_usage.uptime) %></div>
            </div>
          </div>

          <div class="col-lg-4 mb-4">
            <div class="banner-card">
              <h6 class="banner-card-title">
                Events rate
                <%= hint do %>
                  Percentage of events in this dasboard to the total of events of the application. <br>Provided by the application.
                <% end %>
              </h6>
              <div class="banner-card-value"><%= @events_rate %></div>
            </div>
          </div>

        </div>

        <h5 class="card-title">Events information last <%= format_ttl(@system_info.ttl) %></h5>
        <!-- Row with colorful version banners -->
        <div class="row">
          <%= for {section, title} <- versions_sections() do %>
            <div class="col mb-4">
              <div class="banner-card bg-<%= section %> text-white">
                <h6 class="banner-card-title"><%= title %></h6>
                <div class="banner-card-value"><%= @common_events[section] %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Right column containing error usage information -->
      <div class="col-sm-6">
        <h5 class="card-title">
          Top 10 events
        </h5>

        <div class="card mb-4">
          <div class="card-body resource-usage">
            <%= live_component @socket, ColorBarComponent, data: events_usage_sections_percent(@common_events, @common_events.common_size) %>
            <%= live_component @socket, ColorBarLegendComponent, data: events_usage_sections(@common_events), formatter: &(&1) %>
            <div class="row">
              <div class="col">
                <div class="resource-usage-total text-center py-1 mt-3">
                  Total diff. events last <%= format_ttl(@system_info.ttl) %> : <%= @common_events[:total] %>
                </div>
              </div>
            </div>
          </div>
        </div>

        <h5 class="card-title">
          Top 10 event sources
        </h5>

        <div class="card resource-usage mb-4">
          <div class="card-body">
            <%= live_component @socket, ColorBarComponent, data: ids_usage_sections_percent(@common_log_event_ids, @common_log_event_ids.common_size) %>
            <%= live_component @socket, ColorBarLegendComponent, data: ids_usage_sections(@common_log_event_ids), formatter: &(&1) %>
            <div class="row">
              <div class="col">
                <div class="resource-usage-total text-center py-1 mt-3">
                  Total diff. event sources last <%= format_ttl(@system_info.ttl) %> : <%= @common_log_event_ids[:total] %>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
    """
  end

  defp events_usage_sections_percent(ids_usage, total) do
   ids_usage
    |> events_usage_sections()
    |> Enum.map(fn {n, value, c, desc} ->
    {n, percentage(value, total), c, desc}
    end)
  end

  defp events_usage_sections(ids_usage) do
      ids_usage |> Map.drop([:elixir, :phoenix, :dashboard, :total, :common_size])
    |> Enum.reduce({[], @common_colors}, fn {id, value}, {acc, [col|rest]} ->
      {[{id, value, col, nil}|acc], rest}
    end) |> elem(0)    
  end

  
  defp ids_usage_sections_percent(ids_usage, total) do
   ids_usage
    |> ids_usage_sections()
    |> Enum.map(fn {n, value, c, desc} ->
    {n, percentage(value, total), c, desc}
    end)
  end

  defp ids_usage_sections(ids_usage) do
    ids_usage |> Map.drop([:elixir, :phoenix, :dashboard, :total, :common_size])
    |> Enum.reduce({[], @common_colors}, fn {name, value}, {acc, [col|rest]} -> 
      {[{name, value, col, nil}|acc], rest}
    end) |> elem(0)    
  end

  @impl true
  def handle_info({:node_redirect, node}, socket) do
    {:noreply, push_redirect(socket, to: live_event_path(socket, :home, node))}
  end

  def handle_info(:refresh, socket) do
    {:noreply,
     assign(socket, system_usage: SystemInfo.fetch_system_usage(socket.assigns.menu.node),
       common_events: SystemInfo.fetch_common_events(socket.assigns.menu.node),
       common_log_event_ids: SystemInfo.fetch_log_event_ids(socket.assigns.menu.node)
     )}
  end

  def handle_info({:broadcast, %{events_rate: percent}}, socket) when is_float(percent) do
    {:noreply, assign(socket, events_rate: "#{Float.round(percent, 1)}%")}
  end

  defp versions_sections(), do: @versions_sections
end
