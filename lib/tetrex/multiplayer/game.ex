defmodule Tetrex.Multiplayer.Game do
  alias Tetrex.BoardServer
  alias Tetrex.Multiplayer.GameMessage

  @type player_status :: :not_ready | :ready | :playing | :dead
  @type game_status :: :players_joining | :all_ready | :playing | :finished
  @type id :: String.t()

  @type t :: %__MODULE__{
          game_id: id(),
          players: %{
            id() => %{
              board_pid: pid(),
              lines_cleared: non_neg_integer(),
              status: player_status(),
              online: boolean()
            }
          },
          status: game_status(),
          periodic_mover_pid: pid()
        }

  @enforce_keys [:game_id, :players, :status, :periodic_mover_pid]
  defstruct [:game_id, :players, :status, :periodic_mover_pid]

  def new(periodic_mover_pid) do
    %__MODULE__{
      game_id: UUID.uuid1(),
      players: %{},
      status: :players_joining,
      periodic_mover_pid: periodic_mover_pid
    }
  end

  def to_game_message(%__MODULE__{
        game_id: game_id,
        players: players,
        status: game_status
      }) do
    player_update =
      for {user_id,
           %{
             board_pid: board_pid,
             lines_cleared: lines_cleared,
             status: player_status
           }} <- players,
          into: %{},
          do:
            {user_id,
             %{
               board_preview: BoardServer.preview(board_pid),
               lines_cleared: lines_cleared,
               status: player_status
             }}

    %GameMessage{game_id: game_id, players: player_update, status: game_status}
  end

  def add_player(%__MODULE__{players: players} = game, user_id, board_pid),
    do: %__MODULE__{
      game
      | players:
          Map.put(players, user_id, %{
            board_pid: board_pid,
            lines_cleared: 0,
            status: :not_ready,
            online: true
          })
    }

  def drop_player(%__MODULE__{players: players} = game, user_id),
    do: %__MODULE__{
      game
      | players: Map.delete(players, user_id)
    }

  def player_in_game?(%__MODULE__{players: players}, user_id), do: Map.has_key?(players, user_id)

  def num_players(%__MODULE__{players: players}),
    do: Enum.count(players)

  def get_player_state(%__MODULE__{players: players}, user_id) do
    case Map.get(players, user_id) do
      nil -> {:error, :player_not_found}
      player -> {:ok, player}
    end
  end

  def increment_player_lines_cleared(%__MODULE__{} = game, user_id, extra_lines_cleared) do
    update_player_state(
      game,
      user_id,
      &%{&1 | lines_cleared: &1.lines_cleared + extra_lines_cleared}
    )
  end

  defp update_player_state(%__MODULE__{players: players} = game, user_id, update_fn) do
    with {:ok, player_state} <- get_player_state(game, user_id) do
      new_player_state = update_fn.(player_state)
      {:ok, %__MODULE__{game | players: Map.put(players, user_id, new_player_state)}}
    end
  end
end
