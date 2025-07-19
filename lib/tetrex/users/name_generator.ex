defmodule Tetrex.Users.NameGenerator do
  @moduledoc """
  Generates random usernames in the format "<adjective> <animal>".
  """

  @adjectives [
    "Mighty", "Clever", "Brave", "Swift", "Gentle", "Fierce", "Wise", "Playful", "Curious", "Bold",
    "Graceful", "Sneaky", "Cheerful", "Mysterious", "Energetic", "Calm", "Friendly", "Daring", "Noble", "Witty",
    "Agile", "Strong", "Quiet", "Lively", "Proud", "Patient", "Wild", "Cosmic", "Electric", "Magical",
    "Ancient", "Fearless", "Brilliant", "Charming", "Dazzling", "Elegant", "Fluffy", "Glorious", "Happy", "Incredible",
    "Jovial", "Keen", "Legendary", "Magnificent", "Nimble", "Optimistic", "Peaceful", "Radiant", "Serene", "Inquisitive"
  ]

  @animals [
    "Panda", "Otter", "Fox", "Wolf", "Bear", "Eagle", "Tiger", "Lion", "Elephant", "Dolphin",
    "Penguin", "Owl", "Rabbit", "Squirrel", "Deer", "Hawk", "Shark", "Whale", "Leopard", "Cheetah",
    "Kangaroo", "Koala", "Hippo", "Giraffe", "Zebra", "Rhino", "Falcon", "Raven", "Badger", "Beaver",
    "Lynx", "Jaguar", "Panther", "Buffalo", "Moose", "Elk", "Antelope", "Gazelle", "Mongoose", "Meerkat",
    "Wombat", "Platypus", "Armadillo", "Sloth", "Lemur", "Chameleon", "Iguana", "Turtle", "Octopus", "Jellyfish"
  ]

  @doc """
  Generates a random username in the format "<adjective> <animal>".

  ## Examples

      iex> name = Tetrex.Users.NameGenerator.generate()
      iex> String.contains?(name, " ")
      true

      iex> name = Tetrex.Users.NameGenerator.generate()
      iex> parts = String.split(name, " ")
      iex> length(parts)
      2

  """
  def generate do
    adjective = Enum.random(@adjectives)
    animal = Enum.random(@animals)
    "#{adjective} #{animal}"
  end

  @doc """
  Returns the list of available adjectives.

  ## Examples

      iex> adjectives = Tetrex.Users.NameGenerator.adjectives()
      iex> length(adjectives)
      50

      iex> adjectives = Tetrex.Users.NameGenerator.adjectives()
      iex> "mighty" in adjectives
      true

  """
  def adjectives, do: @adjectives

  @doc """
  Returns the list of available animals.

  ## Examples

      iex> animals = Tetrex.Users.NameGenerator.animals()
      iex> length(animals)
      50

      iex> animals = Tetrex.Users.NameGenerator.animals()
      iex> "panda" in animals
      true

  """
  def animals, do: @animals

  @doc """
  Generates a deterministic username based on a seed for testing purposes.

  ## Examples

      iex> Tetrex.Users.NameGenerator.generate_with_seed(42)
      iex> Tetrex.Users.NameGenerator.generate_with_seed(42)
      # Returns the same name both times

  """
  def generate_with_seed(seed) do
    :rand.seed(:exsss, {seed, seed, seed})
    generate()
  end
end
