defmodule EventDashboard.MenuLive do
  use EventDashboard.Web, :live_view

  @default_refresh 5
  @supported_refresh [{"1s", 1}, {"2s", 2}, {"5s", 5}, {"15s", 15}, {"30s", 30}]

  @impl true
  def mount(_, %{"menu" => menu}, socket) do
    socket = assign(socket, menu: menu, node: menu.node, refresh: @default_refresh)
    socket = validate_nodes_or_redirect(socket)

    if connected?(socket) do
      :net_kernel.monitor_nodes(true, node_type: :all)
    end

    {:ok, init_schedule_refresh(socket)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <nav id="menu-bar">
      <%= maybe_active_live_redirect @socket, @menu, "Home", :home, @node %>
      <%= maybe_active_live_redirect @socket, @menu, "Live", :event_ids, @node %>
    </nav>

    <div id="refresher">
      <form phx-change="select_refresh">
        <div class="input-group input-group-sm">
          <%= if @menu.refresher? do %>
            <div class="input-group-prepend">
              <label class="input-group-text" for="refresh-interval-select">Update every</label>
            </div>
            <select name="refresh" class="custom-select" id="refresh-interval-select">
              <%= options_for_select(refresh_options(), @refresh) %>
            </select>
          <% else %>
            <div class="input-group-prepend">
              <small class="input-group-text text-muted">Updates automatically</small>
            </div>
          <% end %>
        </div>
      </form>
    </div>
    """
  end

  defp refresh_options() do
    @supported_refresh
  end

  defp maybe_active_live_redirect(socket, menu, text, page, node) do
    if menu.page == page do
      content_tag(:div, text, class: "menu-item active")
    else
      live_redirect(text, to: live_event_path(socket, page, node), class: "menu-item")
    end
  end

  @impl true
  def handle_info({:nodeup, _, _}, socket) do
    {:noreply, assign(socket, nodes: nodes())}
  end

  def handle_info({:nodedown, _, _}, socket) do
    {:noreply, validate_nodes_or_redirect(socket)}
  end

  def handle_info(:refresh, socket) do
    send(socket.root_pid, :refresh)
    {:noreply, schedule_refresh(socket)}
  end

  @impl true
  def handle_event("select_node", params, socket) do
    param_node = params["node"]
    node = Enum.find(nodes(), &(Atom.to_string(&1) == param_node))

    if node && node != socket.assigns.node do
      send(socket.root_pid, {:node_redirect, node})
      {:noreply, socket}
    else
      {:noreply, redirect_to_current_node(socket)}
    end
  end

  def handle_event("select_refresh", params, socket) do
    case Integer.parse(params["refresh"]) do
      {refresh, ""} -> {:noreply, assign(socket, refresh: refresh)}
      _ -> {:noreply, socket}
    end
  end

  ## Refresh helpers

  defp init_schedule_refresh(socket) do
    if connected?(socket) and socket.assigns.menu.refresher? do
      schedule_refresh(socket)
    else
      assign(socket, timer: nil)
    end
  end

  defp schedule_refresh(socket) do
    assign(socket, timer: Process.send_after(self(), :refresh, socket.assigns.refresh * 1000))
  end

  ## Node helpers

  defp validate_nodes_or_redirect(socket) do
    if socket.assigns.node not in nodes() do
      socket
      |> put_flash(:error, "Node #{socket.assigns.node} disconnected.")
      |> redirect_to_current_node()
    else
      assign(socket, nodes: nodes())
    end
  end

  defp redirect_to_current_node(socket) do
    push_redirect(socket, to: live_event_path(socket, :home, node()))
  end
end
