defmodule RequiredFuelForInterplanetaryTravel.FuelCalculationTest do
  use ExUnit.Case, async: true

  alias RequiredFuelForInterplanetaryTravel.FuelCalculation
  alias RequiredFuelForInterplanetaryTravel.FuelCalculation.Formulas

  describe "calculate/3" do
    test "landing the Apollo 11 CSM (28801 kg) on Earth requires 13447 kg of fuel" do
      assert {:ok, fuel} =
               FuelCalculation.calculate(Decimal.new("28801"), [{:land, "earth"}])

      assert Decimal.eq?(fuel, 13447)
    end

    test "launch earth, land moon, launch moon, land earth requires 51898 kg of fuel" do
      route = [{:launch, "earth"}, {:land, "moon"}, {:launch, "moon"}, {:land, "earth"}]

      assert {:ok, fuel} = FuelCalculation.calculate(Decimal.new("28801"), route)
      assert Decimal.eq?(fuel, 51898)
    end

    test "Mars mission: launch earth, land mars, launch mars, land earth " <>
           "with 14606 kg of equipment requires 33388 kg of fuel" do
      route = [{:launch, "earth"}, {:land, "mars"}, {:launch, "mars"}, {:land, "earth"}]

      assert {:ok, fuel} = FuelCalculation.calculate(Decimal.new("14606"), route)
      assert Decimal.eq?(fuel, 33388)
    end

    test "passenger ship mission: launch earth, land moon, launch moon, land mars, " <>
           "launch mars, land earth with 75432 kg of equipment requires 212161 kg of fuel" do
      route = [
        {:launch, "earth"},
        {:land, "moon"},
        {:launch, "moon"},
        {:land, "mars"},
        {:launch, "mars"},
        {:land, "earth"}
      ]

      assert {:ok, fuel} = FuelCalculation.calculate(Decimal.new("75432"), route)
      assert Decimal.eq?(fuel, 212_161)
    end

    test "accepts a custom formulas struct" do
      route = [{:launch, "earth"}, {:land, "moon"}, {:launch, "moon"}, {:land, "earth"}]

      assert {:ok, fuel} =
               FuelCalculation.calculate(Decimal.new("28801"), route, Formulas.new())

      assert Decimal.eq?(fuel, 51898)
    end

    test "must contain at least one step" do
      assert {:error, "must contain at least one step"} =
               FuelCalculation.calculate(Decimal.new("100"), [])
    end

    test "returns an error for a wrong action" do
      assert {:error, "a wrong action"} =
               FuelCalculation.calculate(Decimal.new("28801"), [{:hover, "earth"}])
    end

    test "returns an error for a wrong celestial object" do
      assert {:error, "a wrong celestial object"} =
               FuelCalculation.calculate(Decimal.new("28801"), [{:land, "pluto"}])
    end
  end

  test "returns an error for consecutive identical actions" do
    route = [{:land, "earth"}, {:land, "moon"}]

    assert {:error, "must not contain consecutive launch or land actions"} =
             FuelCalculation.calculate(Decimal.new("28801"), route)
  end
end
