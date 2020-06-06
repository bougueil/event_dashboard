defmodule Memory.Event do
  @moduledoc """
  Simple wrapper of :redi api
  """
  @memory_bank :redi
  alias :redi, as: Redi 
  
  
  def size(), do: Redi.size @memory_bank

  def all(), do: Redi.all @memory_bank

  def put(key, val), do: Redi.set @memory_bank, key, val

  def get(key),do: Redi.get @memory_bank, key

  def child_spec(ttl_ms) do
        {:redi,
         [:redi,  # process name
           %{bucket_name: @memory_bank, entry_ttl_ms: ttl_ms} ]
	}
  end
end
