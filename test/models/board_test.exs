defmodule Tetrex.Board.Test do
  use ExUnit.Case

  alias Tetrex.Board

  test "new/3 creates a specific board given a specific seed" do
    board = Tetrex.Board.new(20, 10, 3_141_592_654)

    upcoming = Enum.take(board.upcoming_tiles, 10)

    expected = %{
      playfield: Tetrex.SparseGrid.new(),
      playfield_height: 20,
      playfield_width: 10,
      current_tile: :t,
      next_tile: :s,
      hold_tile: nil
    }

    expected_upcoming = [:t, :l, :z, :o, :t, :o, :l, :l, :o, :z]

    assert board.playfield == expected.playfield
    assert board.playfield_height == expected.playfield_height
    assert board.playfield_width == expected.playfield_width
    assert board.current_tile == expected.current_tile
    assert board.next_tile == expected.next_tile
    assert board.hold_tile == expected.hold_tile
    assert upcoming == expected_upcoming
  end
end
