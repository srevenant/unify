defmodule Rivet.Ecto.Model do
  @moduledoc """
  For data models using Ecto.

  # Options:

  * `id_type: :uuid` — enable/disable UUID model id (default is :uuid vs :int)
  * `export_json: [:field, ...]` — becomes `@derive {Jason.Encoder, [fields...]}`
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      if Keyword.get(opts, :id_type, :uuid) == :uuid do
        @primary_key {:id, :binary_id, autogenerate: true}
        @foreign_key_type :binary_id
      else
        if Keyword.get(opts, :id_type, :uuid) == :none do
          @primary_key false
        end
      end

      if Keyword.get(opts, :export_json, []) != [] do
        @derive {Jason.Encoder, Keyword.get(opts, :export_json, [])}
      end

      @timestamps_opts [type: Keyword.get(opts, :timestamp, :utc_datetime)]

      import Ecto, only: [assoc: 2]
      import Ecto.Changeset
      use Rivet.Ecto.Context
    end
  end
end
