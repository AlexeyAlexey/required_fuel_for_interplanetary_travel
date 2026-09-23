defmodule RequiredFuelForInterplanetaryTravel.FuelCalculationHelpers do
  @moduledoc """
  Helpers for building and validating fuel calculation inputs, such as the
  spacecraft mass and the flight path, before they are handed over to
  `RequiredFuelForInterplanetaryTravel.FuelCalculation`.
  """

  alias RequiredFuelForInterplanetaryTravel.FuelCalculation

  @actions [:launch, :land]

  # Only celestial objects present in `Formulas` gravity reference are
  # supported, otherwise the fuel calculation returns an error.
  @celestial_objects [
    {"Earth", "earth"},
    {"Moon", "moon"},
    {"Mars", "mars"}
  ]

  @doc "Returns the supported flight path actions."
  @spec actions() :: [FuelCalculation.action()]
  def actions, do: @actions

  @doc "Returns the supported celestial objects as `{label, value}` options."
  @spec celestial_objects() :: [{String.t(), String.t()}]
  def celestial_objects, do: @celestial_objects

  @doc "Checks whether the given action is supported."
  @spec valid_action?(term()) :: boolean()
  def valid_action?(action), do: action in @actions

  @doc "Checks whether the given celestial object is supported."
  @spec valid_celestial_object?(term()) :: boolean()
  def valid_celestial_object?(celestial_obj) do
    Enum.any?(@celestial_objects, fn {_label, value} -> value == celestial_obj end)
  end

  @doc "Returns the display label for a celestial object value."
  @spec celestial_object_label(String.t()) :: String.t()
  def celestial_object_label(celestial_obj) do
    Enum.find_value(@celestial_objects, celestial_obj, fn {label, value} ->
      value == celestial_obj && label
    end)
  end

  @doc """
  Parses and validates a spacecraft mass given as a string.

  The mass must be a positive decimal number.
  """
  @spec parse_mass(String.t()) :: {:ok, Decimal.t()} | {:error, String.t()}
  def parse_mass(mass) when is_binary(mass) do
    case Decimal.parse(String.trim(mass)) do
      {decimal, ""} ->
        if Decimal.gt?(decimal, 0) do
          {:ok, decimal}
        else
          {:error, "must be greater than 0"}
        end

      _ ->
        {:error, "must be a valid number"}
    end
  end

  @doc """
  Validates whether the given action can be appended to the route.

  A route must alternate between launches and landings, so an action is
  invalid when it matches the action of the last step in the route.
  """
  @spec validate_next_action(FuelCalculation.route(), FuelCalculation.action()) ::
          :ok | {:error, String.t()}
  def validate_next_action([], _action), do: :ok

  def validate_next_action(route, action) do
    case List.last(route) do
      {^action, _celestial_obj} -> {:error, "cannot #{action} twice in a row"}
      _step -> :ok
    end
  end

  @doc """
  Checks whether a route is valid: it must contain at least one step and
  must not contain consecutive `launch` or `land` actions.
  """
  @spec valid_route?(FuelCalculation.route()) :: boolean()
  def valid_route?([]), do: false

  def valid_route?(route) do
    route
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [{action1, _}, {action2, _}] -> action1 != action2 end)
  end
end
