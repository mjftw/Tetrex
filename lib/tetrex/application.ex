defmodule CarsCommerceTetris.Application do
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
      CarsCommerceTetris.GameDynamicSupervisor,
      # Start the UserStore store
      CarsCommerceTetris.Users.UserStore,
      # Start the Telemetry supervisor
      CarsCommerceTetrisWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CarsCommerceTetris.PubSub},
      # Start the Presence module
      CarsCommerceTetrisWeb.Presence,
      # Start the Endpoint (http/https)
      CarsCommerceTetrisWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CarsCommerceTetris.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CarsCommerceTetrisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
