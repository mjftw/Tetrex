defmodule CarsCommercePuzzleAdventure.Users.UserStore do
  alias CarsCommercePuzzleAdventure.Users.User
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_user(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
  end

  def get_user!(user_id) do
    case get_user(user_id) do
      nil -> raise "No user"
      user -> user
    end
  end

  def put_user(user_id, username) when is_binary(username) do
    Agent.update(
      __MODULE__,
      &Map.put(&1, user_id, %User{id: user_id, username: username})
    )
  end
end
