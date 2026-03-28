if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Pluggy.Connect.Live do
    @moduledoc """
    Function component for the Pluggy Connect widget in Phoenix LiveView.

    Renders the Pluggy Connect widget inside a LiveView. When the user
    completes the connection flow, a `"pluggy:connected"` event is pushed
    to the parent LiveView.

    ## Usage

    In your LiveView template:

        <Pluggy.Connect.Live.connect_widget
          id="pluggy-connect"
          connect_token={@connect_token}
        />

    In your LiveView:

        def handle_event("pluggy:connected", item_data, socket) do
          # item_data contains the connected item
          {:noreply, assign(socket, :item, item_data)}
        end

    ### Resolving a token from a client

    Use `Pluggy.Client.connect_token/1` in your LiveView to generate the
    token before passing it to the component:

        def mount(_params, _session, socket) do
          {:ok, client} = Pluggy.Client.new("id", "secret")
          {:ok, token} = Pluggy.Client.connect_token(client)
          {:ok, assign(socket, :connect_token, token)}
        end

    On the client side, add the hook to your LiveSocket:

        import { createPluggyConnectHook } from "pluggy_ai/priv/static/pluggy_connect_hook.js"

        let liveSocket = new LiveSocket("/live", Socket, {
          hooks: { PluggyConnect: createPluggyConnectHook() }
        })

    Requires the `:phoenix_live_view` dependency.
    """
    use Phoenix.Component

    @doc """
    Renders the Pluggy Connect widget container.

    ## Attributes

      * `:id` (required) — unique DOM element ID
      * `:connect_token` (required) — the connect token from `Pluggy.Client.connect_token/2`
      * `:include_sandbox` — whether to show sandbox connectors (default `false`)
    """
    attr(:id, :string, required: true)
    attr(:connect_token, :string, required: true)
    attr(:include_sandbox, :boolean, default: false)

    def connect_widget(assigns) do
      assigns = assign(assigns, :cdn_url, Pluggy.Connect.cdn_url())

      ~H"""
      <div
        id={@id}
        phx-hook="PluggyConnect"
        data-connect-token={@connect_token}
        data-include-sandbox={to_string(@include_sandbox)}
        data-cdn-url={@cdn_url}
        style="min-height: 600px;"
      >
      </div>
      """
    end
  end
else
  defmodule Pluggy.Connect.Live do
    @moduledoc false

    def connect_widget(_assigns) do
      raise "#{__MODULE__} requires the :phoenix_live_view dependency"
    end
  end
end
