defmodule Pluggy.ConnectTest do
  use ExUnit.Case, async: true

  doctest Pluggy.Connect

  describe "normalize_opts/1" do
    test "returns map with defaults when only connect_token given" do
      assert Pluggy.Connect.normalize_opts(connect_token: "tok_abc") == %{
               connect_token: "tok_abc",
               include_sandbox: false
             }
    end

    test "accepts include_sandbox option" do
      opts = [connect_token: "tok_abc", include_sandbox: true]

      assert Pluggy.Connect.normalize_opts(opts) == %{
               connect_token: "tok_abc",
               include_sandbox: true
             }
    end

    test "raises when connect_token is missing" do
      assert_raise ArgumentError, ":connect_token is required", fn ->
        Pluggy.Connect.normalize_opts([])
      end
    end

    test "raises when connect_token is not a string" do
      assert_raise ArgumentError, ~r/:connect_token must be a string/, fn ->
        Pluggy.Connect.normalize_opts(connect_token: 123)
      end
    end
  end

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
