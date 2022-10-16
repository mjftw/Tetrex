defmodule Tetrex.Repo do
  use Ecto.Repo,
    otp_app: :tetrex,
    adapter: Ecto.Adapters.Postgres
end
