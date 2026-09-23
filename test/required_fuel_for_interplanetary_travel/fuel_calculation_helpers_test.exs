defmodule RequiredFuelForInterplanetaryTravel.FuelCalculationHelpersTest do
  use ExUnit.Case, async: true

  alias RequiredFuelForInterplanetaryTravel.FuelCalculationHelpers

  describe "parse_mass/1" do
    test "parses a positive decimal" do
      assert {:ok, mass} = FuelCalculationHelpers.parse_mass("28801")
      assert Decimal.eq?(mass, Decimal.new("28801"))

      assert {:ok, mass} = FuelCalculationHelpers.parse_mass(" 4.2 ")
      assert Decimal.eq?(mass, Decimal.new("4.2"))
    end

    test "rejects zero and negative values" do
      assert {:error, "must be greater than 0"} = FuelCalculationHelpers.parse_mass("0")
      assert {:error, "must be greater than 0"} = FuelCalculationHelpers.parse_mass("-10")
    end

    test "rejects non-numeric input" do
      assert {:error, "must be a valid number"} = FuelCalculationHelpers.parse_mass("abc")
      assert {:error, "must be a valid number"} = FuelCalculationHelpers.parse_mass("4.2kg")
      assert {:error, "must be a valid number"} = FuelCalculationHelpers.parse_mass("")
    end
  end

  describe "validate_next_action/2" do
    test "allows any action on an empty route" do
      assert :ok = FuelCalculationHelpers.validate_next_action([], :launch)
      assert :ok = FuelCalculationHelpers.validate_next_action([], :land)
    end

    test "allows alternating actions" do
      route = [{:launch, "earth"}]

      assert :ok = FuelCalculationHelpers.validate_next_action(route, :land)
    end

    test "rejects consecutive identical actions" do
      assert {:error, "cannot launch twice in a row"} =
               FuelCalculationHelpers.validate_next_action([{:launch, "earth"}], :launch)

      assert {:error, "cannot land twice in a row"} =
               FuelCalculationHelpers.validate_next_action([{:land, "moon"}], :land)
    end
  end

  describe "valid_route?/1" do
    test "rejects an empty route" do
      refute FuelCalculationHelpers.valid_route?([])
    end

    test "accepts a route with alternating actions" do
      assert FuelCalculationHelpers.valid_route?([
               {:launch, "earth"},
               {:land, "moon"},
               {:launch, "moon"},
               {:land, "earth"}
             ])
    end

    test "rejects a route with consecutive identical actions" do
      refute FuelCalculationHelpers.valid_route?([{:launch, "earth"}, {:launch, "moon"}])

      refute FuelCalculationHelpers.valid_route?([
               {:launch, "earth"},
               {:land, "moon"},
               {:land, "mars"}
             ])
    end
  end

  describe "validation helpers" do
    test "valid_action?/1" do
      assert FuelCalculationHelpers.valid_action?(:launch)
      assert FuelCalculationHelpers.valid_action?(:land)
      refute FuelCalculationHelpers.valid_action?(:hover)
    end

    test "valid_celestial_object?/1" do
      assert FuelCalculationHelpers.valid_celestial_object?("earth")
      assert FuelCalculationHelpers.valid_celestial_object?("moon")
      refute FuelCalculationHelpers.valid_celestial_object?("pluto")
    end

    test "celestial_object_label/1" do
      assert FuelCalculationHelpers.celestial_object_label("earth") == "Earth"
    end
  end
end
