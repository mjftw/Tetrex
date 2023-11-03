defmodule CarsCommercePuzzleAdventure.Board.Test do
  use ExUnit.Case

  alias CarsCommercePuzzleAdventure.Board

  test "new/3 creates a the same board given the same seed" do
    board1 = CarsCommercePuzzleAdventure.Board.new(20, 10, 3_141_592_654)
    board2 = CarsCommercePuzzleAdventure.Board.new(20, 10, 3_141_592_654)

    assert board1 == board2
  end

  test "new/3 creates places the first active tile at the top center of the playfield" do
    board = CarsCommercePuzzleAdventure.Board.new(20, 10, 0)

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.align(
        board.active_tile,
        :top_centre,
        {0, 0},
        {board.playfield_height, board.playfield_width}
      )

    assert board.active_tile == expected
  end

  test "try_move_active_if_legal/2 applies the transform function when legal" do
    board = Board.new(20, 10, 0)

    transform = &CarsCommercePuzzleAdventure.SparseGrid.move(&1, {1, 0})

    {:ok, moved} = Board.try_move_active_if_legal(board, transform)

    assert moved.active_tile == transform.(board.active_tile)
  end

  test "try_move_active_if_legal/2 gives out_of_bounds error when moving off playfield" do
    board = %{Board.new(20, 10, 0) | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a]])}

    transform = &CarsCommercePuzzleAdventure.SparseGrid.move(&1, {-1, 0})

    assert Board.try_move_active_if_legal(board, transform) == {:error, :out_of_bounds}
  end

  test "clear_completed_rows/1 should clear completed rows on the playfield" do
    board = %{
      Board.new(6, 3, 0)
      | playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:b, :b, :b],
            [:b, :b, :b],
            [:b, :b],
            [:b, :b],
            [:b, :b]
          ])
    }

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
        [],
        [],
        [],
        [:b, :b],
        [:b, :b],
        [:b, :b]
      ])

    {%CarsCommercePuzzleAdventure.Board{playfield: playfield}, _} = Board.clear_completed_rows(board)

    assert playfield == expected
  end

  test "clear_completed_rows/1 should shift rows above cleared down" do
    board = %{
      Board.new(7, 3, 0)
      | playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
      CarsCommercePuzzleAdventure.SparseGrid.new([
        [],
        [],
        [],
        [:a],
        [nil, nil, :c],
        [:b, :b],
        [:b, :b]
      ])

    {%CarsCommercePuzzleAdventure.Board{playfield: playfield}, _} = Board.clear_completed_rows(board)

    assert playfield == expected
  end

  test "clear_completed_rows/1 should clear top row if complete" do
    board = %{
      Board.new(5, 3, 0)
      | playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:x, :x, :x],
            [:a],
            [nil, nil, :c],
            [:b, :b],
            [:b, :b]
          ])
    }

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
        [],
        [:a],
        [nil, nil, :c],
        [:b, :b],
        [:b, :b]
      ])

    {%CarsCommercePuzzleAdventure.Board{playfield: playfield}, _} = Board.clear_completed_rows(board)

    assert playfield == expected
  end

  test "clear_completed_rows/1 should correctly report number of rows cleared" do
    board = %{
      Board.new(7, 3, 0)
      | playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a]]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:b],
            [:b],
            [:b],
            [:b]
          ])
    }

    transform = &CarsCommercePuzzleAdventure.SparseGrid.move(&1, {1, 0})

    assert Board.try_move_active_if_legal(board, transform) == {:error, :collision}
  end

  test "try_move_active_down/1 should move the active tile down 1 when legal" do
    board = %{
      Board.new(4, 2, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a]]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [],
            [:b]
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
        [],
        [:a]
      ])

    assert moved.active_tile == expected
  end

  test "try_move_active_down/1 should draw a new tile at top centre of playfield if blocked below" do
    board = %{
      Board.new(4, 3, 0)
      | active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [nil, :a]
          ]),
        next_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:n]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [nil, :b],
            [nil, :b]
          ]),
        upcoming_tile_names: [:two_vertical, :two_by_two, :two_horizontal]
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected = %{
      active_tile: board.next_tile |> CarsCommercePuzzleAdventure.SparseGrid.move(:right, 1),
      next_tile: CarsCommercePuzzleAdventure.Tetromino.fetch!(:two_vertical),
      upcoming_tile_names: [:two_by_two, :two_horizontal]
    }

    assert Map.take(moved, [:active_tile, :next_tile, :upcoming_tile_names]) == expected
  end

  test "try_move_active_down/1 should fix the active tile to the playfield if blocked below" do
    board = %{
      Board.new(4, 2, 0)
      | active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [:b],
            [:b]
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [],
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [],
            []
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [],
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:a],
            [:a, :a],
            [:a],
            []
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [nil, nil, :b],
            [nil, nil, :b],
            [nil, :b, :b],
            [:b, :b, nil]
          ])
    }

    {_, moved, _} = Board.try_move_active_down(board)

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:a],
            [:a, :a],
            [:a],
            []
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:a],
            [:a, :a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [nil, nil, :b],
            [nil, nil, :b],
            [nil, :b, :b],
            [:b, :b, nil],
            [:blocking, :blocking, :blocking]
          ])
    }

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [:a],
            [:a, :a],
            [:a],
            []
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [],
            [],
            [nil, :c, :c],
            [:b, :b]
          ])
    }

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, :a, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, nil]])
    }

    {_, moved} = Board.try_move_active_left(board)

    expected = CarsCommercePuzzleAdventure.SparseGrid.new([[:a]])

    assert moved.active_tile == expected
  end

  test "try_move_active_left/1 should not move the active tile left blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, :a, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[:b, nil, nil]])
    }

    {_, not_moved} = Board.try_move_active_left(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_left/1 should give a :out_of_bounds status if active tile left if on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a, nil, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, nil]])
    }

    {status, _} = Board.try_move_active_left(board)

    assert status == :out_of_bounds
  end

  test "try_move_active_left/1 should give a :collision status if active tile left if blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, :a, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[:b, nil, nil]])
    }

    {status, _} = Board.try_move_active_left(board)

    assert status == :collision
  end

  test "try_move_active_left/1 should not move the active tile left on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a, nil, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, nil]])
    }

    {_, not_moved} = Board.try_move_active_left(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_right/1 should move the active tile right by one if legal" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, :a, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, nil]])
    }

    {_, moved} = Board.try_move_active_right(board)

    expected = CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, :a]])

    assert moved.active_tile == expected
  end

  test "try_move_active_right/1 should not move the active tile right if blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, :a, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, :b]])
    }

    {_, not_moved} = Board.try_move_active_right(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_right/1 should not move the active tile right if on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, :a]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, nil]])
    }

    {_, not_moved} = Board.try_move_active_right(board)

    assert not_moved.active_tile == board.active_tile
  end

  test "try_move_active_right/1 should give an :collision status if blocked" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, :a, nil]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, :b]])
    }

    {status, _} = Board.try_move_active_right(board)

    assert status == :collision
  end

  test "try_move_active_right/1 should give a :out_of_bounds status if on edge of playfield" do
    board = %{
      Board.new(1, 3, 0)
      | active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, :a]]),
        playfield: CarsCommercePuzzleAdventure.SparseGrid.new([[nil, nil, nil]])
    }

    {status, _} = Board.try_move_active_right(board)

    assert status == :out_of_bounds
  end

  test "hold_active/1 should hold the active_tile when no hold_tile" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile: nil,
        active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a]])
    }

    new_board = Board.hold_active(board)

    assert new_board.hold_tile == board.active_tile
  end

  test "hold_active/1 should draw a new tile when no hold_tile" do
    board = %{
      Board.new(3, 3, 0)
      | hold_tile: nil,
        active_tile: CarsCommercePuzzleAdventure.SparseGrid.new([[:a]]),
        next_tile: CarsCommercePuzzleAdventure.Tetromino.fetch!(:single),
        upcoming_tile_names: [:two_vertical, :two_by_two, :two_horizontal]
    }

    result =
      board
      |> Board.hold_active()
      |> Map.take([:active_tile, :next_tile, :upcoming_tile_names])

    expected = %{
      active_tile: board.next_tile,
      next_tile: CarsCommercePuzzleAdventure.Tetromino.fetch!(:two_vertical),
      upcoming_tile_names: [:two_by_two, :two_horizontal]
    }

    assert result == expected
  end

  test "hold_active/1 should swap active and hold tiles a new tile when no hold_tile" do
    board = %{
      Board.new(10, 10, 0)
      | hold_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:h],
            [:h],
            [:h, :h]
          ]),
        active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:a, :a, :a, :a]
          ]),
        next_tile: CarsCommercePuzzleAdventure.Tetromino.fetch!(:single),
        upcoming_tile_names: [:two_vertical, :two_by_two, :two_horizontal]
    }

    result =
      board
      |> Board.hold_active()
      |> Map.take([:active_tile, :hold_tile, :next_tile])

    expected = %{
      # Hold tile aligned with top centre of where active_tile was
      active_tile:
        CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:h, :h, :h]
          ]),
        active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, nil],
            [nil, nil, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil]
          ])
    }

    rotated = Board.rotate_active(board)

    assert rotated.active_tile ==
             CarsCommercePuzzleAdventure.SparseGrid.rotate(board.active_tile, :clockwise90)
  end

  test "rotate_active/1 should rotate the active tile 180 degrees when collision at 90" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, :b, nil]
          ])
    }

    rotated = Board.rotate_active(board)

    assert rotated.active_tile ==
             CarsCommercePuzzleAdventure.SparseGrid.rotate(board.active_tile, :clockwise180)
  end

  test "rotate_active/1 should rotate the active tile 270 degrees when collision at 90 & 180" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [:b, nil, nil],
            [nil, :b, nil]
          ])
    }

    rotated = Board.rotate_active(board)

    assert rotated.active_tile ==
             CarsCommercePuzzleAdventure.SparseGrid.rotate(board.active_tile, :clockwise270)
  end

  test "rotate_active/1 should not rotate the active tile when collision at 90, 180, & 270" do
    board = %{
      Board.new(3, 3, 0)
      | active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, nil, nil],
            [nil, :a, :a],
            [nil, nil, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [],
            [nil, :a, nil],
            [:a, nil, nil],
            [nil, :a, nil]
          ])
    }

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [],
            [],
            [nil, :a, nil],
            [:a, nil, nil],
            [nil, :a, nil],
            [:blocking, :blocking, :blocking]
          ])
    }

    expected =
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:h]
          ]),
        next_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:n]
          ]),
        active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, :a, nil],
            [nil, :a, nil],
            [nil, nil, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
        CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:h]
          ]),
        next_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:n]
          ]),
        active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, :a, nil],
            [nil, :a, :a]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
      CarsCommercePuzzleAdventure.SparseGrid.new([
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
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:h]
          ]),
        next_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [:n]
          ]),
        active_tile:
          CarsCommercePuzzleAdventure.SparseGrid.new([
            [nil, :a, :b],
            [nil, :c, nil],
            [nil, :d, nil]
          ]),
        playfield:
          CarsCommercePuzzleAdventure.SparseGrid.new([
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
        CarsCommercePuzzleAdventure.SparseGrid.new([
          [nil, :c, nil],
          [:p, :d, :p],
          [:p, :p, :p]
        ]),
      active_tile_fits: false
    }

    assert previewed == expected
  end
end
