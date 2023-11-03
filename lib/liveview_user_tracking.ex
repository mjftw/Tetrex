defmodule LiveViewUserTracking do
  @moduledoc """
    Use this module to automatically add user tracking via Phoenix Presence to your LiveView.

    Example usage:
    ```
      defmodule MyAppWeb.LobbyLive do
        use MyAppWeb, :live_view

        use PresenceUserTracking,
          # Your Phoenix Presence module
          presence: MyAppWeb.Presence,
          # The topic to publish/subscribe to presence updates on
          topic: "room:lobby",
          # The key in the socket assigns to read current user from
          socket_current_user_assign_key: :current_user,
          # The key in the socket assigns to write store the present users list
          socket_users_assign_key: :users

        @impl true
        def mount(_params, %{"user_id" => user_id} = _session, socket) do
          {:ok,
          socket
          |> assign(:current_user, %CarsCommercePuzzleAdventure.Users.User{id: user_id, username: "James"})
          |> mount_presence_init()}
        end
      end
    ```
  """
  alias CarsCommercePuzzleAdventure.Users.User

  @spec __using__(any) :: {:__block__, [], [{:=, [], [...]} | {:__block__, [...], [...]}, ...]}
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      presence_module = Keyword.fetch!(opts, :presence)
      presence_topic = Keyword.fetch!(opts, :topic)

      presence_current_user_assign_key = Keyword.fetch!(opts, :socket_current_user_assign_key)

      presence_users_assign_key = Keyword.fetch!(opts, :socket_users_assign_key)

      def mount_presence_init(socket) do
        if connected?(socket) do
          %User{id: current_user_id} =
            user = socket.assigns[unquote(presence_current_user_assign_key)]

          {:ok, _} =
            unquote(presence_module).track(
              self(),
              unquote(presence_topic),
              current_user_id,
              %{
                user: user,
                joined_at: inspect(System.system_time(:second))
              }
            )

          Phoenix.PubSub.subscribe(CarsCommercePuzzleAdventure.PubSub, unquote(presence_topic))
        end

        handle_presence_joins(socket, unquote(presence_module).list(unquote(presence_topic)))
      end

      @impl true
      def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
        {
          :noreply,
          socket
          |> handle_joins_leaves(diff.leaves)
          |> handle_presence_joins(diff.joins)
        }
      end

      defp handle_presence_joins(socket, joins) do
        Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
          assign(
            socket,
            unquote(presence_users_assign_key),
            Map.put(socket.assigns[unquote(presence_users_assign_key)], user, meta)
          )
        end)
      end

      defp handle_joins_leaves(socket, leaves) do
        Enum.reduce(leaves, socket, fn {user, _}, socket ->
          assign(
            socket,
            unquote(presence_users_assign_key),
            Map.delete(socket.assigns[unquote(presence_users_assign_key)], user)
          )
        end)
      end
    end
  end
end
