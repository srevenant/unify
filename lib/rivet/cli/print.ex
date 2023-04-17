defmodule Rivet.Cli.Print do
  @moduledoc """
  Command-Line helpers for stdout/stderr I/O
  """

  alias IO.ANSI

  def abort(reason) do
    error(reason)
    exit({:shutdown, 1})
  end

  def stdout(msg) when is_list(msg), do: IO.puts(ANSI.format(msg))
  def stderr(msg) when is_list(msg), do: IO.puts(:stderr, ANSI.format(msg))
  def info(msg) when is_binary(msg), do: stdout([:light_black, "  ", msg])
  def info(msg) when is_list(msg), do: stdout(["  " | msg])
  def error(msg) when is_binary(msg), do: stderr([:red, :bright, "! ", msg])
  def error(msg) when is_list(msg), do: stderr([:red, :bright, "! "] ++ msg)
  def warn(msg) when is_binary(msg), do: stderr([:yellow, :bright, "? ", msg])
  def warn(msg) when is_list(msg), do: stderr([:yellow, :bright, "? "] ++ msg)
  def notify(msg) when is_binary(msg), do: stdout([:green, :bright, ?✓, :reset, " ", msg])
  def notify(msg) when is_list(msg), do: stdout([:green, :bright, ?✓, :reset, " "] ++ msg)
end
