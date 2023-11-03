defmodule CarsCommercePuzzleAdventureWeb.Router do
  use CarsCommercePuzzleAdventureWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CarsCommercePuzzleAdventureWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CarsCommercePuzzleAdventureWeb.Plugs.UserSession
    plug CarsCommercePuzzleAdventureWeb.Plugs.RequireUsername
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :default do
    scope "/", CarsCommercePuzzleAdventureWeb do
      pipe_through :browser

      live "/admin", AdminLive
      live "/signup", SignupLive
      live "/single-player-game", SinglePlayerGameLive
      live "/multiplayer-game/:game_id", MultiplayerGameLive
      live "/", LobbyLive

      get "/home", PageController, :home
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", CarsCommercePuzzleAdventureWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:cars_commerce_puzzle_adventure, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CarsCommercePuzzleAdventureWeb.Telemetry
    end
  end
end
