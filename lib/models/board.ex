defmodule Tetrex.Board do
  alias Tetrex.SparseGrid
  alias Tetrex.LazySparseGrid
  alias Tetrex.Tetromino

  @type placement_error :: :collision | :out_of_bounds

  @tile_bag_size 9999

  @enforce_keys [
    :playfield,
    :playfield_height,
    :playfield_width,
    :active_tile,
    :next_tile,
    :hold_tile,
    :upcoming_tile_names
  ]
  defstruct [
    :playfield,
    :playfield_height,
    :playfield_width,
    :active_tile,
    :next_tile,
    :hold_tile,
    :upcoming_tile_names
  ]

  @spec new(non_neg_integer(), non_neg_integer(), integer()) :: __MODULE__.t()
  def new(height, width, random_seed) do
    [active_tile_name | [next_tile_name | upcoming_tile_names]] =
      Tetromino.draw_randoms(@tile_bag_size, random_seed)

    %__MODULE__{
      playfield: SparseGrid.new(),
      playfield_height: height,
      playfield_width: width,
      active_tile: Tetromino.tetromino!(active_tile_name),
      next_tile: Tetromino.tetromino!(next_tile_name),
      hold_tile: nil,
      upcoming_tile_names: upcoming_tile_names
    }
  end

  @doc """
  Attempt to place the next tile on the board.
  An error is returned if the tile could no be placed due to the board already being full.
  """
  @spec place_next_tile(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, placement_error()}
  def place_next_tile(board) do
    candidate_placement =
      SparseGrid.align(
        board.next_tile,
        {0, 0},
        {board.playfield_height, board.playfield_width},
        :top_centre
      )

    cond do
      SparseGrid.overlaps?(candidate_placement, board.playfield) ->
        {:error, :collision}

      true ->
        [next_tile_name | upcoming_tile_names] = board.upcoming_tile_names

        {:ok,
         %{
           board
           | active_tile: board.next_tile,
             next_tile: Tetromino.tetromino!(next_tile_name),
             upcoming_tile_names: upcoming_tile_names
         }}
    end
  end

  @doc """
  Apply a transform function to the active tile, checking that doing so would
  cause it to collide with the playfield or be outside the playfield.
  """
  @spec move_active_if_legal(
          __MODULE__.t(),
          (SparseGrid.sparse_grid() -> SparseGrid.sparse_grid())
        ) :: {:ok, __MODULE__.t()} | {:error, placement_error()}
  def move_active_if_legal(board, transform_fn) do
    candidate_placement = transform_fn.(board.active_tile)

    collides_with_playfield = SparseGrid.overlaps?(candidate_placement, board.playfield)

    on_playfield =
      SparseGrid.within_bounds?(
        candidate_placement,
        {0, 0},
        {board.playfield_height, board.playfield_width}
      )

    cond do
      collides_with_playfield -> {:error, :collision}
      !on_playfield -> {:error, :out_of_bounds}
      true -> {:ok, %{board | active_tile: candidate_placement}}
    end
  end
end
