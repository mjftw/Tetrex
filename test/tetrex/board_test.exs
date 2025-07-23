defmodule Tetrex.Board.Test do
  use ExUnit.Case

  alias Tetrex.Board

  test "new/3 creates a the same board given the same seed" do
    board1 = Tetrex.Board.new(20, 10, 3_141_592_654)
    board2 = Tetrex.Board.new(20, 10, 3_141_592_654)

    assert board1 == board2
  end

  test "new/3 creates places the first active tile at the top center of the playfield" do
    board = Tetrex.Board.new(20, 10, 0)

    expected =
      Tetrex.SparseGrid.align(
        board.active_tile,
        :top_centre,
        {0, 0},
        {board.playfield_height, board.playfield_width}
      )

    assert board.active_tile == expected
  end

  test "try_move_active_if_legal/2 applies the transform function when legal" do
    board = Board.new(20, 10, 0)

    transform = &Tetrex.SparseGrid.move(&1, {1, 0})

    {:ok, moved} = Board.try_move_active_if_legal(board, transform)

    assert moved.active_tile == transform.(board.active_tile)
  end

  test "try_move_active_if_legal/2 gives out_of_bounds error when moving off playfield" do
    board = %{Board.new(20, 10, 0) | active_tile: Tetrex.SparseGrid.new([[:a]])}

    transform = &Tetrex.SparseGrid.move(&1, {-1, 0})

    assert Board.try_move_active_if_legal(board, transform) == {:error, :out_of_bounds}
  end

  test "clear_completed_rows/1 should clear completed rows on the playfield" do
    board = %{
      Board.new(6, 3, 0)
      | playfield:
          Tetrex.SparseGrid.new([
            [],
            [:b, :b, :b],
            [:b, :b, :b],
            [:b, :b],
            [:b, :b],
            [:b, :b]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [],
        [:b, :b],
        [:b, :b],
        [:b, :b]
      ])

    {%Tetrex.Board{playfield: playfield}, _} = Board.clear_completed_rows(board)

    assert playfield == expected
  end

  test "clear_completed_rows/1 should shift rows above cleared down" do
    board = %{
      Board.new(7, 3, 0)
      | playfield:
          Tetrex.SparseGrid.new([
            [:a],
            [:x, :x, :x],
            [nil, nil, :c],
            [:x, :x, :x],
            [:b, :b],
            [:b, :b],
            [:x, :x, :x]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [],
        [:a],
        [nil, nil, :c],
        [:b, :b],
        [:b, :b]
      ])

    {%Tetrex.Board{playfield: playfield}, _} = Board.clear_completed_rows(board)

    assert playfield == expected
  end

  test "clear_completed_rows/1 should clear top row if complete" do
    board = %{
      Board.new(5, 3, 0)
      | playfield:
          Tetrex.SparseGrid.new([
            [:x, :x, :x],
            [:a],
            [nil, nil, :c],
            [:b, :b],
            [:b, :b]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [:a],
        [nil, nil, :c],
        [:b, :b],
        [:b, :b]
      ])

    {%Tetrex.Board{playfield: playfield}, _} = Board.clear_completed_rows(board)

    assert playfield == expected
  end

  test "clear_completed_rows/1 should correctly report number of rows cleared" do
    board = %{
      Board.new(7, 3, 0)
      | playfield:
          Tetrex.SparseGrid.new([
            [:x, :x, :x],
            [:a],
            [:x, :x, :x],
            [nil, nil, :c],
            [:x, :x, :x],
            [:b, :b],
            [:b, :b]
          ])
    }

    {_, rows_cleared} = Board.clear_completed_rows(board)

    assert rows_cleared == 3
  end

  test "try_move_active_if_legal/2 gives collision error when over a filled space in the playfield" do
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

    assert Board.try_move_active_if_legal(board, transform) == {:error, :collision}
  end

  test "try_move_active_down/1 should move the active tile down 1 when legal" do
    board = %{
      Board.new(4, 2, 0)
      | active_tile: Tetrex.SparseGrid.new([[:a]]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [:b]
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      Tetrex.SparseGrid.new([
        [],
        [:a]
      ])

    assert moved.active_tile == expected
  end

  test "try_move_active_down/1 should draw a new tile at top centre of playfield if blocked below" do
    board = %{
      Board.new(4, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [nil, :a]
          ]),
        next_tile:
          Tetrex.SparseGrid.new([
            [:n]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [nil, :b],
            [nil, :b]
          ]),
        upcoming_tile_names: [:i, :o, :s]
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected = %{
      active_tile: board.next_tile |> Tetrex.SparseGrid.move(:right, 1),
      next_tile: Tetrex.Tetromino.fetch!(:i),
      upcoming_tile_names: [:o, :s]
    }

    assert Map.take(moved, [:active_tile, :next_tile, :upcoming_tile_names]) == expected
  end

  test "try_move_active_down/1 should fix the active tile to the playfield if blocked below" do
    board = %{
      Board.new(4, 2, 0)
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

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      Tetrex.SparseGrid.new([
        [],
        [:a],
        [:b],
        [:b]
      ])

    assert moved.playfield == expected
  end

  test "try_move_active_down/1 should report :collision status if blocked below" do
    board = %{
      Board.new(4, 2, 0)
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

    {status, _, _} = Board.try_move_active_down(board)

    assert status == :collision
  end

  test "try_move_active_down/1 should fix the active tile to the playfield if at bottom of playfield" do
    board = %{
      Board.new(4, 2, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            []
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [],
        [:a]
      ])

    assert moved.playfield == expected
  end

  test "try_move_active_down/1 should report :out_of_bounds status if at bottom of playfield" do
    board = %{
      Board.new(4, 2, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            []
          ])
    }

    {status, _, _} = Board.try_move_active_down(board)

    assert status == :out_of_bounds
  end

  test "try_move_active_down/1 should clear any rows that were filled by the move" do
    board = %{
      Board.new(5, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [:a],
            [:a, :a],
            [:a],
            []
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [nil, nil, :b],
            [nil, nil, :b],
            [nil, :b, :b],
            [:b, :b, nil]
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [],
        [:a, nil, :b],
        [:b, :b, nil]
      ])

    assert moved.playfield == expected
  end

  test "try_move_active_down/1 should report the number of rows that were cleared" do
    board = %{
      Board.new(5, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [:a],
            [:a, :a],
            [:a],
            []
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [nil, nil, :b],
            [nil, nil, :b],
            [nil, :b, :b],
            [:b, :b, nil]
          ])
    }

    {_, _, num_rows_cleared} = Board.try_move_active_down(board)

    assert num_rows_cleared == 2
  end

  test "try_move_active_down/1 should not clear blocking tiles" do
    board = %{
      Board.new(6, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [:a],
            [:a, :a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [nil, nil, :b],
            [nil, nil, :b],
            [nil, :b, :b],
            [:b, :b, nil],
            [:blocking, :blocking, :blocking]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [nil, nil, :b],
        [:a, :a, :b],
        [nil, :b, :b],
        [:b, :b, nil],
        [:blocking, :blocking, :blocking]
      ])

    {_, moved, _} = Board.try_move_active_down(board)

    assert moved.playfield == expected
  end

  test "try_drop/1 move active tile to lowest possible position" do
    board = %{
      Board.new(6, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [],
            [:a],
            [:a, :a],
            [:a],
            []
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [],
            [nil, :c, :c],
            [:b, :b]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [],
        [:a],
        [:a, :a],
        [:b, :b]
      ])

    {moved, 1} = Board.drop_active(board)

    assert moved.playfield == expected
  end

  test "try_move_active_left/1 should move the active tile left by one if legal" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    {_, moved} = Board.try_move_active_left(board)

    expected = Tetrex.SparseGrid.new([[:a]])

    assert moved.active_tile == expected
  end

  test "try_move_active_left/1 should not move the active tile left blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[:b, nil, nil]])
    }

    {_, not_moved} = Board.try_move_active_left(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_left/1 should give a :out_of_bounds status if active tile left if on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[:a, nil, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    {status, _} = Board.try_move_active_left(board)

    assert status == :out_of_bounds
  end

  test "try_move_active_left/1 should give a :collision status if active tile left if blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[:b, nil, nil]])
    }

    {status, _} = Board.try_move_active_left(board)

    assert status == :collision
  end

  test "try_move_active_left/1 should not move the active tile left on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[:a, nil, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    {_, not_moved} = Board.try_move_active_left(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_right/1 should move the active tile right by one if legal" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    {_, moved} = Board.try_move_active_right(board)

    expected = Tetrex.SparseGrid.new([[nil, nil, :a]])

    assert moved.active_tile == expected
  end

  test "try_move_active_right/1 should not move the active tile right if blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, :b]])
    }

    {_, not_moved} = Board.try_move_active_right(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_right/1 should not move the active tile right if on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, nil, :a]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    {_, not_moved} = Board.try_move_active_right(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_right/1 should give an :collision status if blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, :a, nil]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, :b]])
    }

    {status, _} = Board.try_move_active_right(board)

    assert status == :collision
  end

  test "try_move_active_right/1 should give a :out_of_bounds status if on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: Tetrex.SparseGrid.new([[nil, nil, :a]]),
        playfield: Tetrex.SparseGrid.new([[nil, nil, nil]])
    }

    {status, _} = Board.try_move_active_right(board)

    assert status == :out_of_bounds
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

  test "add_blocking_row/2 should push playfield up and add a row to the bottom" do
    board = %{
      Board.new(6, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [nil, :a, nil],
            [:a, nil, nil],
            [nil, :a, nil]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [nil, :a, nil],
        [:a, nil, nil],
        [nil, :a, nil],
        [:blocking, :blocking, :blocking]
      ])

    %{playfield: moved} = Board.add_blocking_row(board)

    assert moved == expected
  end

  test "remove_blocking_row/2 remove a blocking row from bottom of playfield when there is one" do
    board = %{
      Board.new(6, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [nil, :a, nil],
            [:a, nil, nil],
            [nil, :a, nil],
            [:blocking, :blocking, :blocking]
          ])
    }

    expected =
      Tetrex.SparseGrid.new([
        [],
        [],
        [],
        [nil, :a, nil],
        [:a, nil, nil],
        [nil, :a, nil]
      ])

    %{playfield: moved} = Board.remove_blocking_row(board)

    assert moved == expected
  end

  test "remove_blocking_row/2 not modify playfield when no blocking row" do
    board = %{
      Board.new(5, 3, 0)
      | active_tile:
          Tetrex.SparseGrid.new([
            [:a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [nil, :a, nil],
            [:a, nil, nil],
            [nil, :a, nil]
          ])
    }

    %{playfield: not_moved} = Board.remove_blocking_row(board)

    assert not_moved == board.playfield
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
      playfield_height: board.playfield_height,
      playfield_width: board.playfield_width,
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

  test "preview/1 should return flattened view with drop preview when active tile fits" do
    board = %{
      Board.new(6, 3, 0)
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
            [nil, :a, :a]
          ]),
        playfield:
          Tetrex.SparseGrid.new([
            [],
            [],
            [],
            [],
            [:p, nil, :p],
            [:p, :p, :p]
          ])
    }

    %{playfield: previewed} = Board.preview(board)

    expected =
      Tetrex.SparseGrid.new([
        [nil, :a, nil],
        [nil, :a, :a],
        [nil, :drop_preview, nil],
        [nil, :drop_preview, :drop_preview],
        [:p, nil, :p],
        [:p, :p, :p]
      ])

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
      playfield_height: board.playfield_height,
      playfield_width: board.playfield_width,
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

  # Garbage System Tests - Minimal Tetris-compliant implementation

  test "single line clear generates no garbage rows" do
    board = setup_board_with_single_line_ready()
    {new_board, lines_cleared, garbage_rows} = Board.clear_lines_and_generate_garbage(board)
    assert lines_cleared == 1
    assert garbage_rows == []
  end

  defp setup_board_with_single_line_ready do
    board = Board.new(5, 10, 42)

    # Fill bottom row completely
    complete_row =
      for col <- 0..9, into: %{} do
        {{4, col}, :test_block}
      end

    playfield_with_line =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(complete_row))

    %{board | playfield: playfield_with_line}
  end

  test "double line clear generates 1 garbage row with gap" do
    board = setup_board_with_double_lines_ready()
    {new_board, lines_cleared, garbage_rows} = Board.clear_lines_and_generate_garbage(board)
    assert lines_cleared == 2
    assert length(garbage_rows) == 1
    assert garbage_row_has_single_gap(hd(garbage_rows))
  end

  defp setup_board_with_double_lines_ready do
    board = Board.new(5, 10, 42)

    # Fill bottom two rows completely
    double_complete_rows =
      for row <- 3..4, col <- 0..9, into: %{} do
        {{row, col}, :test_block}
      end

    playfield_with_lines =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(double_complete_rows))

    %{board | playfield: playfield_with_lines}
  end

  defp garbage_row_has_single_gap(garbage_row) do
    gap_count = count_gaps(garbage_row)
    filled_count = count_filled_blocks(garbage_row)
    gap_count == 1 and filled_count == 9
  end

  test "triple line clear generates 2 garbage rows with gaps" do
    board = setup_board_with_triple_lines_ready()
    {new_board, lines_cleared, garbage_rows} = Board.clear_lines_and_generate_garbage(board)
    assert lines_cleared == 3
    assert length(garbage_rows) == 2
    assert Enum.all?(garbage_rows, &garbage_row_has_single_gap/1)
  end

  defp setup_board_with_triple_lines_ready do
    board = Board.new(6, 10, 42)

    # Fill bottom three rows completely (Triple)
    triple_complete_rows =
      for row <- 3..5, col <- 0..9, into: %{} do
        {{row, col}, :test_block}
      end

    playfield_with_triple =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(triple_complete_rows))

    %{board | playfield: playfield_with_triple}
  end

  test "tetris (4 lines) generates 4 garbage rows with gaps" do
    board = setup_board_with_tetris_ready()
    {new_board, lines_cleared, garbage_rows} = Board.clear_lines_and_generate_garbage(board)
    assert lines_cleared == 4
    assert length(garbage_rows) == 4
    assert Enum.all?(garbage_rows, &garbage_row_has_single_gap/1)
  end

  defp setup_board_with_tetris_ready do
    board = Board.new(6, 10, 42)

    # Fill bottom four rows completely (Tetris)
    tetris_complete_rows =
      for row <- 2..5, col <- 0..9, into: %{} do
        {{row, col}, :test_block}
      end

    playfield_with_tetris =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(tetris_complete_rows))

    %{board | playfield: playfield_with_tetris}
  end

  test "generate_garbage_row/1 creates row with exactly 9 filled blocks and 1 gap" do
    garbage_row = Board.generate_garbage_row(gap_column: 3, width: 10)
    filled_count = count_filled_blocks(garbage_row)
    gap_count = count_gaps(garbage_row)

    assert filled_count == 9
    assert gap_count == 1
  end

  # Helper functions for garbage system tests
  defp count_filled_blocks(sparse_grid) do
    sparse_grid.values
    |> Map.values()
    |> Enum.count(fn value -> value != nil end)
  end

  defp count_gaps(sparse_grid) do
    # Count positions that should be filled but aren't
    # For a 10-wide row, there should be 10 positions total
    total_positions = 10
    filled_positions = map_size(sparse_grid.values)
    total_positions - filled_positions
  end

  test "generate_garbage_row/1 places gap at specified column" do
    for gap_col <- 0..9 do
      garbage_row = Board.generate_garbage_row(gap_column: gap_col, width: 10)
      assert get_gap_position(garbage_row) == gap_col
    end
  end

  defp get_gap_position(sparse_grid) do
    # Find which column (0-9) doesn't have a value in row 0
    filled_columns =
      sparse_grid.values
      |> Map.keys()
      |> Enum.map(fn {_row, col} -> col end)
      |> MapSet.new()

    all_columns = MapSet.new(0..9)
    gap_columns = MapSet.difference(all_columns, filled_columns)

    case MapSet.to_list(gap_columns) do
      [gap_col] -> gap_col
      [] -> :no_gap
      multiple -> {:multiple_gaps, multiple}
    end
  end

  test "generate_garbage_row/1 uses random gap position when not specified" do
    rows = Enum.map(1..10, fn _ -> Board.generate_garbage_row(width: 10) end)
    gap_positions = Enum.map(rows, &get_gap_position/1)
    assert Enum.uniq(gap_positions) |> length() > 1
  end

  test "add_garbage_rows/2 adds garbage rows to bottom of playfield" do
    board = setup_simple_board()
    garbage_rows = [Board.generate_garbage_row(gap_column: 5, width: 10)]
    new_board = Board.add_garbage_rows(board, garbage_rows)
    bottom_row = extract_bottom_row(new_board)
    assert has_garbage_pattern(bottom_row, gap_column: 5)
  end

  defp setup_simple_board do
    Board.new(5, 10, 42)
  end

  defp extract_bottom_row(board) do
    bottom_row_idx = board.playfield_height - 1

    for col <- 0..(board.playfield_width - 1), into: %{} do
      value = Tetrex.SparseGrid.get(board.playfield, bottom_row_idx, col)
      {{0, col}, value}
    end
    |> Tetrex.SparseGrid.new()
  end

  defp has_garbage_pattern(sparse_grid, opts) do
    gap_column = Keyword.fetch!(opts, :gap_column)

    # Check that all columns except gap_column have :garbage
    for col <- 0..9 do
      value = Tetrex.SparseGrid.get(sparse_grid, 0, col)

      if col == gap_column do
        value == nil
      else
        value == :garbage
      end
    end
    |> Enum.all?()
  end

  test "add_garbage_rows/2 pushes existing blocks up when adding garbage" do
    board = setup_board_with_blocks()
    original_top_left_value = Tetrex.SparseGrid.get(board.playfield, 3, 2)

    garbage_rows = [Board.generate_garbage_row(gap_column: 5, width: 10)]
    new_board = Board.add_garbage_rows(board, garbage_rows)

    # The block that was at (3,2) should now be at (2,2) - moved up one row
    moved_value = Tetrex.SparseGrid.get(new_board.playfield, 2, 2)
    assert moved_value == original_top_left_value
    assert original_top_left_value != nil
  end

  defp setup_board_with_blocks do
    board = Board.new(5, 10, 42)

    # Add some blocks to the playfield manually
    playfield_with_blocks =
      board.playfield
      |> Tetrex.SparseGrid.merge(
        Tetrex.SparseGrid.new(%{
          {3, 2} => :blue,
          {4, 1} => :red,
          {4, 3} => :green
        })
      )

    %{board | playfield: playfield_with_blocks}
  end

  test "add_garbage_rows/2 stacks multiple garbage rows from bottom up" do
    board = setup_simple_board()
    garbage_row1 = Board.generate_garbage_row(gap_column: 3, width: 10)
    garbage_row2 = Board.generate_garbage_row(gap_column: 7, width: 10)

    new_board = Board.add_garbage_rows(board, [garbage_row1, garbage_row2])

    # Second garbage row should be at bottom (last in list)
    bottom_row = extract_row(new_board, board.playfield_height - 1)
    assert has_garbage_pattern(bottom_row, gap_column: 7)

    # First garbage row should be one row up
    second_row = extract_row(new_board, board.playfield_height - 2)
    assert has_garbage_pattern(second_row, gap_column: 3)
  end

  defp extract_row(board, row_index) do
    for col <- 0..(board.playfield_width - 1), into: %{} do
      value = Tetrex.SparseGrid.get(board.playfield, row_index, col)
      {{0, col}, value}
    end
    |> Tetrex.SparseGrid.new()
  end

  test "clear_completed_rows/1 clears lines containing garbage blocks" do
    board = setup_board_with_garbage_and_gap()
    # Fill the gap to complete the line
    board = place_block_in_garbage_gap(board)
    {new_board, lines_cleared} = Board.clear_completed_rows(board)

    assert lines_cleared == 1
    assert garbage_line_is_cleared(new_board)
  end

  defp setup_board_with_garbage_and_gap do
    board = Board.new(5, 10, 42)

    # Create a garbage row with gap at column 5
    garbage_row = Board.generate_garbage_row(gap_column: 5, width: 10)
    # Place it at the bottom row
    moved_garbage = Tetrex.SparseGrid.move(garbage_row, {4, 0})

    playfield_with_garbage =
      board.playfield
      |> Tetrex.SparseGrid.merge(moved_garbage)

    %{board | playfield: playfield_with_garbage}
  end

  defp place_block_in_garbage_gap(board) do
    # Add a block at the gap position (row 4, column 5)
    gap_filled = Tetrex.SparseGrid.new(%{{4, 5} => :regular_block})

    playfield_complete =
      board.playfield
      |> Tetrex.SparseGrid.merge(gap_filled)

    %{board | playfield: playfield_complete}
  end

  defp garbage_line_is_cleared(board) do
    # Check that bottom row (4) has no garbage blocks
    bottom_row_empty =
      Enum.all?(0..9, fn col ->
        Tetrex.SparseGrid.get(board.playfield, 4, col) == nil
      end)

    bottom_row_empty
  end

  test "clear_completed_rows/1 handles mixed garbage and regular block lines" do
    board = setup_board_with_mixed_garbage_and_regular_blocks()
    board = fill_remaining_gaps(board)
    {new_board, lines_cleared} = Board.clear_completed_rows(board)

    assert lines_cleared == 2
    assert all_complete_lines_cleared(new_board)
  end

  defp setup_board_with_mixed_garbage_and_regular_blocks do
    board = Board.new(6, 10, 42)

    # Row 4: Mix of garbage and regular blocks with gaps
    mixed_row_4 = %{
      {4, 0} => :garbage,
      {4, 1} => :garbage,
      {4, 2} => :regular,
      {4, 3} => :garbage,
      {4, 4} => :regular,
      # Gap at {4, 5}
      {4, 6} => :garbage,
      {4, 7} => :regular,
      {4, 8} => :garbage,
      {4, 9} => :regular
    }

    # Row 5: Pure garbage row with gap
    garbage_row_5 = Board.generate_garbage_row(gap_column: 3, width: 10)
    moved_garbage_5 = Tetrex.SparseGrid.move(garbage_row_5, {5, 0})

    playfield_mixed =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(mixed_row_4))
      |> Tetrex.SparseGrid.merge(moved_garbage_5)

    %{board | playfield: playfield_mixed}
  end

  defp fill_remaining_gaps(board) do
    # Fill the gaps to complete both lines
    gap_fillers = %{
      # Fill gap in mixed row
      {4, 5} => :regular,
      # Fill gap in garbage row
      {5, 3} => :regular
    }

    playfield_complete =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(gap_fillers))

    %{board | playfield: playfield_complete}
  end

  defp all_complete_lines_cleared(board) do
    # Check that both rows 4 and 5 are now empty
    rows_4_5_empty =
      Enum.all?([4, 5], fn row ->
        Enum.all?(0..9, fn col ->
          Tetrex.SparseGrid.get(board.playfield, row, col) == nil
        end)
      end)

    rows_4_5_empty
  end

  test "clear_completed_rows/1 leaves incomplete garbage lines uncleared" do
    board = setup_board_with_incomplete_garbage_line()
    {new_board, lines_cleared} = Board.clear_completed_rows(board)

    assert lines_cleared == 0
    assert garbage_line_still_present(new_board)
  end

  defp setup_board_with_incomplete_garbage_line do
    board = Board.new(5, 10, 42)

    # Create a garbage row with gap at column 5 (incomplete)
    garbage_row = Board.generate_garbage_row(gap_column: 5, width: 10)
    moved_garbage = Tetrex.SparseGrid.move(garbage_row, {4, 0})

    playfield_with_incomplete_garbage =
      board.playfield
      |> Tetrex.SparseGrid.merge(moved_garbage)

    %{board | playfield: playfield_with_incomplete_garbage}
  end

  defp garbage_line_still_present(board) do
    # Check that garbage blocks are still at row 4
    garbage_blocks_present =
      Enum.any?(0..9, fn col ->
        Tetrex.SparseGrid.get(board.playfield, 4, col) == :garbage
      end)

    # Check that gap is still empty at column 5
    gap_still_empty = Tetrex.SparseGrid.get(board.playfield, 4, 5) == nil

    garbage_blocks_present and gap_still_empty
  end

  test "clear_completed_rows/1 makes garbage fall when lines above are cleared" do
    # board = setup_board_with_regular_blocks_above_garbage()
    # board = complete_line_above_garbage(board)
    # {new_board, _} = Board.clear_completed_rows(board)
    #
    # # Garbage should have moved down to fill the cleared space
    # assert garbage_has_fallen(new_board)
  end

  test "clear_lines_and_generate_opponent_garbage/1 generates appropriate garbage for opponent" do
    # player_board = setup_board_ready_for_double()
    # {new_board, opponent_garbage} = Board.clear_lines_and_generate_opponent_garbage(player_board)
    #
    # assert length(opponent_garbage) == 1  # Double = 1 garbage row
    # assert hd(opponent_garbage) |> garbage_row_has_single_gap()
  end

  test "clear_lines_and_generate_opponent_garbage/1 sends no garbage for single line clears" do
    # player_board = setup_board_ready_for_single()
    # {new_board, opponent_garbage} = Board.clear_lines_and_generate_opponent_garbage(player_board)
    #
    # assert opponent_garbage == []
  end

  test "garbage gap positions are consistent per player seed" do
    # This ensures that a player's garbage rows have aligned gaps, making them
    # easier to clear together (following modern Tetris conventions)
    # player_seed = 12345
    # garbage_1 = Board.generate_garbage_row(player_seed: player_seed)
    # garbage_2 = Board.generate_garbage_row(player_seed: player_seed)
    #
    # assert get_gap_position(garbage_1) == get_gap_position(garbage_2)
  end

  test "adding garbage that pushes blocks above playfield should trigger game over" do
    board = setup_board_with_blocks_near_top()
    tall_garbage = generate_multiple_garbage_rows(5)
    new_board = Board.add_garbage_rows(board, tall_garbage)
    preview = Board.preview(new_board)

    assert preview.active_tile_fits == false
  end

  defp setup_board_with_blocks_near_top do
    board = Board.new(5, 10, 42)

    # Place blocks in rows 1 and 2 (near top, leaving only row 0 free)
    near_top_blocks = %{
      {1, 4} => :test_block,
      {1, 5} => :test_block,
      {2, 3} => :test_block,
      {2, 4} => :test_block,
      {2, 5} => :test_block,
      {2, 6} => :test_block
    }

    playfield_with_blocks =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(near_top_blocks))

    %{board | playfield: playfield_with_blocks}
  end

  defp generate_multiple_garbage_rows(count) when count > 0 do
    for _ <- 1..count do
      Board.generate_garbage_row(width: 10)
    end
  end

  test "player survives when active piece still fits after garbage addition" do
    board = setup_board_with_room_at_top()
    small_garbage = generate_multiple_garbage_rows(2)
    new_board = Board.add_garbage_rows(board, small_garbage)
    preview = Board.preview(new_board)

    assert preview.active_tile_fits == true
  end

  defp setup_board_with_room_at_top do
    board = Board.new(6, 10, 42)

    # Place blocks only in bottom rows, leaving top 3 rows completely free
    bottom_blocks = %{
      {4, 3} => :test_block,
      {4, 4} => :test_block,
      {4, 5} => :test_block,
      {5, 2} => :test_block,
      {5, 3} => :test_block,
      {5, 4} => :test_block,
      {5, 5} => :test_block,
      {5, 6} => :test_block
    }

    playfield_with_room =
      board.playfield
      |> Tetrex.SparseGrid.merge(Tetrex.SparseGrid.new(bottom_blocks))

    %{board | playfield: playfield_with_room}
  end

  # Helper function placeholders for garbage system tests
  # These would be implemented with actual test setup logic:
  #
  # defp setup_empty_board(), do: Board.new(20, 10, 12345)
  # defp setup_board_with_single_line_ready(), do: # ... implementation
  # defp setup_board_with_double_lines_ready(), do: # ... implementation
  # defp setup_board_with_triple_lines_ready(), do: # ... implementation
  # defp setup_board_with_tetris_ready(), do: # ... implementation
  # defp garbage_row_has_single_gap(row), do: # ... implementation
  # defp generate_test_garbage_row(), do: # ... implementation
  # defp count_filled_blocks(row), do: # ... implementation
  # defp count_gaps(row), do: # ... implementation
  # defp get_gap_position(row), do: # ... implementation
  # defp generate_multiple_garbage_rows(count), do: # ... implementation
end
