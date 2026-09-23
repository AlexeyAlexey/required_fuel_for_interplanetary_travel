defmodule RequiredFuelForInterplanetaryTravel.FuelCalculation.FormulasTest do
  use ExUnit.Case, async: true

  alias RequiredFuelForInterplanetaryTravel.FuelCalculation.Formulas

  describe "land/3" do
    test "the Apollo 11 Command and Service Module, with a weight of 28801 kg, " <>
           "to land it on Earth, the required amount of fuel will be 9278" do
      assert {:ok, fuel} = Formulas.land(Formulas.new(), 28801, "earth")
      assert Decimal.eq?(fuel, 9278)
    end

    test "returns an error for a wrong celestial object" do
      assert {:error, "a wrong celestial object"} = Formulas.land(Formulas.new(), 9278, "wrong")
    end
  end

  describe "launch/3" do
    test "calculates the base launch fuel" do
      assert {:ok, fuel} = Formulas.launch(Formulas.new(), 28801, "earth")
      assert Decimal.eq?(fuel, 11829)
    end

    test "returns an error for a wrong celestial object" do
      assert {:error, "a wrong celestial object"} = Formulas.launch(Formulas.new(), 9278, "wrong")
    end
  end

  describe "additional_fuel_land/3" do
    test "fuel adds weight to the ship, so it requires additional fuel " <>
           "until the additional fuel is 0 or negative" do
      assert {:ok, fuel} = Formulas.additional_fuel_land(Formulas.new(), 9278, "earth")
      assert Decimal.eq?(fuel, 9278 + 2960 + 915 + 254 + 40)
    end

    test "returns zero for a non-positive mass" do
      assert {:ok, fuel} = Formulas.additional_fuel_land(Formulas.new(), 0, "earth")
      assert Decimal.eq?(fuel, 0)
    end

    test "returns an error for a wrong celestial object" do
      assert {:error, "a wrong celestial object"} =
               Formulas.additional_fuel_land(Formulas.new(), 9278, "wrong")
    end
  end

  describe "additional_fuel_launch/3" do
    test "accumulates launch fuel until the additional fuel is 0 or negative" do
      assert {:ok, fuel} = Formulas.additional_fuel_launch(Formulas.new(), 11829, "earth")
      assert Decimal.gt?(fuel, 11829)
    end
  end

  describe "new/1" do
    test "allows overriding constants" do
      formulas = Formulas.new(landing_constant_x: Decimal.new("0"), landing_constant_y: 0)

      assert {:ok, fuel} = Formulas.land(formulas, 28801, "earth")
      assert Decimal.eq?(fuel, 0)
    end
  end

  test "landing the Apollo 11 CSM on Earth: fuel adds weight to the ship, " <>
         "so it requires additional fuel until the additional fuel is 0 or negative" do
    formulas = Formulas.new()

    # 28801 * 9.807 * 0.033 - 42 = 9278
    assert {:ok, base_fuel} = Formulas.land(formulas, 28801, "earth")
    assert Decimal.eq?(base_fuel, 9278)

    # 9278 fuel requires 2960 more fuel
    # 2960 fuel requires 915 more fuel
    # 915 fuel requires 254 more fuel
    # 254 fuel requires 40 more fuel
    # 40 fuel requires no more fuel
    expected_chain = [9278, 2960, 915, 254, 40]

    fuel_chain =
      expected_chain
      |> Enum.map_reduce(base_fuel, fn _expected, fuel_mass ->
        {:ok, more_fuel} = Formulas.land(formulas, fuel_mass, "earth")
        {fuel_mass, more_fuel}
      end)
      |> elem(0)

    assert Enum.zip_with(fuel_chain, expected_chain, &Decimal.eq?/2) |> Enum.all?()
  end
end
