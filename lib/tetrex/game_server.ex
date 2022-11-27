defmodule Tetrex.GameServer do
  use GenServer
  alias Tetrex.BoardServer

  @type init_args :: [
          board_height: non_neg_integer(),
          board_width: non_neg_integer(),
          random_seed: non_neg_integer()
        ]

  # Client API

  @spec start_link(init_args()) :: pid()
  def start_link(opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, opts)
    pid
  end

  @impl true
  @spec init(init_args()) :: any
  def init(opts \\ []) do
    defaults = [board_height: 20, board_width: 10, random_seed: Enum.random(0..10_000_000)]
    options = Keyword.merge(defaults, opts)

    children = [
      {BoardServer, options}
    ]

    GenServer.start_link(children, strategy: :one_for_all)
  end
end
