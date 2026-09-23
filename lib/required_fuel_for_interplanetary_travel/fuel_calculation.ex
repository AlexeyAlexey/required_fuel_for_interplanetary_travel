defmodule RequiredFuelForInterplanetaryTravel.FuelCalculation do
  @moduledoc """
  Context for calculating the fuel required for an interplanetary flight path.

  A flight path (route) is a list of steps, where each step is a tuple of an
  action (`:launch` or `:land`) and a celestial object name, for example:

      [{:launch, "earth"}, {:land, "moon"}, {:launch, "moon"}, {:land, "earth"}]
  """

  import DecimalGuards, only: [is_positive_decimal: 1]
  alias RequiredFuelForInterplanetaryTravel.FuelCalculation.Formulas

  @type action :: :launch | :land
  @type route :: [{action(), String.t()}]

  @doc """
  Calculates the fuel required for the given spacecraft (ship) mass and route.

  The route is processed in reverse order: each earlier step must also carry
  the fuel needed for all later steps, so the fuel accumulated so far is added
  to the ship mass before applying the formulas for a step.

  Accepts an optional `Formulas` struct to customize constants and the
  gravity reference.

  ## Examples

      iex> route = [{:launch, "earth"}, {:land, "moon"}, {:launch, "moon"}, {:land, "earth"}]
      iex> FuelCalculation.calculate(Decimal.new("28801"), route)
      {:ok, Decimal.new("51898")}

  """
  @spec calculate(Decimal.t(), route(), Formulas.t()) ::
          {:ok, Decimal.t()} | {:error, String.t()}
  def calculate(%Decimal{} = mass, route, %Formulas{} = formulas \\ Formulas.new())
      when is_positive_decimal(mass) and is_list(route) do
    with :ok <- validate_route(route) do
      route
      |> Enum.reverse()
      |> Enum.reduce_while({:ok, Decimal.new(0)}, fn step, {:ok, current_fuel} ->
        total_mass = Decimal.add(mass, current_fuel)

        case additional_fuel(formulas, total_mass, step) do
          {:ok, additional_fuel} -> {:cont, {:ok, Decimal.add(current_fuel, additional_fuel)}}
          {:error, _reason} = error -> {:halt, error}
        end
      end)
    end
  end

  defp validate_route([]), do: {:error, "must contain at least one step"}

  defp validate_route(route) when is_list(route) do
    consecutive? =
      route
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.any?(fn [{action1, _}, {action2, _}] -> action1 == action2 end)

    if consecutive? do
      {:error, "must not contain consecutive launch or land actions"}
    else
      :ok
    end
  end

  defp additional_fuel(%formula_module{} = formulas, mass, {:launch, celestial_obj}) do
    with {:ok, launch_fuel} <- formula_module.launch(formulas, mass, celestial_obj) do
      formula_module.additional_fuel_launch(formulas, launch_fuel, celestial_obj)
    end
  end

  defp additional_fuel(%formula_module{} = formulas, mass, {:land, celestial_obj}) do
    with {:ok, land_fuel} <- formula_module.land(formulas, mass, celestial_obj) do
      formula_module.additional_fuel_land(formulas, land_fuel, celestial_obj)
    end
  end

  defp additional_fuel(_formulas, _mass, _step), do: {:error, "a wrong action"}
end
