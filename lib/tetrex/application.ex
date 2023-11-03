defmodule CarsCommercePuzzleAdventure.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Allow monitoring processes
      ProcessMonitor,
      # Start a dynamic supervisor to start games under
      CarsCommercePuzzleAdventure.GameDynamicSupervisor,
      # Start the UserStore store
      CarsCommercePuzzleAdventure.Users.UserStore,
      # Start the Telemetry supervisor
      CarsCommercePuzzleAdventureWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CarsCommercePuzzleAdventure.PubSub},
      # Start the Presence module
      CarsCommercePuzzleAdventureWeb.Presence,
      # Start the Endpoint (http/https)
      CarsCommercePuzzleAdventureWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CarsCommercePuzzleAdventure.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CarsCommercePuzzleAdventureWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
