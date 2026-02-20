defmodule Pluggy.Connect.Kino do
  @moduledoc """
  Pluggy Connect widget for Livebook using `Kino.JS.Live`.

  Renders the Pluggy Connect widget inline in a Livebook cell and
  pushes the connected item data back to Elixir when the user
  completes the connection flow.

  ## Usage

      {:ok, client} = Pluggy.Client.new("client_id", "client_secret")
      {:ok, token} = Pluggy.Client.connect_token(client)

      widget = Pluggy.Connect.Kino.new(connect_token: token)

  After the user connects a bank account in the widget:

      item = Pluggy.Connect.Kino.await_item(widget)

  Requires the `:kino` dependency.
  """

  if Code.ensure_loaded?(Kino.JS.Live) do
    use Kino.JS
    use Kino.JS.Live

    @doc """
    Creates a new Pluggy Connect widget.

    ## Options

      * `:connect_token` (required) — the connect token
      * `:include_sandbox` — show sandbox connectors (default `false`)
    """
    def new(opts) do
      normalized = Pluggy.Connect.normalize_opts(opts)
      Kino.JS.Live.new(__MODULE__, normalized)
    end

    @doc """
    Blocks until the user completes the widget connection and returns the item data.
    """
    def await_item(widget) do
      Kino.JS.Live.call(widget, "get_item")
    end

    @impl true
    def init(opts, ctx) do
      {:ok, assign(ctx, opts: opts, item: nil)}
    end

    @impl true
    def handle_connect(ctx) do
      payload = %{
        token: ctx.assigns.opts.connect_token,
        include_sandbox: ctx.assigns.opts.include_sandbox,
        cdn_url: Pluggy.Connect.cdn_url()
      }

      {:ok, payload, ctx}
    end

    @impl true
    def handle_event("connection_success", item_data, ctx) do
      ctx = assign(ctx, item: item_data)

      case Map.get(ctx.assigns, :waiting) do
        nil ->
          {:noreply, ctx}

        from ->
          Kino.JS.Live.reply(from, item_data)
          {:noreply, assign(ctx, waiting: nil)}
      end
    end

    @impl true
    def handle_call("get_item", from, ctx) do
      if ctx.assigns.item do
        {:reply, ctx.assigns.item, ctx}
      else
        {:noreply, assign(ctx, waiting: from)}
      end
    end

    asset "main.js" do
      """
      #{Pluggy.Connect.widget_js()}

      export function init(ctx, data) {
        ctx.root.innerHTML = '<div id="pluggy-connect-container" style="min-height: 600px;"></div>';

        loadPluggySDK(data.cdn_url).then(function() {
          var container = ctx.root.querySelector("#pluggy-connect-container");
          initPluggyWidget(
            container,
            data.token,
            { includeSandbox: data.include_sandbox },
            function(itemData) {
              ctx.pushEvent("connection_success", itemData);
            },
            function(error) {
              container.innerHTML = '<p style="color: red;">Connection error: ' + (error.message || error) + '</p>';
            }
          );
        }).catch(function(err) {
          ctx.root.innerHTML = '<p style="color: red;">Failed to load Pluggy SDK: ' + err.message + '</p>';
        });
      }
      """
    end
  else
    def new(_opts) do
      raise "#{__MODULE__} requires the :kino dependency"
    end

    def await_item(_widget) do
      raise "#{__MODULE__} requires the :kino dependency"
    end
  end
end
