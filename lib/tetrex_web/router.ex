defmodule TetrexWeb.Router do
  use TetrexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TetrexWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "x-frame-options" => "ALLOW-FROM https://mjftw.dev",
      "content-security-policy" => "frame-ancestors 'self' https://mjftw.dev"
    }

    plug TetrexWeb.Plugs.UserSession
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :default do
    scope "/", TetrexWeb do
      pipe_through :browser

      live "/admin", AdminLive

      live "/single-player-game", SinglePlayerGameLive
      live "/multiplayer-game/:game_id", MultiplayerGameLive
      live "/", LobbyLive

      get "/home", PageController, :home
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TetrexWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:tetrex, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: TetrexWeb.Telemetry
    end
  end
end
