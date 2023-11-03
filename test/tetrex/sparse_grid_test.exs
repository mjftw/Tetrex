defmodule SparseGrid.Test do
  use ExUnit.Case
  alias CarsCommercePuzzleAdventure.SparseGrid
  doctest SparseGrid

  test "new/1 can create a grid from 2d list of tuples" do
    grid =
      SparseGrid.new([
        [:blue, :blue, :blue],
        [:blue, nil, nil]
      ])

    expected = %SparseGrid{
      values: %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}
    }

    assert grid == expected
  end

  test "new/1 can create a grid from irregular 2d list of tuples" do
    grid =
      SparseGrid.new([
        [:blue, :blue, :blue],
        [:blue]
      ])

    expected = %SparseGrid{
      values: %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}
    }

    assert grid == expected
  end

  test "fill/3 creates a grid filled with a given value" do
    grid = SparseGrid.fill(:a, {2, 1}, {4, 2})

    expected =
      SparseGrid.new([
        [],
        [],
        [nil, :a, :a],
        [nil, :a, :a],
        [nil, :a, :a]
      ])

    assert grid == expected
  end

  test "merge/2 can combine grids with no offset" do
    blue_l =
      SparseGrid.new([
        [:blue, nil],
        [:blue, nil],
        [:blue, :blue]
      ])

    red_t =
      SparseGrid.new([
        [nil, :red, nil],
        [:red, :red, :red]
      ])

    merged = SparseGrid.merge(blue_l, red_t)

    expected =
      SparseGrid.new([
        [:blue, :red, nil],
        [:red, :red, :red],
        [:blue, :blue, nil]
      ])

    assert merged == expected
  end

  test "move/2 offsets all the coordinates in a SparseGrid" do
    grid =
      SparseGrid.new(%{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :green
      })

    moved = SparseGrid.move(grid, {-2, 1})

    expected =
      SparseGrid.new(%{
        {-2, 1} => :blue,
        {-2, 2} => :red,
        {-1, 1} => :red,
        {-1, 2} => :green
      })

    assert moved == expected
  end

  test "move/3 :up offsets all the coordinates in a SparseGrid" do
    grid =
      SparseGrid.new(%{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :green
      })

    moved = SparseGrid.move(grid, :up, 10)

    expected =
      SparseGrid.new(%{
        {-10, 0} => :blue,
        {-10, 1} => :red,
        {-9, 0} => :red,
        {-9, 1} => :green
      })

    assert moved == expected
  end

  test "move/3 :down offsets all the coordinates in a SparseGrid" do
    grid =
      SparseGrid.new(%{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :green
      })

    moved = SparseGrid.move(grid, :down, 10)

    expected =
      SparseGrid.new(%{
        {10, 0} => :blue,
        {10, 1} => :red,
        {11, 0} => :red,
        {11, 1} => :green
      })

    assert moved == expected
  end

  test "move/3 :left offsets all the coordinates in a SparseGrid" do
    grid =
      SparseGrid.new(%{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :green
      })

    moved = SparseGrid.move(grid, :left, 10)

    expected =
      SparseGrid.new(%{
        {0, -10} => :blue,
        {0, -9} => :red,
        {1, -10} => :red,
        {1, -9} => :green
      })

    assert moved == expected
  end

  test "move/3 :right offsets all the coordinates in a SparseGrid" do
    grid =
      SparseGrid.new(%{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :green
      })

    moved = SparseGrid.move(grid, :right, 10)

    expected =
      SparseGrid.new(%{
        {0, 10} => :blue,
        {0, 11} => :red,
        {1, 10} => :red,
        {1, 11} => :green
      })

    assert moved == expected
  end

  test "rotate/2 with :zero angle leaves grid untouched" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    assert SparseGrid.rotate(blue_l, :zero) == blue_l
  end

  test "rotate/2 can rotate a SparseGrid 90 degrees around its centre" do
    grid =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, :c, :c],
        [nil, nil, :c],
        [nil, nil, nil, :c, :c]
      ])

    rotated = SparseGrid.rotate(grid, :clockwise90)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, :c, nil],
        [nil, nil, :c, nil, :c],
        [nil, nil, :c, nil, :c]
      ])

    assert rotated == expected
  end

  test "rotate/2 can rotate a SparseGrid 180 degrees around its centre" do
    grid =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, :c, :c],
        [nil, nil, :c],
        [nil, nil, nil, :c, :c]
      ])

    rotated = SparseGrid.rotate(grid, :clockwise180)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, nil, :c, :c],
        [nil, nil, nil, nil, :c],
        [nil, nil, :c, :c]
      ])

    assert rotated == expected
  end

  test "rotate/2 can rotate a SparseGrid 270 degrees around its centre" do
    grid =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, nil, nil, :c, :c],
        [nil, nil, :c],
        [nil, nil, nil, :c, :c]
      ])

    rotated = SparseGrid.rotate(grid, :clockwise270)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, nil, :c, nil, :c],
        [nil, nil, :c, nil, :c],
        [nil, nil, nil, :c, nil]
      ])

    assert rotated == expected
  end

  test "rotate/3 can rotate a SparseGrid 90 degrees around a given origin" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = SparseGrid.rotate(blue_l, :clockwise90, {3, 1})

    expected =
      SparseGrid.new(%{{2, 2} => :blue, {2, 3} => :blue, {2, 4} => :blue, {3, 2} => :blue})

    assert rotated == expected
  end

  test "rotate/3 can rotate a SparseGrid 180 degrees around a given origin" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = SparseGrid.rotate(blue_l, :clockwise180, {3, 1})

    expected =
      SparseGrid.new(%{{4, 1} => :blue, {4, 2} => :blue, {5, 2} => :blue, {6, 2} => :blue})

    assert rotated == expected
  end

  test "rotate/3 can rotate a SparseGrid 270 degrees around a given origin" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = SparseGrid.rotate(blue_l, :clockwise270, {3, 1})

    expected =
      SparseGrid.new(%{{3, 0} => :blue, {4, -2} => :blue, {4, -1} => :blue, {4, 0} => :blue})

    assert rotated == expected
  end

  test "corners/1 can find the corner coordinates of a grid" do
    grid =
      SparseGrid.new(%{
        {-5, 2} => 1,
        {-11, 10} => 1,
        {2, 6} => 1,
        {13, -3} => 1,
        {5, 5} => 1
      })

    corners = SparseGrid.corners(grid)

    expected = %{
      topleft: {-11, -3},
      topright: {-11, 10},
      bottomleft: {13, -3},
      bottomright: {13, 10}
    }

    assert corners == expected
  end

  test "corners/1 can find the corner coordinates of a moved grid" do
    grid =
      SparseGrid.new([
        [:a],
        [:a],
        [:a, :a]
      ])
      |> SparseGrid.move({10, 10})

    corners = SparseGrid.corners(grid)

    expected = %{
      topleft: {10, 10},
      topright: {10, 11},
      bottomleft: {12, 10},
      bottomright: {12, 11}
    }

    assert corners == expected
  end

  test "size/1 can find the height and width of a grid" do
    grid =
      SparseGrid.new(%{
        {-5, 2} => 1,
        {-11, 10} => 1,
        {2, 6} => 1,
        {13, -3} => 1,
        {5, 5} => 1
      })

    {height, width} = SparseGrid.size(grid)

    assert {height, width} == {24, 13}
  end

  test "overlaps?/2 should return false if when no coordinates in common" do
    grid1 =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    grid2 =
      SparseGrid.new([
        [nil, nil, :red],
        [nil, nil, :red]
      ])

    assert SparseGrid.overlaps?(grid1, grid2) == false
  end

  test "overlaps?/2 should return true if when coordinates in common" do
    grid1 =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    grid2 =
      SparseGrid.new([
        [:green, nil, :red],
        [nil, nil, :red]
      ])

    assert SparseGrid.overlaps?(grid1, grid2) == true
  end

  test "within_bounds?/3 should return true if grid fits withing bounding box" do
    grid =
      SparseGrid.new([
        [:a, :a],
        [:a],
        [:a]
      ])

    assert SparseGrid.within_bounds?(grid, {-1, -1}, {3, 3}) == true
  end

  test "within_bounds?/3 should return false if grid falls outside bounding box" do
    # TODO
  end

  test "align/3 should move a grid to align with another using :top_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :top_left, cross)

    expected =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :top_centre alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :top_centre, cross)

    expected =
      SparseGrid.new([
        [nil, nil, :aa, :bb],
        [nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :top_right alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :top_right, cross)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, :aa, :bb],
        [nil, nil, nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :centre_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :centre_left, cross)

    expected =
      SparseGrid.new([
        [nil, nil],
        [nil, nil],
        [:aa, :bb],
        [:cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :centre alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :centre, cross)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, :aa, :bb],
        [nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :centre_right alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :centre_right, cross)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, :aa, :bb],
        [nil, nil, nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :bottom_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :bottom_left, cross)

    expected =
      SparseGrid.new([
        [nil, nil],
        [nil, nil],
        [nil, nil],
        [nil, nil],
        [:aa, :bb],
        [:cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :bottom_centre alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :bottom_centre, cross)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, :aa, :bb],
        [nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should move a grid to align with another using :bottom_right alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    cross =
      SparseGrid.new([
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [:xx, :xx, :xx, :xx, :xx, :xx],
        [nil, nil, :xx, :xx, nil, nil],
        [nil, nil, :xx, :xx, nil, nil]
      ])

    aligned = SparseGrid.align(to_move, :bottom_right, cross)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, :aa, :bb],
        [nil, nil, nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/3 should do nothing for empty grid" do
    empty = SparseGrid.empty()

    assert empty == SparseGrid.align(empty, :centre, SparseGrid.new([[:a]]))
  end

  test "align/3 should do nothing for empty alignment grid" do
    grid = SparseGrid.new([[:a]])
    empty = SparseGrid.empty()

    assert grid == SparseGrid.align(grid, :centre, empty)
  end

  test "align/4 should do nothing for empty grid" do
    empty = SparseGrid.empty()

    assert empty == SparseGrid.align(empty, :centre, 0, 0)
  end

  test "align/4 should move a grid to align with a bounding box :top_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :top_left, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :top_centre alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :top_centre, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil, :aa, :bb],
        [nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :top_right alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :top_right, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, :aa, :bb],
        [nil, nil, nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :centre_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :centre_left, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil],
        [nil, nil],
        [:aa, :bb],
        [:cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :centre alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :centre, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, :aa, :bb],
        [nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :centre_right alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :centre_right, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, :aa, :bb],
        [nil, nil, nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :bottom_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :bottom_left, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil],
        [nil, nil],
        [nil, nil],
        [nil, nil],
        [:aa, :bb],
        [:cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :bottom_centre alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :bottom_centre, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, nil, nil],
        [nil, nil, :aa, :bb],
        [nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "align/4 should move a grid to align with a bounding box :bottom_right alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, :bottom_right, top_left, bottom_right)

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, :aa, :bb],
        [nil, nil, nil, nil, :cc, :dd]
      ])

    assert aligned == expected
  end

  test "clear/3 should delete cell values that are contained within the bounding box" do
    grid =
      SparseGrid.new([
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a]
      ])

    cleared = SparseGrid.clear(grid, {1, 1}, {4, 2})

    expected =
      SparseGrid.new([
        [:a, :a, :a, :a, :a],
        [:a, nil, nil, :a, :a],
        [:a, nil, nil, :a, :a],
        [:a, nil, nil, :a, :a],
        [:a, nil, nil, :a, :a],
        [:a, :a, :a, :a, :a]
      ])

    assert cleared == expected
  end

  test "mask/3 should delete cell values that are not contained within the bounding box" do
    grid =
      SparseGrid.new([
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a],
        [:a, :a, :a, :a, :a]
      ])

    cleared = SparseGrid.mask(grid, {1, 1}, {4, 2})

    expected =
      SparseGrid.new([
        [nil, nil, nil, nil, nil],
        [nil, :a, :a, nil, nil],
        [nil, :a, :a, nil, nil],
        [nil, :a, :a, nil, nil],
        [nil, :a, :a, nil, nil],
        [nil, nil, nil, nil, nil]
      ])

    assert cleared == expected
  end

  test "replace/2 should replace all values with a given value" do
    grid =
      SparseGrid.new([
        [:a, "f", 2],
        [nil, :x, "1"],
        [],
        [:commerce]
      ])

    expected =
      SparseGrid.new([
        [:q, :q, :q],
        [nil, :q, :q],
        [],
        [:q]
      ])

    assert SparseGrid.replace(grid, :q) == expected
  end

  test "filled?/3 should return true if all cells in the bounding box are filled" do
    grid =
      SparseGrid.new([
        [nil, nil, nil],
        [nil, :a, :a],
        [nil, :a, :a]
      ])

    assert SparseGrid.filled?(grid, {1, 1}, {2, 2})
  end

  test "filled?/3 should return false if any cells in the bounding box are empty" do
    grid =
      SparseGrid.new([
        [nil, nil, nil],
        [nil, :a, :a],
        [nil, :a, nil]
      ])

    assert !SparseGrid.filled?(grid, {0, 1}, {2, 2})
  end

  test "filled?/3 should return false if any cells in the bounding box are empty (single row)" do
    grid =
      SparseGrid.new([
        [],
        [:a, nil, nil],
        [:a, :a, :a]
      ])

    assert !SparseGrid.filled?(grid, {1, 0}, {1, 2})
  end

  test "all?/2 should return true if the predicate is true for every value (arity 1 predicate)" do
    grid =
      SparseGrid.new([
        [],
        [:a],
        [:a, :a, :a]
      ])

    assert SparseGrid.all?(grid, fn value -> value == :a end)
  end

  test "all?/2 should return false if the predicate is false for any value (arity 1 predicate)" do
    grid =
      SparseGrid.new([
        [],
        [:a],
        [:a, :b, :a]
      ])

    assert !SparseGrid.all?(grid, fn value -> value == :a end)
  end

  test "all?/2 should return true if the predicate is true for every value (arity 2 predicate)" do
    grid =
      SparseGrid.new([
        [],
        [0],
        [0, 1, 2]
      ])

    assert SparseGrid.all?(grid, fn {y, x}, value -> value == x end)
  end

  test "all?/2 should return false if the predicate is false for any value (arity 2 predicate)" do
    grid =
      SparseGrid.new([
        [],
        [0],
        [0, 1, :foo]
      ])

    assert !SparseGrid.all?(grid, fn {y, x}, value -> value == x end)
  end

  test "Inspect implementation should pretty print a grid" do
    grid =
      SparseGrid.new([
        [nil, nil, 1],
        [nil, :foo],
        [nil, 5, 3.14159],
        ["hello"]
      ])

    expected = """

      x    0         1         2
    y ┼─────────┼─────────┼─────────┤
    0 │         │         │    1    │
      ┼─────────┼─────────┼─────────┤
    1 │         │   foo   │         │
      ┼─────────┼─────────┼─────────┤
    2 │         │    5    │ 3.14159 │
      ┼─────────┼─────────┼─────────┤
    3 │  hello  │         │         │
      ┴─────────┴─────────┴─────────┘
    """

    result = inspect(grid)
    # Required for check as editor auto-strips trailing spaces in expected string above
    result_to_match = String.replace(result, ~r/ +\n/, "\n")

    assert result_to_match <> "\n" == expected
  end

  test "Inspect implementation should pretty print a grid, with negative axis" do
    grid =
      SparseGrid.new([
        [nil, nil, 1],
        [nil, :foo],
        [nil, 5, 3.14159],
        ["hello"]
      ])
      |> SparseGrid.move({-2, -1})

    expected = """

       x   -1         0         1
     y ┼─────────┼─────────┼─────────┤
    -2 │         │         │    1    │
       ┼─────────┼─────────┼─────────┤
    -1 │         │   foo   │         │
       ┼─────────┼─────────┼─────────┤
     0 │         │    5    │ 3.14159 │
       ┼─────────┼─────────┼─────────┤
     1 │  hello  │         │         │
       ┴─────────┴─────────┴─────────┘
    """

    result = inspect(grid)
    # Required for check as editor auto-strips trailing spaces in expected string above
    result_to_match = String.replace(result, ~r/ +\n/, "\n")

    assert result_to_match <> "\n" == expected
  end

  test "Inspect implementation should pretty print a grid, with extreme coordinates" do
    grid =
      SparseGrid.new([
        [:a],
        [:a],
        [:a, :a]
      ])
      |> SparseGrid.move({-10000, 10000})

    expected = """

           x 10000   10001
         y ┼───────┼───────┤
    -10000 │   a   │       │
           ┼───────┼───────┤
     -9999 │   a   │       │
           ┼───────┼───────┤
     -9998 │   a   │   a   │
           ┴───────┴───────┘
    """

    result = inspect(grid)
    # Required for check as editor auto-strips trailing spaces in expected string above
    result_to_match = String.replace(result, ~r/ +\n/, "\n")

    assert result_to_match <> "\n" == expected
  end

  test "Inspect implementation should handle empty grid" do
    assert inspect(SparseGrid.new()) == "<Empty SparseGrid>"
  end
end
