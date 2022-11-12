import Config

config :logger, level: :info

config :rivet,
  ecto_repos: [Rivet.Test.Repo],
  repo: Rivet.Test.Repo

import_config "#{config_env()}.exs"
