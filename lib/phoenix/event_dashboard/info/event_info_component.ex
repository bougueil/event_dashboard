defmodule EventDashboard.EventInfoComponent do
  use EventDashboard.Web, :live_component

  alias EventDashboard.SystemInfo

  @info_keys [
    :id,
    :at,
    :ev,
    :ev_detail
  ]

  @impl true
  def render(assigns) do
    ~L"""
    <div class="tabular-info">
      <%= if @alive do %>
        <table class="table tabular-table-info-table">
          <tbody>
            <tr><td class="border-top-0">ID</td><td class="border-top-0"><pre><%= @id %></pre></td></tr>
            <tr><td>At</td><td><pre><%= @at %></pre></td></tr>
           <tr><td>Event</td><td><pre><%= @ev %></pre></td></tr>
           <tr><td>Detail</td><td><pre><%= @ev_detail %></pre></td></tr>
          </tbody>
        </table>
      <% else %>
        <div class="tabular-info-not-exists mt-1 mb-3">Event does not exist.</div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, Enum.reduce(@info_keys, socket, &assign(&2, &1, nil))}
  end

  @impl true
  def update(%{id: ref, path: path, return_to: return_to, node: node}, socket) do
    [_,backend] =  String.split(return_to, "event_ids?")
    backend = URI.decode_query(backend)["backend"] |> String.to_atom()
    {:ok, socket |> assign(ref: ref, backend: backend, path: path, node: node) |> assign_info()}
  end

  defp assign_info(%{assigns: assigns} = socket) do
    case SystemInfo.fetch_log_event_ids_info(socket.assigns.node, assigns.ref) do
      {:ok, info} ->
        Enum.reduce(info, socket, fn {key, val}, acc ->
          assign(acc, key, format_info(key, val, assigns.path))
        end)
        |> assign(alive: true)

      :error ->
        assign(socket, alive: false)
    end
  end

  defp format_info(_key, val, live_event_path), do: format_value(val, live_event_path)
end
