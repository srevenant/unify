import Config

config :rivet, Rivet.Test.Repo,
  pool_size: 20,
  username: "postgres",
  password: "",
  database: "rivet_#{config_env()}",
  hostname: "localhost",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox
