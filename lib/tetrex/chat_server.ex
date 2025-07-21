defmodule Tetrex.ChatServer do
  @moduledoc """
  GenServer that manages chat conversations between users.
  Stores message history and provides real-time messaging via PubSub.
  """
  use GenServer

  alias Phoenix.PubSub

  @type message :: %{
          id: String.t(),
          from_user_id: String.t(),
          to_user_id: String.t(),
          content: String.t(),
          timestamp: DateTime.t()
        }

  @type conversation :: %{
          participants: [String.t()],
          messages: [message()]
        }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put(opts, :name, __MODULE__))
  end

  @doc """
  Send a chat message between two users
  """
  def send_message(from_user_id, to_user_id, content) when is_binary(content) do
    GenServer.cast(__MODULE__, {:send_message, from_user_id, to_user_id, content})
  end

  @doc """
  Get chat history between two users
  """
  def get_conversation(user_id_1, user_id_2) do
    GenServer.call(__MODULE__, {:get_conversation, user_id_1, user_id_2})
  end

  @doc """
  Subscribe to chat updates for a user
  """
  def subscribe_user_chats(user_id) do
    PubSub.subscribe(Tetrex.PubSub, chat_topic(user_id))
  end

  @doc """
  Unsubscribe from chat updates for a user
  """
  def unsubscribe_user_chats(user_id) do
    PubSub.unsubscribe(Tetrex.PubSub, chat_topic(user_id))
  end

  @doc """
  Subscribe to username change notifications globally
  """
  def subscribe_username_changes() do
    PubSub.subscribe(Tetrex.PubSub, "username_changes")
  end

  @doc """
  Unsubscribe from username change notifications
  """
  def unsubscribe_username_changes() do
    PubSub.unsubscribe(Tetrex.PubSub, "username_changes")
  end

  @doc """
  Broadcast a username change to all subscribers
  """
  def broadcast_username_change(user_id, old_username, new_username) do
    PubSub.broadcast!(
      Tetrex.PubSub,
      "username_changes",
      {:username_changed,
       %{user_id: user_id, old_username: old_username, new_username: new_username}}
    )
  end

  @doc """
  Get unread message counts for a user
  """
  def get_unread_counts(user_id) do
    GenServer.call(__MODULE__, {:get_unread_counts, user_id})
  end

  @doc """
  Mark messages as read between two users
  """
  def mark_as_read(user_id, from_user_id) do
    GenServer.cast(__MODULE__, {:mark_as_read, user_id, from_user_id})
  end

  # Private functions

  defp chat_topic(user_id), do: "chat:#{user_id}"

  defp conversation_key(user_id_1, user_id_2) do
    [user_id_1, user_id_2] |> Enum.sort() |> Enum.join(":")
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{conversations: %{}, unread_counts: %{}}}
  end

  @impl true
  def handle_cast({:send_message, from_user_id, to_user_id, content}, state) do
    message = %{
      id: UUID.uuid4(),
      from_user_id: from_user_id,
      to_user_id: to_user_id,
      content: String.trim(content),
      timestamp: DateTime.utc_now()
    }

    conv_key = conversation_key(from_user_id, to_user_id)

    # Add message to conversation (append to end for chronological order)
    updated_conversations =
      Map.update(
        state.conversations,
        conv_key,
        %{participants: [from_user_id, to_user_id], messages: [message]},
        fn conv -> %{conv | messages: conv.messages ++ [message]} end
      )

    unread_key = "#{to_user_id}:#{from_user_id}"
    updated_unread_counts = Map.update(state.unread_counts, unread_key, 1, &(&1 + 1))

    # Publish message to both users via PubSub
    PubSub.broadcast!(Tetrex.PubSub, chat_topic(from_user_id), {:new_chat_message, message})
    PubSub.broadcast!(Tetrex.PubSub, chat_topic(to_user_id), {:new_chat_message, message})

    {:noreply,
     %{state | conversations: updated_conversations, unread_counts: updated_unread_counts}}
  end

  @impl true
  def handle_cast({:increment_unread, user_id, from_user_id}, state) do
    unread_key = "#{user_id}:#{from_user_id}"
    updated_unread_counts = Map.update(state.unread_counts, unread_key, 1, &(&1 + 1))

    {:noreply, %{state | unread_counts: updated_unread_counts}}
  end

  @impl true
  def handle_call({:get_conversation, user_id_1, user_id_2}, _from, state) do
    conv_key = conversation_key(user_id_1, user_id_2)

    conversation =
      Map.get(state.conversations, conv_key, %{
        participants: [user_id_1, user_id_2],
        messages: []
      })

    # Messages are already in chronological order (oldest first)
    {:reply, conversation, state}
  end

  @impl true
  def handle_call({:get_unread_counts, user_id}, _from, state) do
    # Get all unread counts for this user (as recipient)
    user_prefix = "#{user_id}:"

    unread_counts =
      state.unread_counts
      |> Enum.filter(fn {key, _count} -> String.starts_with?(key, user_prefix) end)
      |> Enum.map(fn {key, count} ->
        from_user_id = String.replace_prefix(key, user_prefix, "")
        {from_user_id, count}
      end)
      |> Enum.into(%{})

    {:reply, unread_counts, state}
  end

  @impl true
  def handle_cast({:mark_as_read, user_id, from_user_id}, state) do
    unread_key = "#{user_id}:#{from_user_id}"
    updated_unread_counts = Map.delete(state.unread_counts, unread_key)

    {:noreply, %{state | unread_counts: updated_unread_counts}}
  end

  # New public API for incrementing unread count
  @doc """
  Increment unread count for a message (called by LiveView when appropriate)
  """
  def increment_unread(user_id, from_user_id) do
    GenServer.cast(__MODULE__, {:increment_unread, user_id, from_user_id})
  end

  # Debug function
  def debug_state do
    GenServer.call(__MODULE__, :debug_state)
  end

  @impl true
  def handle_call(:debug_state, _from, state) do
    {:reply, state, state}
  end
end
