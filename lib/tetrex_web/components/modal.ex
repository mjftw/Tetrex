defmodule TetrexWeb.Components.Modal do
  use TetrexWeb, :live_component

  def modal(assigns) do
    ~H"""
      <div class="modal" style={"display: " <> if assigns[:show], do: "flex", else: "none"}>
        <%= render_slot(@inner_block) %>
      </div>
    """
  end
end
