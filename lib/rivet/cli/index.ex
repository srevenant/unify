defmodule Rivet.Cli do
  @moduledoc """
  Common calls across mix tasks
  """
  import Rivet.Cli.Print

  ##############################################################################
  def run_command(args, opts) do
    commands = Keyword.get(opts, :commands)
    opts_args = Keyword.take(opts, [:switches, :aliases])

    with {matched, [cmd | args], []} <- OptionParser.parse(args, opts_args),
         {:ok, module} <- match_command(cmd, commands),
         :ok <- apply(module, :run, [opts, matched, args]) do
      :ok
    else
      {_, _, errors} -> IO.inspect(errors, label: "ERRORS")
      {:error, msg} -> syntax(opts, msg)
      {:nomatch, cmd} -> syntax(opts, "Unmatched command: #{cmd}")
    end
  end

  ##############################################################################
  def parse_options(args, opts),
    do: OptionParser.parse(args, Keyword.take(opts, [:switches, :aliases]))

  ##############################################################################
  def task_cmd(module) do
    case to_string(module) do
      "Elixir.Mix.Tasks." <> rest -> String.downcase(rest) |> String.replace(".", " ")
    end
  end

  ##############################################################################
  def syntax(opts, msg) do
    stderr([list_commands(opts), list_options(opts)])
    abort(msg)
  end

  ##############################################################################
  def list_commands(opts) do
    ## TODO: or pull from last element of module as default
    prefix = Keyword.get(opts, :prefix, "    ")
    cmd0 = Keyword.get(opts, :command, "")

    [
      "Syntax:\n\n"
      | for {cmd, module} <- Keyword.get(opts, :commands), into: [] do
          shortdoc = Mix.Task.shortdoc(module)

          shortdoc =
            if not is_nil(shortdoc) and String.length(shortdoc), do: " # #{shortdoc}", else: ""

          [prefix, :bright, cmd0, " ", cmd, :reset, shortdoc, "\n"]
        end
    ]
  end

  ##############################################################################
  def list_options(opts) do
    switches = Keyword.get(opts, :switches, [])
    aliases = Keyword.get(opts, :aliases, [])
    info = Keyword.get(opts, :info, [])
    prefix = Keyword.get(opts, :prefix, "    ")

    # invert aliases
    aliases =
      Map.new(aliases)
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        Map.update(acc, v, [k], fn as -> [k | as] end)
      end)

    # switches as strings for sorting
    sorted = Enum.map(switches, fn {k, _} -> to_string(k) end) |> Enum.sort()

    # formatted
    opts = list_options([], Map.new(switches), aliases, Map.new(info), prefix, sorted)

    if opts == [],
      do: [],
      else: ["\nOptions:\n\n"] ++ opts
  end

  def list_options(out, switches, aliases, info, prefix, [option | rest]) do
    key = String.to_atom(option)
    opt = String.replace(option, "_", "-")

    (out ++
       [
         prefix,
         list_option(opt, key, switches[key], aliases[key], info[key])
       ])
    |> list_options(switches, aliases, info, prefix, rest)
  end

  def list_options(out, _, _, _, _, []), do: out

  ##############################################################################
  def list_option(opt, _optkey, :boolean, _aliases, info) do
    {a, b} = if info[:default] == true, do: {"", "no-"}, else: {"no-", ""}
    [:bright, "--#{a}#{opt}", :reset, "|", :bright, "--#{b}#{opt}", :reset, "\n"]
  end

  def list_option(opt, _optkey, [type, :keep], _aliases, _info) do
    [:bright, "--#{opt}", :reset, "=#{to_string(type) |> String.upcase()}\n"]
  end

  def list_option(opt, _optkey, type, _aliases, info) do
    [:bright, "--#{opt}", :reset, "=#{to_string(type) |> String.upcase()}\n"]
  end

  ##############################################################################
  def match_command(cmd, [{pattern, module} | rest]) do
    if match_command(cmd, pattern),
      do: {:ok, module},
      else: match_command(cmd, rest)
  end

  def match_command(cmd, pattern) when is_binary(pattern) do
    case String.split(pattern, "?") do
      [root] -> match_command(cmd, root, [])
      [root | [tail]] -> match_command(cmd, root, String.graphemes(tail))
      _ -> abort("Invalid command pattern #{pattern}")
    end
  end

  def match_command(cmd, []), do: {:nomatch, cmd}

  ##############################################################################
  defp match_command(match, match, _), do: true
  defp match_command(cmd, root, [c | rest]), do: match_command(cmd, root <> c, rest)
  defp match_command(cmd, _, []), do: false
end
