defmodule Tetrex.Users.UserStoreTest do
  use ExUnit.Case, async: false
  alias Tetrex.Users.{UserStore, User}

  setup do
    UserStore.clear()
    :ok
  end

  describe "user management" do
    test "starts empty" do
      assert UserStore.all_users() == %{}
    end

    test "puts and gets users" do
      UserStore.put_user("user1", "Alice")
      user = UserStore.get_user("user1")

      assert user.id == "user1"
      assert user.username == "Alice"
    end

    test "get_user returns nil for non-existent user" do
      assert UserStore.get_user("non_existent") == nil
    end

    test "get_user! raises for non-existent user" do
      assert_raise RuntimeError, "No user", fn ->
        UserStore.get_user!("non_existent")
      end
    end

    test "clear removes all users" do
      UserStore.put_user("user1", "Alice")
      UserStore.put_user("user2", "Bob")

      assert map_size(UserStore.all_users()) == 2

      UserStore.clear()
      assert UserStore.all_users() == %{}
    end

    test "all_users returns all stored users" do
      UserStore.put_user("user1", "Alice")
      UserStore.put_user("user2", "Bob")

      all = UserStore.all_users()
      assert map_size(all) == 2
      assert all["user1"].username == "Alice"
      assert all["user2"].username == "Bob"
    end

    test "overwrites existing user with same ID" do
      UserStore.put_user("user1", "Alice")
      UserStore.put_user("user1", "Alice Updated")

      user = UserStore.get_user("user1")
      assert user.username == "Alice Updated"
      assert map_size(UserStore.all_users()) == 1
    end
  end
end
