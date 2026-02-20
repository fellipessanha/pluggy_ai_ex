defmodule Pluggy.Connect do
  @moduledoc """
  Shared configuration and JavaScript for Pluggy Connect widgets.

  This module provides the common layer used by both `Pluggy.Connect.Kino`
  (Livebook) and `Pluggy.Connect.Live` (Phoenix LiveComponent) to embed
  the Pluggy Connect widget.

  ## Options

    * `:connect_token` (required) — the connect token from `Pluggy.Client.connect_token/2`
    * `:include_sandbox` — whether to show sandbox connectors (default `false`)
  """

  @cdn_url "https://cdn.pluggy.ai/pluggy-connect/v2.8.2/pluggy-connect.js"

  @doc """
  Returns the Pluggy Connect SDK CDN URL.
  """
  @spec cdn_url() :: String.t()
  def cdn_url, do: @cdn_url

  @doc """
  Validates and normalizes widget keyword options into a map.

  ## Examples

      iex> Pluggy.Connect.normalize_opts(connect_token: "tok_abc")
      %{connect_token: "tok_abc", include_sandbox: false}

      iex> Pluggy.Connect.normalize_opts(connect_token: "tok_abc", include_sandbox: true)
      %{connect_token: "tok_abc", include_sandbox: true}

  """
  @spec normalize_opts(keyword()) :: map()
  def normalize_opts(opts) when is_list(opts) do
    token =
      Keyword.get(opts, :connect_token) ||
        raise ArgumentError, ":connect_token is required"

    unless is_binary(token) do
      raise ArgumentError, ":connect_token must be a string, got: #{inspect(token)}"
    end

    %{
      connect_token: token,
      include_sandbox: Keyword.get(opts, :include_sandbox, false)
    }
  end

  @doc """
  Returns the shared JavaScript string for loading the Pluggy Connect SDK
  and initializing the widget.

  The returned JS defines two functions:

    * `loadPluggySDK(cdnUrl)` — injects the script tag (deduplicates via `window.PluggyConnect`)
    * `initPluggyWidget(container, token, opts, onSuccess, onError)` — creates and initializes the widget
  """
  @spec widget_js() :: String.t()
  def widget_js do
    """
    function loadPluggySDK(cdnUrl) {
      return new Promise(function(resolve, reject) {
        if (window.PluggyConnect) {
          resolve();
          return;
        }
        var script = document.createElement("script");
        script.src = cdnUrl;
        script.onload = function() { resolve(); };
        script.onerror = function() { reject(new Error("Failed to load Pluggy SDK from " + cdnUrl)); };
        document.head.appendChild(script);
      });
    }

    function initPluggyWidget(container, token, opts, onSuccess, onError) {
      var config = {
        connectToken: token,
        includeSandbox: opts.includeSandbox || false,
        onSuccess: function(itemData) {
          if (onSuccess) onSuccess(itemData);
        },
        onError: function(error) {
          if (onError) onError(error);
        },
        onClose: function() {}
      };
      var pluggyConnect = new PluggyConnect(config);
      pluggyConnect.init();
      return pluggyConnect;
    }
    """
  end
end
