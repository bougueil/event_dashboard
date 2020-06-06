defmodule EventDashboard do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)
  
  # Structure of an event
  @enforce_keys ~w(id at ev)a
  @type t :: %__MODULE__{id: String.t(), at: DateTime.t(), ev: String.t(), ev: map()}
  defstruct id: nil, at: nil, ev: nil, ev_detail: %{}

  @doc """
  Add an EventDashboard to the EventDashboard.

  An %EventDashboard is has the required fields:

  - id          # binary, the source of the event,  {id, at} should be unique
  - at          # a DateTime, 
  - ev          # the event name
  - ev_detail   # a map containing detail of the event, default to %{}


  Example:
  
  %EventDashboard{ 
      id: "vehicle_1",            
      at: DateTime.utc_now(),
      ev: "ALARM_1",
      ev_detail: %{km_maint: -133}
  } 
  |> EventDashboard.add()

  The event is retained for some configured time (ttl) before being discarded.
  """
  def add(%EventDashboard{id: id, at: at} = event) do
    Memory.Event.put "#{id} #{at}", Map.to_list(event)
  end

  def test() do
    num = 10_154
    for i <- 1..num do
      %EventDashboard{
	id: "vehicle_#{round(5*:math.log(i))}",
	at: DateTime.utc_now(),
	ev: "ALARM_#{round(:math.log(Enum.random(1..200)))}",
	ev_detail: %{km_maint: -Enum.random(1..10_000) }
      }
      |> EventDashboard.add()
    end
    IO.puts "#{num} events added."
  end
end
