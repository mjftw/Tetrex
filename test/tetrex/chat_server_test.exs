defmodule Tetrex.ChatServerTest do
  use ExUnit.Case, async: true
  alias Tetrex.ChatServer
  alias Phoenix.PubSub

  setup do
    # Start a fresh ChatServer for each test
    {:ok, pid} = GenServer.start_link(ChatServer, %{})
    {:ok, chat_server: pid}
  end

  describe "basic functionality" do
    test "starts with empty state", %{chat_server: pid} do
      state = GenServer.call(pid, :debug_state)
      assert state.conversations == %{}
      assert state.unread_counts == %{}
    end

    test "sends a message between users", %{chat_server: pid} do
      GenServer.cast(pid, {:send_message, "user1", "user2", "Hello!"})

      # Wait for async cast to complete
      :timer.sleep(10)

      state = GenServer.call(pid, :debug_state)
      assert map_size(state.conversations) == 1

      [conv] = Map.values(state.conversations)
      assert length(conv.messages) == 1

      message = hd(conv.messages)
      assert message.from_user_id == "user1"
      assert message.to_user_id == "user2"
      assert message.content == "Hello!"
    end

    test "gets conversation between users", %{chat_server: pid} do
      # Send messages
      GenServer.cast(pid, {:send_message, "user1", "user2", "First"})
      GenServer.cast(pid, {:send_message, "user2", "user1", "Second"})
      GenServer.cast(pid, {:send_message, "user1", "user2", "Third"})

      :timer.sleep(50)

      conv = GenServer.call(pid, {:get_conversation, "user1", "user2"})

      assert length(conv.messages) == 3
      # Messages should be in chronological order (oldest first)
      assert Enum.at(conv.messages, 0).content == "First"
      assert Enum.at(conv.messages, 1).content == "Second"
      assert Enum.at(conv.messages, 2).content == "Third"
    end

    test "conversation key is symmetric", %{chat_server: pid} do
      GenServer.cast(pid, {:send_message, "user1", "user2", "Hello"})
      :timer.sleep(10)

      conv1 = GenServer.call(pid, {:get_conversation, "user1", "user2"})
      conv2 = GenServer.call(pid, {:get_conversation, "user2", "user1"})

      assert conv1 == conv2
    end
  end

  describe "unread count logic" do
    test "starts with no unread counts", %{chat_server: pid} do
      counts = GenServer.call(pid, {:get_unread_counts, "user1"})
      assert counts == %{}
    end

    test "increments unread count manually", %{chat_server: pid} do
      GenServer.cast(pid, {:increment_unread, "user2", "user1"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts == %{"user1" => 1}
    end

    test "increments unread count multiple times", %{chat_server: pid} do
      GenServer.cast(pid, {:increment_unread, "user2", "user1"})
      GenServer.cast(pid, {:increment_unread, "user2", "user1"})
      GenServer.cast(pid, {:increment_unread, "user2", "user1"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts == %{"user1" => 3}
    end

    test "tracks unread counts from different users separately", %{chat_server: pid} do
      GenServer.cast(pid, {:increment_unread, "user3", "user1"})
      GenServer.cast(pid, {:increment_unread, "user3", "user2"})
      GenServer.cast(pid, {:increment_unread, "user3", "user1"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user3"})
      assert counts == %{"user1" => 2, "user2" => 1}
    end

    test "marks messages as read", %{chat_server: pid} do
      GenServer.cast(pid, {:increment_unread, "user2", "user1"})
      GenServer.cast(pid, {:increment_unread, "user2", "user1"})
      :timer.sleep(10)

      counts_before = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts_before == %{"user1" => 2}

      GenServer.cast(pid, {:mark_as_read, "user2", "user1"})
      :timer.sleep(10)

      counts_after = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts_after == %{}
    end

    test "marking as read only affects specific user pair", %{chat_server: pid} do
      GenServer.cast(pid, {:increment_unread, "user3", "user1"})
      GenServer.cast(pid, {:increment_unread, "user3", "user2"})
      :timer.sleep(10)

      GenServer.cast(pid, {:mark_as_read, "user3", "user1"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user3"})
      assert counts == %{"user2" => 1}
    end
  end

  describe "message sending vs unread count behavior" do
    test "sending message DOES automatically increment unread count", %{chat_server: pid} do
      # Fixed: messages SHOULD auto-increment unread count to prevent multiple LiveView race conditions
      GenServer.cast(pid, {:send_message, "user1", "user2", "Hello!"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts == %{"user1" => 1}, "Sending message should auto-increment unread count"

      state = GenServer.call(pid, :debug_state)
      assert map_size(state.conversations) == 1, "Message should still be stored"
    end

    test "unread count increments automatically when sending messages", %{
      chat_server: pid
    } do
      # Send message (should auto-increment count now)
      GenServer.cast(pid, {:send_message, "user1", "user2", "Hello!"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts == %{"user1" => 1}

      # Send another message (should increment to 2)
      GenServer.cast(pid, {:send_message, "user1", "user2", "Hello again!"})
      :timer.sleep(10)

      counts = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts == %{"user1" => 2}
    end

    test "multiple messages DO accumulate unread count correctly", %{
      chat_server: pid
    } do
      GenServer.cast(pid, {:send_message, "user1", "user2", "Message 1"})
      GenServer.cast(pid, {:send_message, "user1", "user2", "Message 2"})
      GenServer.cast(pid, {:send_message, "user1", "user2", "Message 3"})
      :timer.sleep(50)

      counts = GenServer.call(pid, {:get_unread_counts, "user2"})
      assert counts == %{"user1" => 3}, "3 messages should result in unread count of 3"

      # Verify messages were stored
      conv = GenServer.call(pid, {:get_conversation, "user1", "user2"})
      assert length(conv.messages) == 3
    end
  end

  describe "pubsub behavior" do
    setup do
      # Start PubSub for testing
      start_supervised!({Phoenix.PubSub, name: TestPubSub})
      :ok
    end

    @tag :skip
    test "sends pubsub messages when sending chat message", %{chat_server: pid} do
      # Skip: This test requires making ChatServer PubSub-configurable
      # The test ChatServer instance uses a different PubSub than TestPubSub
      # Subscribe to both user topics
      Phoenix.PubSub.subscribe(TestPubSub, "chat:user1")
      Phoenix.PubSub.subscribe(TestPubSub, "chat:user2")

      # Mock the PubSub name in ChatServer
      # Note: This test would need the ChatServer to be configurable for PubSub name
      # For now, this is a conceptual test showing what should happen

      GenServer.cast(pid, {:send_message, "user1", "user2", "Test message"})

      # Should receive messages on both topics
      assert_receive {:new_chat_message,
                      %{content: "Test message", from_user_id: "user1", to_user_id: "user2"}}

      assert_receive {:new_chat_message,
                      %{content: "Test message", from_user_id: "user1", to_user_id: "user2"}}
    end
  end

  describe "edge cases" do
    test "empty message content is trimmed", %{chat_server: pid} do
      GenServer.cast(pid, {:send_message, "user1", "user2", "  \n  "})
      :timer.sleep(10)

      conv = GenServer.call(pid, {:get_conversation, "user1", "user2"})
      assert length(conv.messages) == 1
      assert hd(conv.messages).content == ""
    end

    test "handles same user messaging themselves", %{chat_server: pid} do
      GenServer.cast(pid, {:send_message, "user1", "user1", "Self message"})
      :timer.sleep(10)

      conv = GenServer.call(pid, {:get_conversation, "user1", "user1"})
      assert length(conv.messages) == 1
      assert hd(conv.messages).from_user_id == "user1"
      assert hd(conv.messages).to_user_id == "user1"
    end

    test "gets empty conversation for users with no history", %{chat_server: pid} do
      conv = GenServer.call(pid, {:get_conversation, "new_user1", "new_user2"})
      assert conv.messages == []
      assert conv.participants == ["new_user1", "new_user2"]
    end
  end
end
