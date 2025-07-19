defmodule Tetrex.Users.NameGeneratorTest do
  use ExUnit.Case, async: true
  alias Tetrex.Users.NameGenerator

  describe "generate/0" do
    test "generates a name with two parts separated by a space" do
      name = NameGenerator.generate()
      parts = String.split(name, " ")

      assert length(parts) == 2
      assert String.contains?(name, " ")
    end

    test "generates names with valid adjectives and animals" do
      name = NameGenerator.generate()
      [adjective, animal] = String.split(name, " ")

      assert adjective in NameGenerator.adjectives()
      assert animal in NameGenerator.animals()
    end

    test "can generate multiple different names" do
      names = for _ <- 1..20, do: NameGenerator.generate()
      unique_names = Enum.uniq(names)

      # With 50 adjectives and 50 animals (2500 combinations),
      # it's very likely we get some unique names in 20 attempts
      assert length(unique_names) > 1
    end

    test "generated names are reasonable length" do
      name = NameGenerator.generate()

      # Shortest possible: "calm fox" (8 chars)
      # Longest possible: "magnificent chameleon" (21 chars)
      assert String.length(name) >= 8
      assert String.length(name) <= 25
    end
  end

  describe "adjectives/0" do
    test "returns exactly 50 adjectives" do
      adjectives = NameGenerator.adjectives()
      assert length(adjectives) == 50
    end

    test "all adjectives are non-empty strings" do
      adjectives = NameGenerator.adjectives()

      for adjective <- adjectives do
        assert is_binary(adjective)
        assert String.length(adjective) > 0
      end
    end

    test "adjectives are unique" do
      adjectives = NameGenerator.adjectives()
      unique_adjectives = Enum.uniq(adjectives)

      assert length(adjectives) == length(unique_adjectives)
    end

    test "contains expected sample adjectives" do
      adjectives = NameGenerator.adjectives()

      assert "Mighty" in adjectives
      assert "Clever" in adjectives
      assert "Brave" in adjectives
      assert "Inquisitive" in adjectives
    end
  end

  describe "animals/0" do
    test "returns exactly 50 animals" do
      animals = NameGenerator.animals()
      assert length(animals) == 50
    end

    test "all animals are non-empty strings" do
      animals = NameGenerator.animals()

      for animal <- animals do
        assert is_binary(animal)
        assert String.length(animal) > 0
      end
    end

    test "animals are unique" do
      animals = NameGenerator.animals()
      unique_animals = Enum.uniq(animals)

      assert length(animals) == length(unique_animals)
    end

    test "contains expected sample animals" do
      animals = NameGenerator.animals()

      assert "Panda" in animals
      assert "Otter" in animals
      assert "Fox" in animals
      assert "Wolf" in animals
    end
  end

  describe "generate_with_seed/1" do
    test "generates deterministic names with the same seed" do
      name1 = NameGenerator.generate_with_seed(42)
      name2 = NameGenerator.generate_with_seed(42)

      assert name1 == name2
    end

    test "generates different names with different seeds" do
      name1 = NameGenerator.generate_with_seed(1)
      name2 = NameGenerator.generate_with_seed(2)

      # Very likely to be different with different seeds
      assert name1 != name2
    end

    test "seeded names still follow the correct format" do
      name = NameGenerator.generate_with_seed(123)
      [adjective, animal] = String.split(name, " ")

      assert adjective in NameGenerator.adjectives()
      assert animal in NameGenerator.animals()
    end
  end

  describe "name combinations" do
    test "can generate a large variety of unique names" do
      # Generate 100 names and check uniqueness
      names = for i <- 1..100, do: NameGenerator.generate_with_seed(i)
      unique_names = Enum.uniq(names)

      # With 2500 possible combinations, we should get mostly unique names
      assert length(unique_names) > 90
    end

    test "maximum possible combinations is 2500" do
      adjective_count = length(NameGenerator.adjectives())
      animal_count = length(NameGenerator.animals())
      max_combinations = adjective_count * animal_count

      assert max_combinations == 2500
    end
  end
end
