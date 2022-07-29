defmodule Tetrex.Shape.Test do
  use ExUnit.Case
  doctest Tetrex.Shape

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
