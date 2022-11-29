defmodule Rivet.StubTastic do
  use TypedEctoSchema
  use Rivet.Ecto.Model

  typed_schema "stub_tastics" do
    # belongs_to(:user, ..., type: :binary_id, foreign_key: :user_id)
    # field(:type, Enum)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    required: [:user],
    update: [:user]
end
