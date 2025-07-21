defmodule Tetrex.Users.NameGeneratorAdditionalTest do
  use ExUnit.Case, async: true
  alias Tetrex.Users.NameGenerator

  describe "name generation" do
    test "generates names with expected format" do
      name = NameGenerator.generate()
      assert is_binary(name)
      assert String.length(name) > 0

      # Should contain a space separating adjective and animal
      assert String.contains?(name, " ")

      # Should be title case (first letter capitalized)
      first_char = String.first(name)
      assert first_char == String.upcase(first_char)
    end

    test "generates different names on multiple calls" do
      names = Enum.map(1..10, fn _ -> NameGenerator.generate() end)
      unique_names = Enum.uniq(names)

      # Should generate at least some variety (not all identical)
      # Note: There's a small chance of duplicates, but very unlikely
      assert length(unique_names) > 5
    end

    test "generated names have reasonable length" do
      name = NameGenerator.generate()

      # Should be reasonable length (not too short or too long)
      # "Cat Dog" minimum
      assert String.length(name) >= 6
      # reasonable maximum
      assert String.length(name) <= 25
    end

    test "names contain only letters and spaces" do
      names = Enum.map(1..20, fn _ -> NameGenerator.generate() end)

      Enum.each(names, fn name ->
        # Should only contain letters and spaces
        assert String.match?(name, ~r/^[A-Za-z ]+$/)
      end)
    end
  end
end
