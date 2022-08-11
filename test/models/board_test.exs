defmodule Tetrex.Board.Test do
  use ExUnit.Case

  alias Tetrex.Board

  test "new/3 creates a the same board given the same seed" do
    board1 = Tetrex.Board.new(20, 10, 3_141_592_654)
    board2 = Tetrex.Board.new(20, 10, 3_141_592_654)

    assert board1 == board2
  end

  test "merge_active_draw_next/1 should change the current tile when no overlap would occur" do
    board = %{
      Board.new(3, 3, 0)
      | next_tile: Tetrex.Tetromino.fetch!(:t),
        upcoming_tile_names: [:i, :o, :s]
    }

    expected = %{
      board
      | active_tile: board.next_tile,
        next_tile: Tetrex.Tetromino.fetch!(:i),
        playfield: board.active_tile,
        upcoming_tile_names: [:o, :s]
    }

    assert Board.merge_active_draw_next(board) == {:ok, expected}
  end

  test "merge_active_draw_next/1 should error when an overlap would occur" do
    full_playfield =
      Tetrex.SparseGrid.new([
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x],
        [:x, :x, :x, :x, :x]
      ])

    board = %{Board.new(5, 5, 0) | playfield: full_playfield}

    assert Board.merge_active_draw_next(board) == {:error, :collision}
  end

  test "move_active_if_legal/2 applies the transform function when legal" do
    board = Board.new(20, 10, 0)

    transform = &Tetrex.SparseGrid.move(&1, {1, 0})

    {:ok, moved} = Board.move_active_if_legal(board, transform)

    assert moved.active_tile == transform.(board.active_tile)
  end

  test "move_active_if_legal/2 gives out_of_bounds error when moving off playfield" do
    board = %{Board.new(20, 10, 0) | active_tile: Tetrex.SparseGrid.new([[:a]])}

    transform = &Tetrex.SparseGrid.move(&1, {-1, 0})

    assert Board.move_active_if_legal(board, transform) == {:error, :out_of_bounds}
  end

  test "move_active_if_legal/2 gives collision error when over a filled space in the playfield" do
    board = %{
      Board.new(5, 1, 0)
      | active_tile: Tetrex.SparseGrid.new([[:a]]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [:b],
            [:b],
            [:b],
            [:b]
          ])
    }

    transform = &Tetrex.SparseGrid.move(&1, {1, 0})

    assert Board.move_active_if_legal(board, transform) == {:error, :collision}
  end

  test "move_active_down/1 should move the active tile down 1 when legal" do
    board = %{
      Board.new(4, 1, 0)
      | active_tile: Tetrex.SparseGrid.new([[:a]]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [:b]
          ])
    }

    {:ok, moved} = Board.move_active_down(board)

    expected =
      Tetrex.SparseGrid.new([
        [],
        [:a]
      ])

    assert moved.active_tile == expected
  end

  test "move_active_down/1 should draw a new tile if block below" do
    board = %{
      Board.new(4, 1, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [:b],
            [:b]
          ]),
        upcoming_tile_names: [:i, :o, :s]
    }

    {:ok, moved} = Board.move_active_down(board)

    expected = %{
      active_tile: board.next_tile,
      next_tile: Tetrex.Tetromino.fetch!(:i),
      upcoming_tile_names: [:o, :s]
    }

    assert Map.take(moved, [:active_tile, :next_tile, :upcoming_tile_names]) == expected
  end

  test "move_active_down/1 should fix the active tile to the playfield if block below" do
    board = %{
      Board.new(4, 1, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [:b],
            [:b]
          ])
    }

    {:ok, moved} = Board.move_active_down(board)

    expected =
      Tetrex.SparseGrid.new([
        [],
        [:a],
        [:b],
        [:b]
      ])

    assert moved.playfield == expected
  end

  test "move_active_left/1 should move the active tile left by one if legal" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    moved = Board.move_active_left(board)

    expected = Tetrex.SparseGrid.new([[:a]])

    assert moved.active_tile == expected
  end

  test "move_active_left/1 should not move the active tile left blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[:b, nil, nil]])
    }

    not_moved = Board.move_active_left(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "move_active_left/1 should not move the active tile left on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[:a, nil, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    not_moved = Board.move_active_left(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "move_active_right/1 should move the active tile right by one if legal" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    moved = Board.move_active_right(board)

    expected = Tetrex.SparseGrid.new([[nil, nil, :a]])

    assert moved.active_tile == expected
  end

  test "move_active_right/1 should not move the active tile right blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, :b]])
    }

    not_moved = Board.move_active_right(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "move_active_right/1 should not move the active tile right on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, nil, :a]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    not_moved = Board.move_active_right(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "hold_active/1 should hold the active_tile when no hold_tile" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile: nil,
        active_tile: Tetrex.SparseGrid.new([[:a]])
    }

    new_board = Board.hold_active(board)

    assert new_board.hold_tile == board.active_tile
  end

  test "hold_active/1 should draw a new tile when no hold_tile" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile: nil,
        active_tile: Tetrex.SparseGrid.new([[:a]]),
        next_tile: Tetrex.Tetromino.fetch!(:t),
        upcoming_tile_names: [:i, :o, :s]
    }

    result =
      board
      |> Board.hold_active()
      |> Map.take([:active_tile, :next_tile, :upcoming_tile_names])

    expected = %{
      active_tile: board.next_tile,
      next_tile: Tetrex.Tetromino.fetch!(:i),
      upcoming_tile_names: [:o, :s]
    }

    assert result == expected
  end

  test "hold_active/1 should swap active and hold tiles a new tile when no hold_tile" do
    board = %{
      Board.new(10, 10, 0)
      | hold_tile:
          Tetrex.SparseGrid.new([
            [:h],
            [:h],
            [:h, :h]
          ]),
        active_tile:
          Tetrex.SparseGrid.new([
            [:a, :a, :a, :a]
          ]),
        next_tile: Tetrex.Tetromino.fetch!(:t),
        upcoming_tile_names: [:i, :o, :s]
    }

    result =
      board
      |> Board.hold_active()
      |> Map.take([:active_tile, :hold_tile, :next_tile])

    expected = %{
      # Hold tile aligned with top centre of where active_tile was
      active_tile:
        Tetrex.SparseGrid.new([
          [nil, :h],
          [nil, :h],
          [nil, :h, :h]
        ]),
      hold_tile: board.active_tile,
      next_tile: board.next_tile
    }

    assert result == expected
  end

  test "hold_active/1 should not swap active and hold tiles if hold tile doesn't fit where active was" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile:
          Tetrex.SparseGrid.new([
            [:h, :h, :h]
          ]),
        active_tile:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, nil],
            [nil, nil, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [:p, :p, :p],
            [:p, nil, :p],
            [:p, :p, :p]
          ])
    }

    assert Board.hold_active(board) == board
  end

  test "rotate_active/1 should rotate the active tile 90 degrees when no collision" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil]
          ])
    }

    rotated = Board.rotate_active(board)

    assert rotated.active_tile == Tetrex.SparseGrid.rotate(board.active_tile, :clockwise90)
  end

  test "rotate_active/1 should rotate the active tile 180 degrees when collision at 90" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, :b, nil]
          ])
    }

    rotated = Board.rotate_active(board)

    assert rotated.active_tile == Tetrex.SparseGrid.rotate(board.active_tile, :clockwise180)
  end

  test "rotate_active/1 should rotate the active tile 270 degrees when collision at 90 & 180" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [:b, nil, nil],
            [nil, :b, nil]
          ])
    }

    rotated = Board.rotate_active(board)

    assert rotated.active_tile == Tetrex.SparseGrid.rotate(board.active_tile, :clockwise270)
  end

  test "rotate_active/1 should not rotate the active tile when collision at 90, 180, & 270" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [nil, :b, nil],
            [:b, nil, nil],
            [nil, :b, nil]
          ])
    }

    not_rotated = Board.rotate_active(board)

    assert not_rotated == board
  end

  test "preview/1 should return flattened view of board when active tile fits" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile:
          Tetrex.SparseGrid.new([
            [:h]
          ]),
        next_tile:
          Tetrex.SparseGrid.new([
            [:n]
          ]),
        active_tile:
          Tetrex.SparseGrid.new([
            [nil, :a, nil],
            [nil, :a, nil],
            [nil, nil, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [:p, nil, :p],
            [:p, :p, :p]
          ])
    }

    previewed = Board.preview(board)

    expected = %{
      hold_tile: board.hold_tile,
      next_tile: board.next_tile,
      playfield:
        Tetrex.SparseGrid.new([
          [nil, :a, nil],
          [:p, :a, :p],
          [:p, :p, :p]
        ]),
      active_tile_fits: true
    }

    assert previewed == expected
  end

  test "preview/1 should return flattened view with active tile clipped to fit when overlaps" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile:
          Tetrex.SparseGrid.new([
            [:h]
          ]),
        next_tile:
          Tetrex.SparseGrid.new([
            [:n]
          ]),
        active_tile:
          Tetrex.SparseGrid.new([
            [nil, :a, :b],
            [nil, :c, nil],
            [nil, :d, nil]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [nil, nil, nil],
            [:p, nil, :p],
            [:p, :p, :p]
          ])
    }

    previewed = Board.preview(board)

    expected = %{
      hold_tile: board.hold_tile,
      next_tile: board.next_tile,
      playfield:
        Tetrex.SparseGrid.new([
          [nil, :c, nil],
          [:p, :d, :p],
          [:p, :p, :p]
        ]),
      active_tile_fits: false
    }

    assert previewed == expected
  end
end
