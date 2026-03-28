defmodule Pluggy.Connect do
  @moduledoc """
  Shared configuration and JavaScript for Pluggy Connect widgets.

  This module provides the common layer used by both `Pluggy.Connect.Kino`
  (Livebook) and `Pluggy.Connect.Live` (Phoenix function component) to embed
  the Pluggy Connect widget.

  ## Usage

  Widget entry points accept either a `%Pluggy.Client{}` or a connect token
  string as the first argument, plus an optional keyword list:

      # With a client (generates the token automatically)
      Pluggy.Connect.Kino.new(client, include_sandbox: true)

      # With an existing token
      Pluggy.Connect.Kino.new(token, include_sandbox: true)
  """

  @cdn_url "https://cdn.pluggy.ai/pluggy-connect/v2.8.2/pluggy-connect.js"

  @doc """
  Returns the Pluggy Connect SDK CDN URL.
  """
  @spec cdn_url() :: String.t()
  def cdn_url, do: @cdn_url

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
