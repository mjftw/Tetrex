defmodule CarsCommercePuzzleAdventureWeb.Plugs.UserSession do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        put_session(conn, :user_id, generate_user_id())

      _ ->
        conn
    end
  end

  defp generate_user_id(), do: UUID.uuid1()
end
