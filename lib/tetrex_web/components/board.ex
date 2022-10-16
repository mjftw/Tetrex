defmodule TetrexWeb.Components.Board do
  use TetrexWeb, :component

  def playfield(assigns) do
    ~H"""
    <div class="playfield">
      <h2>Playfield component</h2>
    </div>
    """
  end
end
