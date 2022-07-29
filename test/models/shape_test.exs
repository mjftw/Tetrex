defmodule Tetrex.Shape.Test do
  use ExUnit.Case
  doctest Tetrex.Shape

  test "new/1 can create a shape from 2d list of tuples" do
    shape =
      Tetrex.Shape.new([
        [:blue, nil],
        [:blue, nil],
        [:blue, :blue]
      ])

    expected = %Tetrex.Shape{
      squares: %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue},
      rows: 2,
      cols: 1
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
      cols: 2,
      rows: 2,
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
end
