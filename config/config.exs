import Config

# OpenAPI spec used for compile-time codegen (see Pluggy.OAS.Spec).
# Override in your own config to point at a custom spec.
config :pluggy_ai, :oas_spec_path, Path.expand("../priv/oas3.json", __DIR__)
