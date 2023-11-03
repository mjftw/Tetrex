import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/cars_commerce_puzzle_adventure start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :cars_commerce_puzzle_adventure, CarsCommercePuzzleAdventureWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :cars_commerce_puzzle_adventure,
    admin_panel_username: "admin"

  config :cars_commerce_puzzle_adventure,
    admin_panel_password: "password"

  secret_key_base = "g1eakvGzXLk2G1kOUJpEbilfr6dPdymxi3q4wnrgen2+if7cN2u3gAaSsEPc2BND"
  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :cars_commerce_puzzle_adventure, CarsCommercePuzzleAdventureWeb.Endpoint,
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: System.get_env("PORT") || 4000, compress: true],
    url: [host: "localhost", port: System.get_env("PORT") || 4000],
    check_origin: ["//*.fly.dev", "//localhost"],
    cache_static_manifest: "priv/static/cache_manifest.json",
    root: ".",
    secret_key_base: secret_key_base

  # url: [host: host, port: 443, scheme: "https"],
  # http: [
  #   # Enable IPv6 and bind on all interfaces.
  #   # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
  #   # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
  #   # for details about using IPv6 vs IPv4 and loopback vs public addresses.
  #   ip: {0, 0, 0, 0, 0, 0, 0, 0},
  #   port: port
  # ],

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :cars_commerce_puzzle_adventure, CarsCommercePuzzleAdventureWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :cars_commerce_puzzle_adventure, CarsCommercePuzzleAdventureWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
else
  config :cars_commerce_puzzle_adventure,
    admin_panel_username: System.get_env("ADMIN_PANEL_USERNAME", "admin"),
    admin_panel_password: System.get_env("ADMIN_PANEL_PASSWORD", "password")
end
