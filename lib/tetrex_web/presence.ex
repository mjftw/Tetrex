defmodule TetrexWeb.Presence do
  use Phoenix.Presence,
    otp_app: :tetrex,
    pubsub_server: Tetrex.PubSub
end
