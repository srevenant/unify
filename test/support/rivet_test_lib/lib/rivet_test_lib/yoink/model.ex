defmodule RivetTestLib.Yoink do
  use TypedEctoSchema
  use Rivet.Ecto.Model

  typed_schema "rivet_test_lib_yoinks" do
    #belongs_to(:user, ..., type: :binary_id, foreign_key: :user_id)
    #field(:type, Enum)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    required: [:user_id],
    update: [:user_id]
end
