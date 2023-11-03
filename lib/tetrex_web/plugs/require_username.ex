defmodule CarsCommercePuzzleAdventureWeb.Plugs.RequireUsername do
  use CarsCommercePuzzleAdventureWeb, :verified_routes

  alias CarsCommercePuzzleAdventure.Users.UserStore

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    signup_path = ~p"/signup"

    if conn.request_path == signup_path do
      conn
    else
      case UserStore.get_user(user_id) do
        nil ->
          conn
          |> Phoenix.Controller.redirect(to: signup_path)

        _ ->
          conn
      end
    end
  end
end
