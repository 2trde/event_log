# EventLog

## Rollbax

The `rollbax` dependency is used to report plug, uncatched and manual errors to the cloud service [rollbar](https://rollbar.com). Please update your `config.exs` accordingly:

```elixir
# Disable rollbar reporting
config :rollbax,
  enabled: false

# Use environment variables to configure rollbax
# ROLLBAR_ACCESS_TOKEN string
# ROLLBAR_ENABLED "false" "true"
# ROLLBAR_ENV string
config :rollbax,
  config_callback: {EventLog.Rollbax, :config}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `event_log` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:event_log, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/event_log](https://hexdocs.pm/event_log).
