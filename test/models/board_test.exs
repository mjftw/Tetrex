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
      current_tile: %Tetrex.LazySparseGrid{
        rotation: :zero,
        rotation_origin: {0, 0},
        sparse_grid: %{{0, 1} => :purple, {1, 0} => :purple, {1, 1} => :purple, {1, 2} => :purple},
        translation: {0, 0}
      },
      next_tile_name: :s,
      hold_tile_name: nil
    }

    expected_upcoming = [:t, :l, :z, :o, :t, :o, :l, :l, :o, :z]

    assert board.playfield == expected.playfield
    assert board.playfield_height == expected.playfield_height
    assert board.playfield_width == expected.playfield_width
    assert board.current_tile == expected.current_tile
    assert board.next_tile_name == expected.next_tile_name
    assert board.hold_tile_name == expected.hold_tile_name
    assert upcoming == expected_upcoming
  end

  test "place_next_tile/1 should change the current tile when no overlap would occur" do
    board = %{
      Board.new(5, 5, 0)
      | next_tile_name: :t,
        upcoming_tile_names: [:i, :o, :s]
    }

    expected = %{
      board
      | current_tile: :t,
        next_tile_name: :i,
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
