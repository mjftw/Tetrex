defmodule Tetrex.GameRegistry do
  alias Tetrex.GameServer

  def start_new_game(player_id) do
    # TODO: Start under a dynamic supervisor rather than unlinked
    GameServer.start(name: {:via, Registry, {Tetrex.GameRegistry, player_id}})
    user_games(player_id)
  end

  def user_has_game?(player_id) do
    player_id
    |> user_games()
    |> Enum.count() > 0
  end

  def user_games(player_id) do
    Registry.lookup(Tetrex.GameRegistry, player_id)
  end

  def remove_game(player_id) do
    case Registry.lookup(Tetrex.GameRegistry, player_id) do
      [{game_server_pid, _}] -> Process.exit(game_server_pid, :kill)
    end
  end
end
