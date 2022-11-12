defmodule Mix.Tasks.Rivet.New do
  use Mix.Task
  # import Mix.Ecto
  import Mix.Generator
  import Transmogrify
  require Logger
  import Rivet.Mix.Common

  @moduledoc """
  Generate a new Rivet Model structure
  """

  @defaults [
    model: true,
    db: true,
    schema: true,
    test: true,
    loader: false,
    seeds: false,
    graphql: false,
    resolver: false,
    rest: false,
    cache: false
  ]

  @switches [
    lib_dir: [:string, :keep],
    test_dir: [:string, :keep],
    migration_dir: [:string, :keep],
    migration_prefix: [:integer, :keep],
    "app-base": [:string, :keep],
    order: [:integer, :keep],
    model: :boolean,
    db: :boolean,
    ab_cd: :boolean,
    schema: :boolean,
    loader: :boolean,
    seeds: :boolean,
    graphql: :boolean,
    resolver: :boolean,
    rest: :boolean,
    cache: :boolean,
    test: :boolean
  ]

  @aliases [
    m: :model,
    d: :db,
    s: :schema,
    l: :loader,
    s: :seeds,
    g: :graphql,
    c: :cache,
    t: :test
  ]

  def run(args) do
    case OptionParser.parse(args, strict: @switches, aliases: @aliases) do
      {opts, [path_name], []} ->
        configure_model(Keyword.merge(@defaults, opts), path_name)

      {_, _, errs} ->
        syntax()
        # TODO: better handle this
        IO.inspect(errs, label: "bad arguments")
    end
  end

  defp configure_model(opts, path_name) do
    %{
      uconf: uconf,
      app: app,
      moddir: moddir,
      testdir: testdir,
      migdir: migdir,
      base: base
    } = option_configs(opts)

    {mod, dir} = Path.split(path_name) |> List.pop_at(-1)

    moddir = Path.split(moddir)
    testdir = Path.split(testdir)
    migdir = Path.split(migdir)

    table = pathname(mod)
    moddir = Path.join(moddir ++ ["#{app}"] ++ dir ++ [table])
    testdir = Path.join(testdir ++ ["#{app}"] ++ dir ++ [table])
    migdir = Path.join(migdir)
    model = modulename(mod)
    # prefix our config opts with `c_` so they don't collide with command-line opts
    opts =
      Keyword.merge(opts,
        c_app: app,
        c_base: base,
        c_model: model,
        c_table: table,
        c_mod: "#{base}.#{model}"
      )

    dopts = Map.new(opts)

    create_directory(moddir)
    create_directory(testdir)

    if dopts.model do
      create_file("#{moddir}/model.ex", model_template(opts))
    end

    if dopts.schema do
      create_file("#{moddir}/schema.ex", schema_template(opts))
      create_directory(migdir)

      Rivet.Mix.Migration.link_next_schema(
        "#{moddir}/schema.ex",
        table,
        migdir,
        getconf(:migration_prefix, opts, uconf, 00),
        getconf(:order, opts, uconf, nil)
      )
    end

    if dopts.db do
      create_file("#{moddir}/db.ex", db_template(opts))
    end

    if dopts.loader do
      create_file("#{moddir}/loader.ex", empty_template(opts ++ [c_sub: "Loader"]))
    end

    if dopts.seeds do
      create_file("#{moddir}/seeds.ex", empty_template(opts ++ [c_sub: "Seeds"]))
    end

    if dopts.graphql do
      create_file("#{moddir}/graphql.ex", empty_template(opts ++ [c_sub: "Graphql"]))
    end

    if dopts.resolver do
      create_file("#{moddir}/resolver.ex", empty_template(opts ++ [c_sub: "Resolver"]))
    end

    if dopts.rest do
      create_file("#{moddir}/rest.ex", empty_template(opts ++ [c_sub: "Rest"]))
    end

    if dopts.cache do
      create_file("#{moddir}/cache.ex", empty_template(opts ++ [c_sub: "Cache"]))
    end

    if dopts.test do
      create_file("#{testdir}/#{table}_test.ex", test_template(opts))
    end
  end

  ################################################################################
  defp syntax() do
    cmd = Rivet.Mix.Common.task_cmd(__MODULE__)

    IO.puts(:stderr, """
    Syntax: mix #{cmd} {path/to/model_folder (singular)}

    TODO: list options here
    """)
  end

  ################################################################################
  embed_template(:model, """
  defmodule <%= @c_mod %> do
    use TypedEctoSchema
    use Rivet.Ecto.Model

    typed_schema "<%= @c_table %>s" do
      #belongs_to(:user, ..., type: :binary_id, foreign_key: :user_id)
      #field(:type, Enum)
      timestamps()
    end

    use Rivet.Ecto.Collection,
      required: [:user],
      update: [:user]
  end
  """)

  embed_template(:schema, """
  defmodule <%= @c_mod %>.Schema do
    @moduledoc false
    use Ecto.Migration

    def change do
      create table(:<%= @c_table %>) do
      #  add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
        timestamps()
      end

      #create(index(:auth_accesses, [:domain, :ref_id]))
    end
  end
  """)

  embed_template(:db, """
  defmodule <%= @c_mod %>.Db do
    import Ecto.Query
  end
  """)

  embed_template(:empty, """
  defmodule <%= @c_mod %>.<%= @c_sub %> do
    @moduledoc false
  end
  """)

  embed_template(:test, """
  defmodule <%= @c_base %>.Test.<%= @c_model %>Test do
    use <%= @c_base %>.Case, async: true

    doctest <%= @c_mod %>, import: true
    <%= if @db do %>doctest <%= @c_mod %>.Db, import: true
    <% end %><%= if @loader do %>doctest <%= @c_mod %>.Loader, import: true
    <% end %><%= if @seeds do %>doctest <%= @c_mod %>.Seeds, import: true
    <% end %><%= if @graphql do %>doctest <%= @c_mod %>.Graphql, import: true
    <% end %><%= if @resolver do %>doctest <%= @c_mod %>.Resolver, import: true
    <% end %><%= if @rest do %>doctest <%= @c_mod %>.Rest, import: true
    <% end %><%= if @cache do %>doctest <%= @c_mod %>.Cache, import: true
    <% end %>
    describe "factory" do
      test "factory creates a valid instance" do
        assert %{} = dup_template = insert(:dup_template)
        assert dup_template.id != nil
      end
    end

    describe "build/1" do
      test "build when valid" do
        params = params_with_assocs(:dup_template)
        changeset = Db.DupTemplate.build(params)
        assert changeset.valid?
      end
    end

    describe "get/1" do
      test "loads saved transactions as expected" do
        c = insert(:dup_template)
        assert %Db.DupTemplate{} = found = Db.DupTemplates.one!(id: c.id)
        assert found.id == c.id
      end
    end

    describe "create/1" do
      test "inserts a valid record" do
        attrs = params_with_assocs(:dup_template)
        assert {:ok, dup_template} = Db.DupTemplates.create(attrs)
        assert dup_template.id != nil
      end
    end

    describe "delete/1" do
      test "deletes record" do
        dup_template = insert(:dup_template)
        assert {:ok, deleted} = Db.DupTemplates.delete(dup_template)
        assert deleted.id == dup_template.id
      end
    end
  end
  """)
end
