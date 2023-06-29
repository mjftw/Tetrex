defmodule TetrexWeb.Components.Client.Touch do
  use TetrexWeb, :live_component

  attr :id, :string, required: true
  slot :inner_block, required: true

  def touch_events(assigns) do
    ~H"""
    <span class="h-full w-full" id={@id} phx-hook="Touch">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
