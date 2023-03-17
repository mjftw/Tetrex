defmodule Tetrex.Application do
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
      Tetrex.GameDynamicSupervisor,
      # Start the Telemetry supervisor
      TetrexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tetrex.PubSub},
      # Start the Presence module
      TetrexWeb.Presence,
      # Start the Endpoint (http/https)
      TetrexWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tetrex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TetrexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
