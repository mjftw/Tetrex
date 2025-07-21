defmodule TetrexWeb.ChatComponent do
  use TetrexWeb, :live_component

  alias Tetrex.ChatServer
  alias Tetrex.Users.UserStore

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:messages, [])
     |> assign(:chat_with_user_id, nil)
     |> assign(:chat_with_username, nil)
     |> assign(:message_content, "")}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Handle partial updates (like when only new_message is sent)
    cond do
      # If this is a username update for the user we're chatting with
      Map.has_key?(assigns, :updated_username) and
        Map.has_key?(assigns, :chat_with_user_id) and
          socket.assigns.chat_with_user_id == assigns.chat_with_user_id ->
        {:ok, assign(socket, :chat_with_username, assigns.updated_username)}

      # If this is just a new message update
      Map.has_key?(assigns, :new_message) and not is_nil(assigns.new_message) and
          not Map.has_key?(assigns, :current_user) ->
        message = assigns.new_message
        current_user = socket.assigns.current_user
        chat_with_user_id = socket.assigns.chat_with_user_id

        if not is_nil(chat_with_user_id) and
             ((message.from_user_id == chat_with_user_id and message.to_user_id == current_user.id) or
                (message.from_user_id == current_user.id and
                   message.to_user_id == chat_with_user_id)) do
          updated_messages = socket.assigns.messages ++ [message]

          {:ok,
           socket
           |> assign(:messages, updated_messages)
           |> push_event("scroll-to-bottom", %{})}
        else
          {:ok, socket}
        end

      # Full update with all assigns
      Map.has_key?(assigns, :current_user) ->
        current_user = assigns.current_user
        chat_open = assigns.chat_open
        chat_with_user_id = assigns.chat_with_user_id

        cond do
          chat_open == true and not is_nil(chat_with_user_id) ->
            target_user = UserStore.get_user!(chat_with_user_id)
            conversation = ChatServer.get_conversation(current_user.id, chat_with_user_id)

            {:ok,
             socket
             |> assign(:chat_with_username, target_user.username)
             |> assign(:messages, conversation.messages)
             |> push_event("scroll-to-bottom", %{})
             |> push_event("focus-input", %{})}

          true ->
            {:ok, socket}
        end

      true ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("send_message", _params, socket) do
    content = String.trim(socket.assigns.message_content)

    if String.length(content) > 0 and socket.assigns.chat_with_user_id do
      ChatServer.send_message(
        socket.assigns.current_user.id,
        socket.assigns.chat_with_user_id,
        content
      )

      send(self(), {:chat_sent, socket.assigns.chat_with_user_id})

      {:noreply,
       socket
       |> assign(:message_content, "")
       |> push_event("scroll-to-bottom", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_message", %{"value" => content}, socket) do
    {:noreply, assign(socket, :message_content, content)}
  end

  @impl true
  def handle_event("close_chat", _params, socket) do
    send(self(), :close_chat)
    {:noreply, socket}
  end

  # Helper functions
  def format_timestamp(timestamp) do
    timestamp
    |> DateTime.to_time()
    |> Time.to_string()
    # Show only HH:MM
    |> String.slice(0, 5)
  end

  def is_own_message?(message, current_user_id) do
    message.from_user_id == current_user_id
  end
end
