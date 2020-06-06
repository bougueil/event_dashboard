defmodule EventDashboard.EventLive do
  use EventDashboard.Web, :live_view
  import EventDashboard.TableHelpers

  alias EventDashboard.SystemInfo

  @sort_by ~w(id at ev)
  @temporary_assigns [log_event_ids: [], total: 0]

  @impl true
  def mount(%{"node" => _} = params, session, socket) do
    {:ok, assign_mount(socket, :event_ids, params, session, true),
     temporary_assigns: @temporary_assigns}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket |> assign_params(params) |> assign_table_params(params, @sort_by) |> fetch_log_event_ids()}
   end

  defp fetch_log_event_ids(socket) do
    %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = socket.assigns.params

    {ids, total} =
      SystemInfo.fetch_log_event_ids(socket.assigns.menu.node, search, sort_by, sort_dir, limit)
  
    assign(socket, log_event_ids: ids, total: total)
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="tabular-page">
      <h5 class="card-title">Events</h5>

      <div class="tabular-search">
        <form phx-change="search" phx-submit="search" class="form-inline">
          <div class="form-row align-items-center">
            <div class="col-auto">
              <input type="search" name="search" class="form-control form-control-sm" value="<%= @params.search %>" placeholder="Search by id or event" phx-debounce="300">
            </div>
          </div>
        </form>
      </div>

      <form phx-change="select_limit" class="form-inline">
        <div class="form-row align-items-center">
          <div class="col-auto">Showing at most</div>
          <div class="col-auto">
            <div class="input-group input-group-sm">
              <select name="limit" class="custom-select" id="limit-select">
                <%= options_for_select(limit_options(), @params.limit) %>
              </select>
            </div>
          </div>
          <div class="col-auto">
            events out of <%= @total %>, last 1h.
          </div>
        </div>
      </form>

  

      <div class="card tabular-card mb-4 mt-4">
        <div class="card-body p-0">
          <div class="dash-table-wrapper">
            <table class="table table-hover mt-0 dash-table clickable-rows">
              <thead>
                <tr>
                  <th class="pl-4">Id</th>
                  <th class="text-right">
                    <%= sort_link(@socket, @live_action, @menu, @params, :at, "At") %>
                  </th>
                  <th class="text-right">
                    <%= sort_link(@socket, @live_action, @menu, @params, :ev, "Event") %>
                  </th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody>
                <%= for table <- @log_event_ids, encoded_ref = encode_event(table[:id], table[:at]) do %>
                  <tr phx-click="show_info" phx-value-ref="<%= encoded_ref %>" phx-page-loading>
                    <td class="tabular-column-name pl-4"><%= table[:id] %></td>
                    <td class="text-right"><%= table[:at] %></td>
                    <td class="text-right"><%= table[:ev] %></td>
                    <td><%= inspect(table[:ev_detail]) %></td>
                   </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:node_redirect, node}, socket) do
    {:noreply, push_redirect(socket, to: self_path(socket, node, socket.assigns.params))}
  end

  def handle_info(:refresh, socket) do
    {:noreply, fetch_log_event_ids(socket)}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    %{menu: menu, params: params} = socket.assigns
    {:noreply, push_patch(socket, to: self_path(socket, menu.node, %{params | search: search}))}
  end

  def handle_event("select_limit", %{"limit" => limit}, socket) do
    %{menu: menu, params: params} = socket.assigns
    {:noreply, push_patch(socket, to: self_path(socket, menu.node, %{params | limit: limit}))}
  end

  def handle_event("show_info", %{"ref" => ref}, socket) do
    params = Map.put(socket.assigns.params, :info, ref)
    |> Map.put(:backend, socket.assigns.menu.backend)
    {:noreply, push_redirect(socket, to: self_path(socket, node(), params))}
  end

  defp self_path(socket, node, params) do
    live_event_path(socket, :event_ids, node, params)
  end

end
