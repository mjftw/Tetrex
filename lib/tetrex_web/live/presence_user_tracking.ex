defmodule TetrexWeb.PresenceUserTracking do
  @moduledoc """
    Use this module to automatically add user tracking via Phoenix Presence to your LiveView
    To use, make sure to call `mount_presence_init` at the end of your LiveView's `mount` function.

    Opts:
      module: Your Phoenix Presence module,
      topic: The topic to publish/subscribe to presence updates on,
      socket_current_user_assign_key: The key in the socket assigns where the current user can be found,
      socket_users_assign_key: The key in the socket assigns where the present users list should be stored
  """
  @spec __using__(any) :: {:__block__, [], [{:=, [], [...]} | {:__block__, [...], [...]}, ...]}
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      presence_module = Keyword.fetch!(opts, :module)
      presence_topic = Keyword.fetch!(opts, :topic)
      presence_current_user_assign_key = Keyword.fetch!(opts, :socket_current_user_assign_key)
      presence_users_assign_key = Keyword.fetch!(opts, :socket_users_assign_key)

      def mount_presence_init(socket) do
        if connected?(socket) do
          {:ok, _} =
            unquote(presence_module).track(
              self(),
              unquote(presence_topic),
              socket.assigns[unquote(presence_current_user_assign_key)],
              %{
                joined_at: inspect(System.system_time(:second))
              }
            )

          Phoenix.PubSub.subscribe(Tetrex.PubSub, unquote(presence_topic))
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
