defmodule Rivet.Ecto.Collection.Model do
  import Ecto.Changeset

  @spec validate_foreign_keys(Ecto.Changeset.t(), [{term(), keyword()} | term()]) ::
          Ecto.Changeset.t()
  def validate_foreign_keys(chgset, [{key, opts} | rest]),
    do: foreign_key_constraint(chgset, key, opts) |> validate_foreign_keys(rest)

  def validate_foreign_keys(chgset, [key | rest]),
    do: foreign_key_constraint(chgset, key) |> validate_foreign_keys(rest)

  def validate_foreign_keys(chgset, []), do: chgset

  @spec validate_unique_constraints(Ecto.Changeset.t(), [{term(), keyword()} | term()]) ::
          Ecto.Changeset.t()
  def validate_unique_constraints(chgset, [{key, opts} | rest]),
    do: unique_constraint(chgset, key, opts) |> validate_unique_constraints(rest)

  def validate_unique_constraints(chgset, [key | rest]),
    do: unique_constraint(chgset, key) |> validate_unique_constraints(rest)

  def validate_unique_constraints(chgset, []), do: chgset

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import Rivet.Ecto.Collection.Model,
        only: [validate_foreign_keys: 2, validate_unique_constraints: 2]

      @required_fields Keyword.get(opts, :required, []) |> Enum.uniq()
      @update_allowed_fields Keyword.get(opts, :update, []) |> Enum.uniq()
      @create_allowed_fields (Keyword.get(opts, :create, [:id]) ++
                                @required_fields ++ @update_allowed_fields)
                             |> Enum.uniq()
      @foreign_keys Keyword.get(opts, :foreign_keys, []) |> Enum.uniq()
      @unique_constraints Keyword.get(opts, :unique_constraints, []) |> Enum.uniq()

      def build(params \\ %{}) do
        %__MODULE__{}
        |> cast(params, @create_allowed_fields)
        |> validate
      end

      defoverridable build: 1

      def changeset(item, attrs) do
        item
        |> cast(attrs, @update_allowed_fields)
        |> validate
      end

      defoverridable changeset: 2

      # default is to do nothing
      @doc """
      change_prep alters the params only, and may only return {:ok, params}
      """
      def change_prep(item, params), do: {:ok, params}
      defoverridable change_prep: 2

      @doc """
      change_post for side effects; should return the item

      Note: BE VERY CAREFUL on large impact effects. This can quickly become
      a performance bottleneck.
      """
      def change_post(item, params), do: item
      defoverridable change_post: 2

      @doc """
      create_prep alters the params only, and may only return {:ok, params}
      """
      def create_prep(item, params), do: {:ok, params}
      defoverridable create_prep: 2

      @doc """
      create_post for side effects; should return the item

      Note: BE VERY CAREFUL on large impact effects. This can quickly become
      a performance bottleneck.
      """
      def create_post(item, params), do: item
      defoverridable create_post: 2

      cond do
        @foreign_keys == [] and @unique_constraints == [] ->
          def validate(%Ecto.Changeset{} = chgset),
            do: validate_required(chgset, @required_fields)

        @foreign_keys == [] ->
          def validate(%Ecto.Changeset{} = chgset) do
            chgset
            |> validate_required(@required_fields)
            |> validate_unique_constraints(@unique_constraints)
          end

        @unique_constraints == [] ->
          def validate(%Ecto.Changeset{} = chgset) do
            chgset
            |> validate_required(@required_fields)
            |> validate_foreign_keys(@foreign_keys)
          end

        true ->
          def validate(%Ecto.Changeset{} = chgset) do
            chgset
            |> validate_required(@required_fields)
            |> validate_foreign_keys(@foreign_keys)
            |> validate_unique_constraints(@unique_constraints)
          end
      end

      defoverridable validate: 1
    end
  end
end
