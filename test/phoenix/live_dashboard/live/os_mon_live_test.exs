defmodule EventDashboard.OSMonLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint EventDashboardTest.Endpoint

  describe "OS mon page" do
    test "displays section titles" do
      {:ok, _live, rendered} = live(build_conn(), "/dashboard/nonode@nohost/os_mon")
      assert rendered =~ "CPU"
      assert rendered =~ "Memory"
      assert rendered =~ "Disk"
    end
  end
end
