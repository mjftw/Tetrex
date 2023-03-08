defmodule Tetrex.GameRegistry do
  alias Tetrex.SinglePlayer.GameServer

  def start_new_game(user_id) do
    # TODO: Start under a dynamic supervisor rather than unlinked
    GameServer.start(name: {:via, Registry, {Tetrex.GameRegistry, user_id}})
    user_games(user_id)
  end

  def user_has_game?(user_id) do
    user_id
    |> user_games()
    |> Enum.count() > 0
  end

  def user_games(user_id) do
    Registry.lookup(Tetrex.GameRegistry, user_id)
  end

  def remove_game(user_id) do
    case Registry.lookup(Tetrex.GameRegistry, user_id) do
      [{game_server_pid, _}] -> Process.exit(game_server_pid, :kill)
    end
  end
end
