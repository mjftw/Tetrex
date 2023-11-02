defmodule CarsCommerceTetrisWeb.Presence do
  use Phoenix.Presence,
    otp_app: :cars_commerce_tetris,
    pubsub_server: CarsCommerceTetris.PubSub
end
