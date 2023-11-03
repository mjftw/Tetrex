# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cars_commerce_puzzle_adventure, :settings,
  multiplayer: [
    # Maximum players in game.
    max_players_in_game: 99,
    # The number of opponent boards to render. Increasing this number makes rendering more expensive,
    # and puts more load on the client browser.
    # Cannot be greater than :max_players_in_game
    num_opponent_boards_to_show: 98,
    # The probability of sending a blocking row to another player when a
    # line is cleared
    send_blocking_row_probability: 1,
    # How many times per second to update the browser game views
    rate_limit_max_updates_per_sec: 20
  ]

# Configures the endpoint
config :cars_commerce_puzzle_adventure, CarsCommercePuzzleAdventureWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: CarsCommercePuzzleAdventureWeb.ErrorHTML, json: CarsCommercePuzzleAdventureWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CarsCommercePuzzleAdventure.PubSub,
  live_view: [signing_salt: "BCIQ6//6"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure version bumping
config :versioce,
  pre_hooks: [CarsCommercePuzzleAdventure.Versioce.PreHooks.GitCheckUncommitted],
  post_hooks: [
    CarsCommercePuzzleAdventure.Versioce.PostHooks.GitCommitUpdate,
    CarsCommercePuzzleAdventure.Versioce.PostHooks.GitTag
  ]

config :versioce, :changelog,
  datagrabber: Versioce.Changelog.DataGrabber.Git,
  formatter: Versioce.Changelog.Formatter.Keepachangelog,
  anchors: %{
    added: ["Added:", "added:"],
    changed: ["Changed:", "changed:"],
    deprecated: ["Depreciated:", "depreciated:"],
    removed: ["Removed:", "removed:"],
    fixed: ["Fixed:", "fixed:"],
    security: ["Security:", "security:"]
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
