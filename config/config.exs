# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :budget_app, BudgetAppWeb.Endpoint,
  url: [host: "localhost"],
  # np, this gets overwritten by the import_config at the bottom of this file.
  secret_key_base: "VUL4YuJOFsmbMOpPj+5K8bOpBG4aGUN2vHFPFV9+OHtH9ifgiOz4VFqbtmxxomfo",
  render_errors: [view: BudgetAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BudgetApp.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configuring Bamboo w/ SendGrid

config :budget_app, BudgetApp.Mailer,
  adapter: Bamboo.SendGridAdapter,
  server: "smtp.sendgrid.net",
  port: 465,
  # {:system, "SMTP_USERNAME"}
  username: "apikey",
  # {:system, "SMTP_PASSWORD"}
  # can be `:always` or `:never`
  tls: :if_available,
  # can be `true`
  ssl: false,
  retries: 1

IO.puts("THE Mix.env")
IO.inspect(Mix.env())
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
