defmodule TetrexWeb.Presence do
  use Phoenix.Presence,
    otp_app: :tetrex,
    pubsub_server: Tetrex.PubSub

  def all_rooms, do: "room:*"

  def channel_name(room_type), do: "room:#{room_type}"

  def track_room(player_id, room_type, game_pid \\ nil) do
    {:ok, _} =
      track(self(), "room:#{room_type}", player_id, %{
        joined_at: inspect(System.system_time(:second)),
        room_type: room_type,
        game_pid: game_pid
      })
  end
end
