defmodule RequiredFuelForInterplanetaryTravel.FuelCalculation.Formulas do
  @moduledoc """
  Fuel formulas for launching from and landing on celestial objects.

  The base fuel for a step is calculated as:

      floor(mass * gravity * constant_x - constant_y)

  Since fuel adds weight to the ship, `additional_fuel_launch/3` and
  `additional_fuel_land/3` keep applying the formula to the fuel itself until
  the additional fuel is zero or negative.

  Constants and the gravity reference can be overridden via `new/1`.
  """

  @gravity_reference %{
    "earth" => Decimal.new("9.807"),
    "moon" => Decimal.new("1.62"),
    "mars" => Decimal.new("3.711")
  }

  defstruct gravity_reference: @gravity_reference,
            launch_constant_x: Decimal.new("0.042"),
            launch_constant_y: 33,
            landing_constant_x: Decimal.new("0.033"),
            landing_constant_y: 42

  @type t :: %__MODULE__{
          gravity_reference: %{String.t() => Decimal.t()},
          launch_constant_x: Decimal.t(),
          launch_constant_y: Decimal.decimal(),
          landing_constant_x: Decimal.t(),
          landing_constant_y: Decimal.decimal()
        }

  @doc """
  Builds a formulas struct. Custom gravity entries are merged into the
  default gravity reference; constants replace the defaults.
  """
  @spec new(keyword()) :: t()
  def new(overrides \\ []) do
    {gravity_overrides, constants} = Keyword.pop(overrides, :gravity_reference, %{})

    struct!(__MODULE__, constants)
    |> Map.update!(:gravity_reference, &Map.merge(&1, gravity_overrides))
  end

  @doc "Calculates the base fuel required to launch the given mass."
  @spec launch(t(), Decimal.decimal(), String.t()) :: {:ok, Decimal.t()} | {:error, String.t()}
  def launch(%__MODULE__{} = formulas, mass, celestial_obj) do
    base_fuel(
      formulas,
      mass,
      celestial_obj,
      formulas.launch_constant_x,
      formulas.launch_constant_y
    )
  end

  @doc "Calculates the base fuel required to land the given mass."
  @spec land(t(), Decimal.decimal(), String.t()) :: {:ok, Decimal.t()} | {:error, String.t()}
  def land(%__MODULE__{} = formulas, mass, celestial_obj) do
    base_fuel(
      formulas,
      mass,
      celestial_obj,
      formulas.landing_constant_x,
      formulas.landing_constant_y
    )
  end

  @doc """
  Calculates the total launch fuel, including the fuel required to carry the
  fuel itself, until the additional fuel is zero or negative.
  """
  @spec additional_fuel_launch(t(), Decimal.decimal(), String.t()) ::
          {:ok, Decimal.t()} | {:error, String.t()}
  def additional_fuel_launch(%__MODULE__{} = formulas, mass, celestial_obj) do
    accumulate_fuel(formulas, mass, celestial_obj, &launch/3, Decimal.new(0))
  end

  @doc """
  Calculates the total landing fuel, including the fuel required to carry the
  fuel itself, until the additional fuel is zero or negative.
  """
  @spec additional_fuel_land(t(), Decimal.decimal(), String.t()) ::
          {:ok, Decimal.t()} | {:error, String.t()}
  def additional_fuel_land(%__MODULE__{} = formulas, mass, celestial_obj) do
    accumulate_fuel(formulas, mass, celestial_obj, &land/3, Decimal.new(0))
  end

  defp base_fuel(formulas, mass, celestial_obj, constant_x, constant_y) do
    case Map.fetch(formulas.gravity_reference, celestial_obj) do
      {:ok, gravity} ->
        fuel =
          mass
          |> Decimal.mult(gravity)
          |> Decimal.mult(constant_x)
          |> Decimal.sub(constant_y)
          |> Decimal.round(0, :floor)

        {:ok, fuel}

      :error ->
        {:error, "a wrong celestial object"}
    end
  end

  defp accumulate_fuel(formulas, mass, celestial_obj, fuel_fun, acc) do
    if Decimal.gt?(mass, 0) do
      with {:ok, next_mass} <- fuel_fun.(formulas, mass, celestial_obj) do
        accumulate_fuel(formulas, next_mass, celestial_obj, fuel_fun, Decimal.add(acc, mass))
      end
    else
      {:ok, acc}
    end
  end
end
