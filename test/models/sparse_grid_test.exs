defmodule SparseGrid.Test do
  use ExUnit.Case
  alias Tetrex.SparseGrid
  doctest SparseGrid

  test "new/1 can create a grid from 2d list of tuples" do
    grid =
      SparseGrid.new([
        [:blue, :blue, :blue],
        [:blue, nil, nil]
      ])

    expected = %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}

    assert grid == expected
  end

  test "new/1 can create a grid from irregular 2d list of tuples" do
    grid =
      SparseGrid.new([
        [:blue, :blue, :blue],
        [:blue]
      ])

    expected = %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}

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

    expected = %{
      {0, 0} => :blue,
      {0, 1} => :red,
      {1, 0} => :red,
      {1, 1} => :red,
      {1, 2} => :red,
      {2, 0} => :blue,
      {2, 1} => :blue
    }

    assert merged == expected
  end

  test "move/2 offsets all the coordinates in a SparseGrid" do
    grid = %{
      {0, 0} => :blue,
      {0, 1} => :red,
      {1, 0} => :red,
      {1, 1} => :green
    }

    moved = SparseGrid.move(grid, {-2, 1})

    expected = %{
      {-2, 1} => :blue,
      {-2, 2} => :red,
      {-1, 1} => :red,
      {-1, 2} => :green
    }

    assert moved == expected
  end

  test "rotate/2 can rotate a SparseGrid 90 degrees around the origin" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = SparseGrid.rotate(blue_l, :clockwise90)

    expected = %{{0, -2} => :blue, {0, -1} => :blue, {0, 0} => :blue, {1, -2} => :blue}

    assert rotated == expected
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

  test "rotate/2 can rotate a SparseGrid 180 degrees around the origin" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = SparseGrid.rotate(blue_l, :clockwise180)

    expected = %{{-2, -1} => :blue, {-2, 0} => :blue, {-1, 0} => :blue, {0, 0} => :blue}

    assert rotated == expected
  end

  test "rotate/2 can rotate a SparseGrid 270 degrees around the origin" do
    blue_l =
      SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = SparseGrid.rotate(blue_l, :clockwise270)

    expected = %{{-1, 2} => :blue, {0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue}

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

    expected = %{{2, 2} => :blue, {2, 3} => :blue, {2, 4} => :blue, {3, 2} => :blue}

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

    expected = %{{4, 1} => :blue, {4, 2} => :blue, {5, 2} => :blue, {6, 2} => :blue}

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

    expected = %{{3, 0} => :blue, {4, -2} => :blue, {4, -1} => :blue, {4, 0} => :blue}

    assert rotated == expected
  end

  test "corners/1 can find the corner coordinates of a grid" do
    grid = %{
      {-5, 2} => 1,
      {-11, 10} => 1,
      {2, 6} => 1,
      {13, -3} => 1,
      {5, 5} => 1
    }

    corners = SparseGrid.corners(grid)

    expected = %{
      topleft: {-11, -3},
      topright: {-11, 10},
      bottomleft: {13, -3},
      bottomright: {13, 10}
    }

    assert corners == expected
  end

  test "size/1 can find the height and width of a grid" do
    grid = %{
      {-5, 2} => 1,
      {-11, 10} => 1,
      {2, 6} => 1,
      {13, -3} => 1,
      {5, 5} => 1
    }

    {height, width} = SparseGrid.size(grid)

    assert {height, width} == {24, 13}
  end

  test "overlaps/2 should return false if when no coordinates in common" do
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

  test "overlaps/2 should return true if when coordinates in common" do
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

    aligned = SparseGrid.align(to_move, cross, :top_left)

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

    aligned = SparseGrid.align(to_move, cross, :top_centre)

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

    aligned = SparseGrid.align(to_move, cross, :top_right)

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

    aligned = SparseGrid.align(to_move, cross, :centre_left)

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

    aligned = SparseGrid.align(to_move, cross, :centre)

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

    aligned = SparseGrid.align(to_move, cross, :centre_right)

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

    aligned = SparseGrid.align(to_move, cross, :bottom_left)

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

    aligned = SparseGrid.align(to_move, cross, :bottom_centre)

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

    aligned = SparseGrid.align(to_move, cross, :bottom_right)

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

  test "align/4 should move a grid to align with a bounding box :top_left alignment" do
    to_move =
      SparseGrid.new([
        [:aa, :bb],
        [:cc, :dd]
      ])

    {top_left, bottom_right} = {{0, 0}, {5, 5}}

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :top_left)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :top_centre)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :top_right)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :centre_left)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :centre)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :centre_right)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :bottom_left)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :bottom_centre)

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

    aligned = SparseGrid.align(to_move, top_left, bottom_right, :bottom_right)

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
end
