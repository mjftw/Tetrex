defmodule Tetrex.GameRegistry do
  alias Tetrex.GameServer

  def start_new_game(player_id) do
    # TODO: Start under a dynamic supervisor rather than unlinked
    GameServer.start(name: {:via, Registry, {Tetrex.GameRegistry, player_id}})
    user_games(player_id) |> IO.inspect()
  end

  def user_has_game?(player_id) do
    player_id
    |> user_games()
    |> Enum.count() > 0
  end

  def user_games(player_id) do
    Registry.lookup(Tetrex.GameRegistry, player_id)
  end
end
