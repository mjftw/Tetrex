defmodule Tetrex.SparseGrid.Test do
  use ExUnit.Case
  doctest Tetrex.SparseGrid

  test "new/1 can create a grid from 2d list of tuples" do
    grid =
      Tetrex.SparseGrid.new([
        [:blue, :blue, :blue],
        [:blue, nil, nil]
      ])

    expected = %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}

    assert grid == expected
  end

  test "new/1 can create a grid from irregular 2d list of tuples" do
    grid =
      Tetrex.SparseGrid.new([
        [:blue, :blue, :blue],
        [:blue]
      ])

    expected = %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}

    assert grid == expected
  end

  test "merge/2 can combine grids with no offset" do
    blue_l =
      Tetrex.SparseGrid.new([
        [:blue, nil],
        [:blue, nil],
        [:blue, :blue]
      ])

    red_t =
      Tetrex.SparseGrid.new([
        [nil, :red, nil],
        [:red, :red, :red]
      ])

    merged = Tetrex.SparseGrid.merge(blue_l, red_t)

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

    moved = Tetrex.SparseGrid.move(grid, {-2, 1})

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
      Tetrex.SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.SparseGrid.rotate(blue_l, :clockwise90)

    expected = %{{0, -2} => :blue, {0, -1} => :blue, {0, 0} => :blue, {1, -2} => :blue}

    assert rotated == expected
  end

  test "rotate/2 can rotate a SparseGrid 180 degrees around the origin" do
    blue_l =
      Tetrex.SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.SparseGrid.rotate(blue_l, :clockwise180)

    expected = %{{-2, -1} => :blue, {-2, 0} => :blue, {-1, 0} => :blue, {0, 0} => :blue}

    assert rotated == expected
  end

  test "rotate/2 can rotate a SparseGrid 270 degrees around the origin" do
    blue_l =
      Tetrex.SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.SparseGrid.rotate(blue_l, :clockwise270)

    expected = %{{-1, 2} => :blue, {0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue}

    assert rotated == expected
  end

  test "rotate/3 can rotate a SparseGrid 90 degrees around a given origin" do
    blue_l =
      Tetrex.SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.SparseGrid.rotate(blue_l, :clockwise90, {3, 1})

    expected = %{{2, 2} => :blue, {2, 3} => :blue, {2, 4} => :blue, {3, 2} => :blue}

    assert rotated == expected
  end

  test "rotate/3 can rotate a SparseGrid 180 degrees around a given origin" do
    blue_l =
      Tetrex.SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.SparseGrid.rotate(blue_l, :clockwise180, {3, 1})

    expected = %{{4, 1} => :blue, {4, 2} => :blue, {5, 2} => :blue, {6, 2} => :blue}

    assert rotated == expected
  end

  test "rotate/3 can rotate a SparseGrid 270 degrees around a given origin" do
    blue_l =
      Tetrex.SparseGrid.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.SparseGrid.rotate(blue_l, :clockwise270, {3, 1})

    expected = %{{3, 0} => :blue, {4, -2} => :blue, {4, -1} => :blue, {4, 0} => :blue}

    assert rotated == expected
  end
end
