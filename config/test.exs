import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cars_commerce_puzzle_adventure, CarsCommercePuzzleAdventureWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Yt5vA09bckVmrvDJS7QEgwrsYaYjLGkaRxcYGZFyBEHa21JEdbongbNfjfubYCh2",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
