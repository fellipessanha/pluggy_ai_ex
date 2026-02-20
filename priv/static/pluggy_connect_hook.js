/**
 * Phoenix LiveView hook for the Pluggy Connect widget.
 *
 * Usage:
 *
 *   import { createPluggyConnectHook } from "pluggy_ai/priv/static/pluggy_connect_hook.js"
 *
 *   let liveSocket = new LiveSocket("/live", Socket, {
 *     hooks: { PluggyConnect: createPluggyConnectHook() }
 *   })
 */

function loadPluggySDK(cdnUrl) {
  return new Promise(function (resolve, reject) {
    if (window.PluggyConnect) {
      resolve();
      return;
    }
    var script = document.createElement("script");
    script.src = cdnUrl;
    script.onload = function () {
      resolve();
    };
    script.onerror = function () {
      reject(new Error("Failed to load Pluggy SDK from " + cdnUrl));
    };
    document.head.appendChild(script);
  });
}

function initPluggyWidget(container, token, opts, onSuccess, onError) {
  var config = {
    connectToken: token,
    includeSandbox: opts.includeSandbox || false,
    onSuccess: function (itemData) {
      if (onSuccess) onSuccess(itemData);
    },
    onError: function (error) {
      if (onError) onError(error);
    },
    onClose: function () {},
  };
  var pluggyConnect = new PluggyConnect(config);
  pluggyConnect.init();
  return pluggyConnect;
}

export function createPluggyConnectHook() {
  return {
    mounted() {
      var el = this.el;
      var token = el.dataset.connectToken;
      var includeSandbox = el.dataset.includeSandbox === "true";
      var cdnUrl = el.dataset.cdnUrl;
      var hook = this;

      loadPluggySDK(cdnUrl)
        .then(function () {
          initPluggyWidget(
            el,
            token,
            { includeSandbox: includeSandbox },
            function (itemData) {
              hook.pushEvent("pluggy:connected", itemData);
            },
            function (error) {
              console.error("Pluggy Connect error:", error);
            }
          );
        })
        .catch(function (err) {
          console.error("Failed to load Pluggy SDK:", err);
        });
    },
  };
}
