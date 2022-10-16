defmodule TetrexTest do
  use ExUnit.Case
  doctest Tetrex

  test "greets the world" do
    assert Tetrex.hello() == :world
  end
end
