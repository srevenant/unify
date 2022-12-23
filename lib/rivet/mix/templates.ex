defmodule Rivet.Mix.Templates do
  # use Mix.Task
  import Mix.Generator

  ################################################################################
  def model(opts), do: model_template(opts)

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

  ################################################################################
  def empty_list(opts), do: empty_list_template(opts)

  embed_template(:empty_list, """
  [
  ]
  """)

  ################################################################################
  def migrations(opts), do: migrations_template(opts)

  embed_template(:migrations, """
  [
    [base: true, version: 0, module: Base]
  ]
  """)

  ################################################################################
  def migration(opts), do: migration_template(opts)

  embed_template(:migration, """
  defmodule <%= @c_base %>.Migrations.<%= @c_name %><%= @c_index %> do
    @moduledoc false
    use Ecto.Migration

    def change do

    end
  end
  """)

  ################################################################################
  def base_migration(opts), do: base_migration_template(opts)

  embed_template(:base_migration, """
  defmodule <%= @c_mod %>.Migrations.Base do
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

  ################################################################################
  def db(opts), do: db_template(opts)

  embed_template(:db, """
  defmodule <%= @c_mod %>.Db do
    import Ecto.Query
  end
  """)

  ################################################################################
  def empty(opts), do: empty_template(opts)

  embed_template(:empty, """
  defmodule <%= @c_mod %>.<%= @c_sub %> do
    @moduledoc false
  end
  """)

  ################################################################################
  def test(opts), do: test_template(opts)

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
