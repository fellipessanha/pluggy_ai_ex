if Code.ensure_loaded?(Kino.JS.Live) do
  defmodule Pluggy.Connect.Kino do
    @moduledoc """
    Pluggy Connect widget for Livebook using `Kino.JS.Live`.

    Renders the Pluggy Connect widget inline in a Livebook cell and
    pushes the connected item data back to Elixir when the user
    completes the connection flow.

    ## Usage

    With a client (generates the connect token automatically):

        {:ok, client} = Pluggy.Client.new("client_id", "client_secret")
        widget = Pluggy.Connect.Kino.new(client, include_sandbox: true)

    Or with an existing connect token:

        {:ok, token} = Pluggy.Client.connect_token(client)
        widget = Pluggy.Connect.Kino.new(token, include_sandbox: true)

    After the user connects a bank account in the widget:

        item = Pluggy.Connect.Kino.await_item(widget)

    Requires the `:kino` dependency.
    """

    use Kino.JS
    use Kino.JS.Live

    @doc """
    Creates a new Pluggy Connect widget.

    ## Options

      * `:include_sandbox` — show sandbox connectors (default `false`)

    ## Examples

        widget = Pluggy.Connect.Kino.new(client)
        widget = Pluggy.Connect.Kino.new(client, include_sandbox: true)
        widget = Pluggy.Connect.Kino.new("connect_token_string")

    """
    def new(token_or_client, opts \\ [])

    def new(token, opts) when is_binary(token) do
      init_data = %{
        connect_token: token,
        include_sandbox: Keyword.get(opts, :include_sandbox, false)
      }

      Kino.JS.Live.new(__MODULE__, init_data)
    end

    def new(%Pluggy.Client{} = client, opts) do
      {:ok, token} = Pluggy.Client.connect_token(client)
      new(token, opts)
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
  end
else
  defmodule Pluggy.Connect.Kino do
    @moduledoc """
    Pluggy Connect widget for Livebook using `Kino.JS.Live`.

    Requires the `:kino` dependency.
    """
    def new(_token, _opts \\ []) do
      raise "#{__MODULE__} requires the :kino dependency"
    end

    def await_item(_widget) do
      raise "#{__MODULE__} requires the :kino dependency"
    end
  end
end
