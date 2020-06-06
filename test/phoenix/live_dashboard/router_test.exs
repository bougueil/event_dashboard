defmodule EventDashboard.RouterTest do
  use ExUnit.Case, async: true

  alias EventDashboard.Router

  test "default options" do
    assert Router.__options__([]) == [
             session: {EventDashboard.Router, :__session__, [nil, nil]},
             private: %{live_socket_path: "/live"},
             layout: {EventDashboard.LayoutView, :dash},
             as: :live_dashboard
           ]
  end

  test "configures live_socket_path" do
    assert Router.__options__(live_socket_path: "/custom/live")[:private] ==
             %{live_socket_path: "/custom/live"}
  end

  test "configures metrics" do
    assert Router.__options__(metrics: Foo)[:session] ==
             {EventDashboard.Router, :__session__, [{Foo, :metrics}, nil]}

    assert Router.__options__(metrics: {Foo, :bar})[:session] ==
             {EventDashboard.Router, :__session__, [{Foo, :bar}, nil]}

    assert_raise ArgumentError, fn ->
      Router.__options__(metrics: [])
    end
  end

  test "configures env_keys" do
    assert Router.__options__(env_keys: ["USER", "ROOTDIR"])[:session] ==
             {EventDashboard.Router, :__session__, [nil, ["USER", "ROOTDIR"]]}

    assert_raise ArgumentError, fn ->
      Router.__options__(env_keys: "FOO")
    end
  end
end
