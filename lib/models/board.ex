defmodule Tetrex.Board do
  alias Tetrex.SparseGrid
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

  @spec new(non_neg_integer(), non_neg_integer(), integer()) :: __MODULE__
  def new(height, width, random_seed) do
    [active_tile_name | [next_tile_name | upcoming_tile_names]] =
      Tetromino.draw_randoms(@tile_bag_size, random_seed)

    %__MODULE__{
      playfield: SparseGrid.new(),
      playfield_height: height,
      playfield_width: width,
      active_tile: Tetromino.fetch!(active_tile_name),
      next_tile: Tetromino.fetch!(next_tile_name),
      hold_tile: nil,
      upcoming_tile_names: upcoming_tile_names
    }
  end

  defp merge_active_tile(board) do
    %{
      board
      | playfield: SparseGrid.merge(board.playfield, board.active_tile)
    }
  end

  @doc """
  Clear all rows that have been completed, shifting the remaining playfield values down to
  fill the gaps.
  Return value is {Board, number_of_lines_cleared}
  """
  @spec clear_completed_rows(__MODULE__) :: {__MODULE__, non_neg_integer()}
  def clear_completed_rows(board) do
    {new_playfield, num_rows_cleared} =
      Enum.reduce(
        0..(board.playfield_height - 1),
        {board.playfield, 0},
        fn row_num, {playfield, num_rows_cleared} ->
          row_start = {row_num, 0}
          row_end = {row_num, board.playfield_width - 1}

          row_is_filled = SparseGrid.filled?(playfield, row_start, row_end)

          case {row_is_filled, row_num} do
            {false, _} ->
              # Row not filled, skip
              {playfield, num_rows_cleared}

            {true, 0} ->
              # Top row is filled, clear it
              new_playfield =
                playfield
                |> SparseGrid.clear(row_start, row_end)

              {new_playfield, num_rows_cleared + 1}

            {true, _} ->
              # Some row is filled, clear it and shift everything above down

              new_playfield =
                playfield
                |> SparseGrid.clear({0, 0}, row_end)
                |> SparseGrid.merge(
                  playfield
                  |> SparseGrid.clear(row_start, row_end)
                  |> SparseGrid.mask({0, 0}, row_end)
                  |> SparseGrid.move(:down, 1)
                )

              {new_playfield, num_rows_cleared + 1}
          end
        end
      )

    {%{board | playfield: new_playfield}, num_rows_cleared}
  end

  @spec draw_next_tile(__MODULE__) :: __MODULE__
  defp draw_next_tile(board) do
    [next_tile_name | upcoming_tile_names] = board.upcoming_tile_names

    %{
      board
      | next_tile: Tetromino.fetch!(next_tile_name),
        upcoming_tile_names: upcoming_tile_names,
        active_tile:
          SparseGrid.align(
            board.next_tile,
            :top_centre,
            {0, 0},
            {board.playfield_height, board.playfield_width}
          )
    }
  end

  @doc """
  Move the active tile down on the playfield by one square.
  If doing so would cause it to collide with tiles on the playfield or it's at the bottom then fix
  the active_tile to the playfield and draw a new one.
  If fixing the active_tile to the playfield results in completed rows, these rows are cleared.
  The return value is a {new_board, number_of_rows_cleared}
  """
  @spec move_active_down(__MODULE__) :: {__MODULE__, non_neg_integer()}
  def move_active_down(board) do
    case move_active_if_legal(board, &SparseGrid.move(&1, {1, 0})) do
      # Moved active tile down without a collision
      {:ok, new_board} ->
        {new_board, 0}

      {:error, error} when error in [:collision, :out_of_bounds] ->
        # Could not move active tile down, fix in place, draw a new tile, and clear any filled rows
        board
        |> merge_active_tile()
        |> draw_next_tile()
        |> clear_completed_rows()
    end
  end

  @doc """
  Move the active_tile left on the playfield by one square.
  If doing so would result in a collision or the tile moving off the board the tile is not moved.
  """
  @spec move_active_left(__MODULE__) :: __MODULE__
  def move_active_left(board), do: move_active_sideways(board, -1)

  @doc """
  Move the active_tile right on the playfield by one square.
  If doing so would result in a collision or the tile moving off the board the tile is not moved.
  """
  @spec move_active_right(__MODULE__) :: __MODULE__
  def move_active_right(board), do: move_active_sideways(board, 1)

  @doc """
  Move the active tile into the hold slot.
  If the hold slot was empty a new tile is drawn.
  If hold slot was full, swap the hold and active tiles
  If swapping the hold and active tiles is not possible due to a collision, do not swap.
  """
  @spec hold_active(__MODULE__) :: __MODULE__
  def hold_active(board) do
    # Compute lazily as not needed in all branches
    active_at_origin = fn -> SparseGrid.align(board.active_tile, :top_left, {0, 0}, {0, 0}) end

    case board.hold_tile do
      nil ->
        # No hold tile, put active in hold slot and draw new active
        %{board | hold_tile: active_at_origin.()}
        |> draw_next_tile()

      _ ->
        # Swap the active and hold tiles
        case move_active_if_legal(
               board,
               fn _ -> SparseGrid.align(board.hold_tile, :top_centre, board.active_tile) end
             ) do
          {:ok, new_board} ->
            # hold tile fits on board
            %{new_board | hold_tile: active_at_origin.()}

          {:error, error} when error in [:collision, :out_of_bounds] ->
            # hold tile does not fit on board
            board
        end
    end
  end

  @doc """
  Attempt to rotate the active tile clockwise, first 90 degrees clockwise, then 180, then 270.
  If a rotation would cause a collision the next is tried.
  If no rotation is possible then the board is returned unchanged.
  """
  @spec rotate_active(__MODULE__) :: __MODULE__
  def rotate_active(board) do
    # Keep attempting to rotate until it works, or every rotation has been tried and failed
    result =
      with {:error, _} <-
             move_active_if_legal(board, &Tetrex.SparseGrid.rotate(&1, :clockwise90)),
           {:error, _} <-
             move_active_if_legal(board, &Tetrex.SparseGrid.rotate(&1, :clockwise180)),
           {:error, _} <-
             move_active_if_legal(board, &Tetrex.SparseGrid.rotate(&1, :clockwise270)),
           do: :could_not_rotate

    case result do
      {:ok, new_board} -> new_board
      :could_not_rotate -> board
    end
  end

  @doc """
  Apply a transform function to the active tile, checking that doing so would
  cause it to collide with the playfield or be outside the playfield.
  """
  @spec move_active_if_legal(
          __MODULE__,
          (SparseGrid.sparse_grid() -> SparseGrid.sparse_grid())
        ) :: {:ok, __MODULE__} | {:error, placement_error()}
  def move_active_if_legal(board, transform_fn) do
    candidate_placement = transform_fn.(board.active_tile)

    collides_with_playfield = SparseGrid.overlaps?(candidate_placement, board.playfield)

    on_playfield =
      SparseGrid.within_bounds?(
        candidate_placement,
        {0, 0},
        {board.playfield_height - 1, board.playfield_width - 1}
      )

    cond do
      collides_with_playfield -> {:error, :collision}
      !on_playfield -> {:error, :out_of_bounds}
      true -> {:ok, %{board | active_tile: candidate_placement}}
    end
  end

  @doc """
  Build the flattened preview of the Board.
  This preview contains everything needed for a front end to display the Board.
  """
  @spec preview(__MODULE__) :: %{
          playfield: SparseGrid.t(),
          next_tile: SparseGrid.t(),
          hold_tile: SparseGrid.t(),
          active_tile_fits: boolean()
        }
  def preview(board) do
    case SparseGrid.overlaps?(board.active_tile, board.playfield) do
      false ->
        %{
          playfield: SparseGrid.merge(board.playfield, board.active_tile),
          next_tile: board.next_tile,
          hold_tile: board.hold_tile,
          active_tile_fits: true
        }

      true ->
        new_board = move_active_up_until_fits(board)

        %{
          playfield: SparseGrid.merge(new_board.playfield, new_board.active_tile),
          next_tile: new_board.next_tile,
          hold_tile: new_board.hold_tile,
          active_tile_fits: false
        }
    end
  end

  defp move_active_up_until_fits(board) do
    case SparseGrid.overlaps?(board.active_tile, board.playfield) do
      false ->
        board

      true ->
        %{
          board
          | active_tile:
              board.active_tile
              |> SparseGrid.move({-1, 0})
              |> SparseGrid.mask({0, 0}, {board.playfield_height - 1, board.playfield_width - 1})
        }
        |> move_active_up_until_fits()
    end
  end

  defp move_active_sideways(board, x_translation) do
    case move_active_if_legal(board, &SparseGrid.move(&1, {0, x_translation})) do
      {:ok, new_board} -> new_board
      {:error, error} when error in [:collision, :out_of_bounds] -> board
    end
  end
end
