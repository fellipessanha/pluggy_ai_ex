if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Pluggy.Connect.Live do
    @moduledoc """
    Phoenix LiveComponent for the Pluggy Connect widget.

    Renders the Pluggy Connect widget inside a LiveView. When the user
    completes the connection flow, a `"pluggy:connected"` event is pushed
    to the parent LiveView.

    ## Usage

    In your LiveView template:

        <.live_component
          module={Pluggy.Connect.Live}
          id="pluggy-connect"
          connect_token={@connect_token}
        />

    In your LiveView:

        def handle_info({"pluggy:connected", item_data}, socket) do
          # item_data contains the connected item
          {:noreply, assign(socket, :item, item_data)}
        end

    On the client side, add the hook to your LiveSocket:

        import { createPluggyConnectHook } from "pluggy_ai/priv/static/pluggy_connect_hook.js"

        let liveSocket = new LiveSocket("/live", Socket, {
          hooks: { PluggyConnect: createPluggyConnectHook() }
        })

    Requires the `:phoenix_live_view` dependency.
    """
    use Phoenix.LiveComponent

    @impl true
    def update(assigns, socket) do
      opts = [
        connect_token: assigns[:connect_token],
        include_sandbox: assigns[:include_sandbox] || false
      ]

      normalized = Pluggy.Connect.normalize_opts(opts)

      {:ok,
       socket
       |> assign(:id, assigns.id)
       |> assign(:connect_token, normalized.connect_token)
       |> assign(:include_sandbox, normalized.include_sandbox)
       |> assign(:cdn_url, Pluggy.Connect.cdn_url())}
    end

    @impl true
    def render(assigns) do
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
    def render(_assigns) do
      raise "#{__MODULE__} requires the :phoenix_live_view dependency"
    end
  end
end
