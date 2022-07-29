defmodule Tetrex.Shape.Test do
  use ExUnit.Case
  doctest Tetrex.Shape

  test "new/1 can create a shape from 2d list of tuples" do
    shape =
      Tetrex.Shape.new([
        [:blue, :blue, :blue],
        [:blue, nil, nil]
      ])

    expected = %Tetrex.Shape{
      squares: %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue},
      rows: 2,
      cols: 3
    }

    assert shape == expected
  end

  test "new/1 can create a shape from irregular 2d list of tuples" do
    shape =
      Tetrex.Shape.new([
        [:blue, :blue, :blue],
        [:blue]
      ])

    expected = %Tetrex.Shape{
      squares: %{{0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue, {1, 0} => :blue},
      rows: 2,
      cols: 3
    }

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

    expected = %Tetrex.Shape{
      cols: 3,
      rows: 3,
      squares: %{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :red,
        {1, 2} => :red,
        {2, 0} => :blue,
        {2, 1} => :blue
      }
    }

    assert merged == expected
  end

  test "move/2 offsets all the coordinates in a Shape" do
    shape = %Tetrex.Shape{
      cols: 2,
      rows: 2,
      squares: %{
        {0, 0} => :blue,
        {0, 1} => :red,
        {1, 0} => :red,
        {1, 1} => :green
      }
    }

    moved = Tetrex.Shape.move(shape, {-2, 1})

    expected = %Tetrex.Shape{
      cols: 2,
      rows: 2,
      squares: %{
        {-2, 1} => :blue,
        {-2, 2} => :red,
        {-1, 1} => :red,
        {-1, 2} => :green
      }
    }

    assert moved == expected
  end

  test "rotate/2 can rotate a Shape around the origin 90 degrees" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise90)

    expected = %Tetrex.Shape{
      squares: %{{0, -2} => :blue, {0, -1} => :blue, {0, 0} => :blue, {1, -2} => :blue},
      rows: 2,
      cols: 3
    }

    assert rotated == expected
  end

  test "rotate/2 can rotate a Shape around the origin 180 degrees" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise180)

    expected = %Tetrex.Shape{
      squares: %{{-2, -1} => :blue, {-2, 0} => :blue, {-1, 0} => :blue, {0, 0} => :blue},
      rows: 3,
      cols: 2
    }

    assert rotated == expected
  end

  test "rotate/2 can rotate a Shape around the origin 270 degrees" do
    blue_l =
      Tetrex.Shape.new([
        [:blue],
        [:blue],
        [:blue, :blue]
      ])

    rotated = Tetrex.Shape.rotate(blue_l, :clockwise270)

    expected = %Tetrex.Shape{
      squares: %{{-1, 2} => :blue, {0, 0} => :blue, {0, 1} => :blue, {0, 2} => :blue},
      rows: 2,
      cols: 3
    }

    assert rotated == expected
  end
end
