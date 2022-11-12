defmodule Rivet.Mix.Common do
  import Transmogrify
  require Logger

  @moduledoc """
  Common calls across mix tasks
  """

  def getconf(key, opts, conf, default), do: opts[key] || conf[key] || default

  def cleandir(path) do
    (Path.split(path) |> Path.join()) <> "/"
  end

  def option_configs(opts) do
    config = Mix.Project.config()
    uconf = config[:rivet] || []
    app = config[:app] || :APP_MISSING

    %{
      conf: config,
      uconf: uconf,
      app: app,
      moddir: getconf(:lib_dir, opts, uconf, "./lib/") |> cleandir(),
      testdir: getconf(:test_dir, opts, uconf, "./test/") |> cleandir(),
      migdir: getconf(:migration_dir, opts, uconf, "./priv/repo/migrations/") |> cleandir(),
      base: uconf[:app_base] || modulename("#{app}")
    }
  end

  def nodot(path) do
    case Path.split(path) do
      ["." | rest] -> rest
      rest -> rest
    end
  end

  def task_cmd(module) do
    case to_string(module) do
      "Elixir.Mix.Tasks." <> rest -> String.downcase(rest)
    end
  end
end
