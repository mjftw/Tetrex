defmodule Tetrex.Shape.Test do
  use ExUnit.Case
  doctest Tetrex.Shape

  test "new can create a shape from 2d list of tuples" do
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
end
