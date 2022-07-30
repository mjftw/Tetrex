defmodule Tetrex.Board do
  alias Tetrex.SparseGrid
  alias Tetrex.Tetromino

  @tile_bag_size 9999

  @enforce_keys [
    :playfield,
    :playfield_height,
    :playfield_width,
    :current_tile,
    :next_tile,
    :hold_tile,
    :upcoming_tiles
  ]
  defstruct [
    :playfield,
    :playfield_height,
    :playfield_width,
    :current_tile,
    :next_tile,
    :hold_tile,
    :upcoming_tiles
  ]

  @spec new(non_neg_integer(), non_neg_integer(), integer()) :: __MODULE__.t()
  def new(height, width, random_seed) do
    [current_tile | [next_tile | upcoming_tiles]] =
      Tetromino.draw_randoms(@tile_bag_size, random_seed)

    %__MODULE__{
      playfield: SparseGrid.new(),
      playfield_height: height,
      playfield_width: width,
      current_tile: current_tile,
      next_tile: next_tile,
      hold_tile: nil,
      upcoming_tiles: upcoming_tiles
    }
  end
end
