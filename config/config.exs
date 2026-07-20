import Config

# OpenAPI spec used for compile-time codegen (see Pluggy.OAS.Spec).
# Override in your own config to point at a custom spec.
config :pluggy_ai, :oas_spec_path, Path.expand("../priv/oas3.json", __DIR__)

# Default API version for versioned endpoints (see Pluggy.api_version/3).
# Keyed by {module, function}; the newest version is used when unset. Can also
# be set per endpoint via the PLUGGY_<MODULE>_VERSION env var, e.g.
# PLUGGY_TRANSACTION_VERSION=v1.
# config :pluggy_ai, :api_versions, %{{Pluggy.Transaction, :list} => :v1}
