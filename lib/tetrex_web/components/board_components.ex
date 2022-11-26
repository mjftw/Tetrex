defmodule TetrexWeb.Components.BoardComponents do
  use TetrexWeb, :component
  alias Tetrex.SparseGrid

  def playfield(assigns) do
    ~H"""
      <div class="playfield">
        <.sparsegrid_fixed sparsegrid={@board.playfield} width={@board.playfield_width} height={@board.playfield_height} />
      </div>
    """
  end

  def next_tile_box(assigns) do
    ~H"""
      <div class="next_tile_box">
        Next tile:
        <.sparsegrid_fixed sparsegrid={@board.next_tile} width={4} height={4} />
      </div>
    """
  end

  def hold_tile_box(assigns) do
    ~H"""
      <div class="hold_tile_box">
        Hold tile:
        <.sparsegrid_fixed sparsegrid={@board.hold_tile || SparseGrid.empty()} width={4} height={4} />
      </div>
    """
  end

  defp sparsegrid_fixed(assigns) do
    ~H"""
      <div class="sparsegrid" style={"--num-columns: #{@width}"}>
        <%= for y <- 0..@height-1, x <- 0..@width-1 do %>
          <div class={@sparsegrid |> SparseGrid.get(y, x) |> tile_class()}/>
        <% end %>
      </div>
    """
  end

  defp tile_class(tile), do: "tetris-tile-" <> tile_class_suffix(tile)
  defp tile_class_suffix(:red), do: "red"
  defp tile_class_suffix(:green), do: "green"
  defp tile_class_suffix(:blue), do: "blue"
  defp tile_class_suffix(:cyan), do: "cyan"
  defp tile_class_suffix(:yellow), do: "yellow"
  defp tile_class_suffix(:purple), do: "purple"
  defp tile_class_suffix(:orange), do: "orange"
  defp tile_class_suffix(:grey), do: "grey"
  defp tile_class_suffix(nil), do: "empty"
end
