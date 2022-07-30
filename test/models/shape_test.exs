defmodule Tetrex.Shape.Test do
  use ExUnit.Case
  doctest Tetrex.Shape

  test "new/1 can create a shape from 2d list of tuples" do
    shape =
      Tetrex.Shape.new([
        [:blue, :blue, :blue],
        [:blue, nil, nil]
      ])

    expected = %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}

    assert shape == expected
  end

  test "new/1 can create a shape from irregular 2d list of tuples" do
    shape =
      Tetrex.Shape.new([
        [:blue, :blue, :blue],
        [:blue]
      ])

    expected = %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue}

    assert shape == expected
  end

  test "merge/2 can combine shapes with no offset" do
    blue_l =
      Tetrex.Shape.new([
        [:blue, nil],
        [:blue, nil],
        [:blue, :blue]
      ])

    red_t =
      Tetrex.Shape.new([
        [nil, :red, nil],
        [:red, :red, :red]
      ])

    merged = Tetrex.Shape.merge(blue_l, red_t)

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

  test "move/2 offsets all the coordinates in a Shape" do
    shape = %{
      {0, 0} => :blue,
      {0, 1} => :red,
      {1, 0} => :red,
      {1, 1} => :green
    }

    moved = Tetrex.Shape.move(shape, {-2, 1})

    expected = %{
      {-2, 1} => :blue,
      {-2, 2} => :red,
      {-1, 1} => :red,
      {-1, 2} => :green
    }

    assert moved == expected
  end

  test "rotate/2 can rotate a Shape 90 degrees around the origin" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise90)

    expected = %{{0, -2} => :blue, {0, -1} => :blue, {0, 0} => :blue, {1, -2} => :blue}

    assert rotated == expected
  end

  test "rotate/2 can rotate a Shape 180 degrees around the origin" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise180)

    expected = %{{-2, -1} => :blue, {-2, 0} => :blue, {-1, 0} => :blue, {0, 0} => :blue}

    assert rotated == expected
  end

  test "rotate/2 can rotate a Shape 270 degrees around the origin" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise270)

    expected = %{{-1, 2} => :blue, {0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue}

    assert rotated == expected
  end

  test "rotate/3 can rotate a Shape 90 degrees around a given origin" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise90, {3, 1})

    expected = %{{2, 2} => :blue, {2, 3} => :blue, {2, 4} => :blue, {3, 2} => :blue}

    assert rotated == expected
  end

  test "rotate/3 can rotate a Shape 180 degrees around a given origin" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise180, {3, 1})

    expected = %{{4, 1} => :blue, {4, 2} => :blue, {5, 2} => :blue, {6, 2} => :blue}

    assert rotated == expected
  end

  test "rotate/3 can rotate a Shape 270 degrees around a given origin" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise270, {3, 1})

    expected = %{{3, 0} => :blue, {4, -2} => :blue, {4, -1} => :blue, {4, 0} => :blue}

    assert rotated == expected
  end
end
