defmodule Tetrex.Multiplayer.Game do
  alias Tetrex.BoardServer
  alias Tetrex.Multiplayer.GameMessage

  @type player_status :: :not_ready | :ready | :dead
  @type game_status :: :players_joining | :playing | :finished | :exiting
  @type id :: String.t()

  @type t :: %__MODULE__{
          game_id: id(),
          players: %{
            id() => %{
              board_pid: pid(),
              periodic_mover_pid: pid(),
              lines_cleared: non_neg_integer(),
              status: player_status(),
              online: boolean()
            }
          },
          status: game_status(),
          periodic_timer_period: non_neg_integer()
        }

  @enforce_keys [:game_id, :players, :status, :periodic_timer_period]
  defstruct [:game_id, :players, :status, :periodic_timer_period]

  def new(periodic_timer_period) do
    %__MODULE__{
      game_id: UUID.uuid1(),
      players: %{},
      status: :players_joining,
      periodic_timer_period: periodic_timer_period
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

  def add_player(%__MODULE__{players: players} = game, user_id, board_pid, periodic_mover_pid),
    do: %__MODULE__{
      game
      | players:
          Map.put(players, user_id, %{
            board_pid: board_pid,
            periodic_mover_pid: periodic_mover_pid,
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

  def alive_players(%__MODULE__{players: players}),
    do: players |> Enum.filter(fn {_user_id, player_state} -> player_alive?(player_state) end)

  def num_alive_players(%__MODULE__{players: players}),
    do: players |> Enum.count(fn {_user_id, player_state} -> player_alive?(player_state) end)

  def get_player_state(%__MODULE__{players: players}, user_id) do
    case Map.get(players, user_id) do
      nil -> {:error, :player_not_found}
      player -> {:ok, player}
    end
  end

  def kill_player(%__MODULE__{} = game, user_id) do
    update_player_state(
      game,
      user_id,
      &%{&1 | status: :dead}
    )
  end

  def set_player_ready(%__MODULE__{} = game, user_id, is_ready?) do
    update_player_state(
      game,
      user_id,
      &%{
        &1
        | status:
            case {&1.status, is_ready?} do
              {:not_ready, true} -> :ready
              {:ready, true} -> :ready
              {:ready, false} -> :not_ready
              {:dead, _} -> :dead
            end
      }
    )
  end

  def increment_player_lines_cleared(%__MODULE__{} = game, user_id, extra_lines_cleared) do
    update_player_state(
      game,
      user_id,
      &%{&1 | lines_cleared: &1.lines_cleared + extra_lines_cleared}
    )
  end

  def start(%__MODULE__{} = game), do: %__MODULE__{game | status: :playing}

  def ready_to_start?(%__MODULE__{players: players, status: status}) do
    status == :players_joining &&
      Enum.all?(players, fn {_user_id, player_state} -> player_ready?(player_state) end)
  end

  def players_can_leave?(%__MODULE__{status: status})
      when status in [:players_joining, :finished],
      do: true

  def players_can_leave?(%__MODULE__{}), do: false

  def has_started?(%__MODULE__{status: status}) when status == :players_joining, do: false
  def has_started?(%__MODULE__{}), do: true

  defp player_ready?(player_state) do
    player_state.status in [:ready, :dead]
  end

  defp player_alive?(player_state) do
    player_state.status != :dead
  end

  defp update_player_state(%__MODULE__{players: players} = game, user_id, update_fn) do
    with {:ok, player_state} <- get_player_state(game, user_id) do
      new_player_state = update_fn.(player_state)
      {:ok, %__MODULE__{game | players: Map.put(players, user_id, new_player_state)}}
    end
  end

  def finish_if_required(%__MODULE__{players: players, status: :playing} = game) do
    num_players_alive =
      players
      |> Stream.filter(fn {_user_id, %{status: status}} -> status == :ready end)
      |> Enum.count()

    num_players_dead =
      players
      |> Stream.filter(fn {_user_id, %{status: status}} -> status == :dead end)
      |> Enum.count()

    if num_players_alive == 1 && num_players_dead > 0 do
      %__MODULE__{game | status: :finished}
    else
      game
    end
  end

  def finish_if_required(%__MODULE__{} = game), do: game

  def set_exiting(%__MODULE__{} = game), do: %__MODULE__{game | status: :exiting}

  def exiting?(%__MODULE__{status: :exiting}), do: true
  def exiting?(%__MODULE__{}), do: false
end
