defmodule Rivet.Test.Repo do
  @moduledoc false
  use Ecto.Repo, otp_app: :rivet, adapter: Ecto.Adapters.Postgres
end
