defmodule RequiredFuelForInterplanetaryTravelWeb.FuelCalculatorLiveTest do
  use RequiredFuelForInterplanetaryTravelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "renders the calculator with an empty flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#mass-form")
      assert has_element?(view, "#step-form")
      assert has_element?(view, "#empty-flight-path")
      assert has_element?(view, "#fuel-placeholder")
    end
  end

  describe "mass validation" do
    test "shows an error for non-numeric mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#mass-form", spacecraft: %{mass: "not a number"})
        |> render_change()

      assert html =~ "must be a valid number"
    end

    test "shows an error for non-positive mass", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#mass-form", spacecraft: %{mass: "-5"})
        |> render_change()

      assert html =~ "must be greater than 0"
    end
  end

  describe "flight path" do
    test "adds steps to the flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      view
      |> form("#step-form", step: %{action: "land", celestial_object: "moon"})
      |> render_submit()

      assert has_element?(view, "#flight-step-0", "Earth")
      assert has_element?(view, "#flight-step-1", "Moon")
      refute has_element?(view, "#empty-flight-path")
    end

    test "removes a step from the flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      view
      |> form("#step-form", step: %{action: "land", celestial_object: "moon"})
      |> render_submit()

      view |> element("#remove-step-0") |> render_click()

      assert has_element?(view, "#flight-step-0", "Moon")
      refute has_element?(view, "#flight-step-1")
    end

    test "rejects consecutive identical actions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      html =
        view
        |> form("#step-form", step: %{action: "launch", celestial_object: "moon"})
        |> render_submit()

      assert html =~ "cannot launch twice in a row"
      refute has_element?(view, "#flight-step-1")
    end

    test "warns when removing a step leaves consecutive actions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      for step <- [
            %{action: "launch", celestial_object: "earth"},
            %{action: "land", celestial_object: "moon"},
            %{action: "launch", celestial_object: "moon"}
          ] do
        view |> form("#step-form", step: step) |> render_submit()
      end

      refute has_element?(view, "#path-error")

      view |> element("#remove-step-1") |> render_click()

      assert has_element?(view, "#path-error")
    end

    test "clears the entire flight path", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      view |> element("#clear-path-button") |> render_click()

      assert has_element?(view, "#empty-flight-path")
    end
  end

  describe "fuel calculation" do
    test "shows the fuel result when mass and flight path are valid", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#mass-form", spacecraft: %{mass: "28801"})
      |> render_change()

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      assert has_element?(view, "#fuel-result")
      refute has_element?(view, "#fuel-placeholder")
    end

    test "updates the fuel result when the flight path changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#mass-form", spacecraft: %{mass: "1000"})
      |> render_change()

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      fuel_after_one_step = view |> element("#fuel-result") |> render()

      view
      |> form("#step-form", step: %{action: "land", celestial_object: "moon"})
      |> render_submit()

      fuel_after_two_steps = view |> element("#fuel-result") |> render()

      refute fuel_after_one_step == fuel_after_two_steps
    end

    test "hides the fuel result when the mass becomes invalid", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#mass-form", spacecraft: %{mass: "1000"})
      |> render_change()

      view
      |> form("#step-form", step: %{action: "launch", celestial_object: "earth"})
      |> render_submit()

      assert has_element?(view, "#fuel-result")

      view
      |> form("#mass-form", spacecraft: %{mass: "0"})
      |> render_change()

      refute has_element?(view, "#fuel-result")
      assert has_element?(view, "#fuel-placeholder")
    end
  end
end
