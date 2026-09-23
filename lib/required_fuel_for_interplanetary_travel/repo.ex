defmodule RequiredFuelForInterplanetaryTravel.Repo do
  use Ecto.Repo,
    otp_app: :required_fuel_for_interplanetary_travel,
    adapter: Ecto.Adapters.Postgres
end
