defmodule Tetrex.Board.Test do
  use ExUnit.Case

  alias Tetrex.Board

  test "new/3 creates a specific board given a specific seed" do
    board = Tetrex.Board.new(20, 10, 3_141_592_654)

    upcoming = Enum.take(board.upcoming_tile_names, 10)

    expected = %{
      playfield: Tetrex.SparseGrid.new(),
      playfield_height: 20,
      playfield_width: 10,
      active_tile: Tetrex.Tetromino.tetromino!(:t),
      next_tile: Tetrex.Tetromino.tetromino!(:s),
      hold_tile: nil
    }

    expected_upcoming = [:t, :l, :z, :o, :t, :o, :l, :l, :o, :z]

    assert board.playfield == expected.playfield
    assert board.playfield_height == expected.playfield_height
    assert board.playfield_width == expected.playfield_width
    assert board.active_tile == expected.active_tile
    assert board.next_tile == expected.next_tile
    assert board.hold_tile == expected.hold_tile
    assert upcoming == expected_upcoming
  end

  test "place_next_tile/1 should change the current tile when no overlap would occur" do
    board = %{
      Board.new(5, 5, 0)
      | next_tile: Tetrex.Tetromino.tetromino!(:t),
        upcoming_tile_names: [:i, :o, :s]
    }

    expected = %{
      board
      | active_tile: Tetrex.Tetromino.tetromino!(:t),
        next_tile: Tetrex.Tetromino.tetromino!(:i),
        upcoming_tile_names: [:o, :s]
    }

    assert Board.place_next_tile(board) == {:ok, expected}
  end

  test "place_next_tile/1 should error when an overlap would occur" do
    full_playfield =
      Tetrex.SparseGrid.new([
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x]
      ])

    board = %{Board.new(5, 5, 0) | playfield: full_playfield}

    assert Board.place_next_tile(board) == {:error, :collision}
  end
end
