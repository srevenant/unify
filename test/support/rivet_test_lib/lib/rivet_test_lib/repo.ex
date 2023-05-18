defmodule RivetTestLib.Repo do
  use Ecto.Repo, otp_app: :rivet_test_lib, adapter: Ecto.Adapters.Postgres
end
