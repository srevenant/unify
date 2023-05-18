defmodule RivetTestLib.Yoink.Migrations.Base do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:rivet_test_lib_yoinks, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      # add(:user_id, references(:users, on_delete: :delete_all, type: :uuid))
      timestamps()
    end

    # create(index(:auth_accesses, [:domain, :ref_id]))
  end
end
