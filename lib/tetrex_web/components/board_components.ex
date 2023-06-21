defmodule TetrexWeb.Components.BoardComponents do
  use TetrexWeb, :live_component
  alias Tetrex.SparseGrid
  alias TetrexWeb.Components.Board.SparseGridFixed

  def playfield(assigns) do
    ~H"""
    <div class="playfield">
      <SparseGridFixed.render
        sparsegrid={@board.playfield}
        width={@board.playfield_width}
        height={@board.playfield_height}
      />
    </div>
    """
  end

  def score_box(assigns) do
    ~H"""
    <div class="score-box">
      Score: <%= @score %>
    </div>
    """
  end

  def next_tile_box(assigns) do
    ~H"""
    <div class="tile-box">
      Next
      <SparseGridFixed.render sparsegrid={centre_single_tile(@board.next_tile)} width={4} height={4} />
    </div>
    """
  end

  def hold_tile_box(assigns) do
    ~H"""
    <div class="tile-box">
      Hold
      <SparseGridFixed.render
        sparsegrid={centre_single_tile(@board.hold_tile || SparseGrid.empty())}
        width={4}
        height={4}
      />
    </div>
    """
  end

  def multiplayer_game(assigns) do
    ~H"""
    <div
      class="multiplayer-game"
      style={"--background-color: " <> if assigns[:is_dead], do: "grey", else: "antiquewhite"}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp centre_single_tile(tile), do: SparseGrid.align(tile, :centre, {0, 0}, {3, 3})
end
