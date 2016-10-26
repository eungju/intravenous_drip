defmodule Webhook do
  def start_link() do
    GenEvent.start_link([name: __MODULE__])
  end

  def stop() do
    GenEvent.stop(__MODULE__)
  end

  def event(event) do
    GenEvent.notify(__MODULE__, {:event, event})
  end
end
