defmodule CarsCommercePuzzleAdventureWeb.Presence do
  use Phoenix.Presence,
    otp_app: :cars_commerce_puzzle_adventure,
    pubsub_server: CarsCommercePuzzleAdventure.PubSub
end
