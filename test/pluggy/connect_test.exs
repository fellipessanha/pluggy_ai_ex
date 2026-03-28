defmodule Pluggy.ConnectTest do
  use ExUnit.Case, async: true

  describe "cdn_url/0" do
    test "returns the Pluggy Connect SDK CDN URL" do
      assert Pluggy.Connect.cdn_url() =~ "pluggy-connect"
      assert Pluggy.Connect.cdn_url() =~ "https://"
    end
  end

  describe "widget_js/0" do
    test "returns JavaScript string with loadPluggySDK function" do
      js = Pluggy.Connect.widget_js()
      assert js =~ "function loadPluggySDK"
      assert js =~ "function initPluggyWidget"
      assert js =~ "PluggyConnect"
    end
  end
end
