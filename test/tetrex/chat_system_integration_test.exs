defmodule Tetrex.ChatSystemIntegrationTest do
  # Changed to false to avoid state conflicts
  use ExUnit.Case, async: false
  alias Tetrex.{ChatServer, Users.UserStore, Users.User}

  setup do
    # Clear state between tests
    UserStore.clear()
    # We can't easily clear ChatServer state without restarting it,
    # so we use unique user IDs per test
    test_id = :erlang.unique_integer([:positive])
    {:ok, test_id: test_id}
  end

  describe "chat system integration" do
    test "complete message flow works correctly" do
      # Setup users
      user1_id = "user1"
      user2_id = "user2"
      UserStore.put_user(user1_id, "Alice")
      UserStore.put_user(user2_id, "Bob")

      # Verify users exist
      alice = UserStore.get_user!(user1_id)
      bob = UserStore.get_user!(user2_id)
      assert alice.username == "Alice"
      assert bob.username == "Bob"

      # Send messages
      ChatServer.send_message(user1_id, user2_id, "Hello Bob!")
      ChatServer.send_message(user2_id, user1_id, "Hi Alice!")
      ChatServer.send_message(user1_id, user2_id, "How are you?")

      :timer.sleep(50)

      # Check conversation
      conversation = ChatServer.get_conversation(user1_id, user2_id)
      assert length(conversation.messages) == 3

      # Messages should be in chronological order
      [msg1, msg2, msg3] = conversation.messages
      assert msg1.content == "Hello Bob!"
      assert msg1.from_user_id == user1_id
      assert msg1.to_user_id == user2_id

      assert msg2.content == "Hi Alice!"
      assert msg2.from_user_id == user2_id
      assert msg2.to_user_id == user1_id

      assert msg3.content == "How are you?"
      assert msg3.from_user_id == user1_id
      assert msg3.to_user_id == user2_id

      # Check unread counts (Bob should have 2 unread from Alice)
      bob_unreads = ChatServer.get_unread_counts(user2_id)
      alice_unreads = ChatServer.get_unread_counts(user1_id)

      # 2 messages from Alice
      assert bob_unreads == %{user1_id => 2}
      # 1 message from Bob
      assert alice_unreads == %{user2_id => 1}

      # Mark Bob's messages as read
      ChatServer.mark_as_read(user2_id, user1_id)

      # Check unread counts are cleared
      bob_unreads_after = ChatServer.get_unread_counts(user2_id)
      assert bob_unreads_after == %{}

      # Alice's unreads should remain
      alice_unreads_after = ChatServer.get_unread_counts(user1_id)
      assert alice_unreads_after == %{user2_id => 1}
    end

    test "chat server handles edge cases correctly", %{test_id: test_id} do
      user1 = "edge_test_user1_#{test_id}"
      user2 = "edge_test_user2_#{test_id}"

      # Empty message
      ChatServer.send_message(user1, user2, "")
      :timer.sleep(10)

      conv = ChatServer.get_conversation(user1, user2)
      assert length(conv.messages) == 1
      assert hd(conv.messages).content == ""

      # Self-messaging
      ChatServer.send_message(user1, user1, "Note to self")
      :timer.sleep(10)

      self_conv = ChatServer.get_conversation(user1, user1)
      assert length(self_conv.messages) == 1
      assert hd(self_conv.messages).content == "Note to self"

      # Non-existent conversation
      new1 = "new_user1_#{test_id}"
      new2 = "new_user2_#{test_id}"
      empty_conv = ChatServer.get_conversation(new1, new2)
      assert empty_conv.messages == []
      assert empty_conv.participants == [new1, new2]
    end

    test "unread counts work correctly with multiple senders" do
      # User3 receives messages from multiple users
      ChatServer.send_message("user1", "user3", "From user1")
      ChatServer.send_message("user2", "user3", "From user2")
      ChatServer.send_message("user1", "user3", "Another from user1")

      :timer.sleep(50)

      unreads = ChatServer.get_unread_counts("user3")
      assert unreads == %{"user1" => 2, "user2" => 1}

      # Mark one sender as read
      ChatServer.mark_as_read("user3", "user1")

      unreads_after = ChatServer.get_unread_counts("user3")
      assert unreads_after == %{"user2" => 1}
    end

    test "conversation keys are symmetric" do
      ChatServer.send_message("alice", "bob", "Hello")
      :timer.sleep(10)

      conv1 = ChatServer.get_conversation("alice", "bob")
      conv2 = ChatServer.get_conversation("bob", "alice")

      assert conv1 == conv2
      assert length(conv1.messages) == 1
    end
  end
end
