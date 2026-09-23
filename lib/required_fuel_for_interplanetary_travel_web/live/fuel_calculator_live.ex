defmodule RequiredFuelForInterplanetaryTravelWeb.FuelCalculatorLive do
  @moduledoc """
  LiveView for building a flight path and calculating the required fuel
  in real time as the user adjusts the spacecraft mass and route.
  """
  use RequiredFuelForInterplanetaryTravelWeb, :live_view

  alias RequiredFuelForInterplanetaryTravel.{FuelCalculation, FuelCalculationHelpers}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Fuel Calculator")
     |> assign(:mass, nil)
     |> assign(:fuel, nil)
     |> assign(:flight_path, [])
     |> assign(:mass_form, to_form(%{"mass" => ""}, as: :spacecraft))
     |> assign(
       :step_form,
       to_form(%{"action" => "launch", "celestial_object" => "earth"}, as: :step)
     )
     |> recalculate()}
  end

  @impl true
  def handle_event("validate_mass", %{"spacecraft" => %{"mass" => mass} = params}, socket) do
    socket =
      case FuelCalculationHelpers.parse_mass(mass) do
        {:ok, decimal} ->
          socket
          |> assign(:mass, decimal)
          |> assign(:mass_form, to_form(params, as: :spacecraft, action: :validate))

        {:error, message} ->
          message = if String.trim(mass) == "", do: "can't be blank", else: message

          socket
          |> assign(:mass, nil)
          |> assign(
            :mass_form,
            to_form(params, as: :spacecraft, action: :validate, errors: [mass: {message, []}])
          )
      end

    {:noreply, recalculate(socket)}
  end

  def handle_event("validate_step", %{"step" => params}, socket) do
    {:noreply, assign(socket, :step_form, to_form(params, as: :step))}
  end

  def handle_event(
        "add_step",
        %{"step" => %{"action" => action, "celestial_object" => celestial_obj} = params},
        socket
      ) do
    with {:ok, action} <- parse_action(action),
         true <- FuelCalculationHelpers.valid_celestial_object?(celestial_obj),
         :ok <- FuelCalculationHelpers.validate_next_action(socket.assigns.flight_path, action) do
      {:noreply,
       socket
       |> update(:flight_path, &(&1 ++ [{action, celestial_obj}]))
       |> assign(:step_form, to_form(params, as: :step))
       |> recalculate()}
    else
      {:error, message} ->
        {:noreply,
         assign(
           socket,
           :step_form,
           to_form(params, as: :step, action: :validate, errors: [action: {message, []}])
         )}

      _ ->
        {:noreply,
         put_flash(socket, :error, "Please select a valid action and celestial object.")}
    end
  end

  def handle_event("remove_step", %{"index" => index}, socket) do
    {:noreply,
     socket
     |> update(:flight_path, &List.delete_at(&1, String.to_integer(index)))
     |> recalculate()}
  end

  def handle_event("clear_path", _params, socket) do
    {:noreply,
     socket
     |> assign(:flight_path, [])
     |> recalculate()}
  end

  defp parse_action("launch"), do: {:ok, :launch}
  defp parse_action("land"), do: {:ok, :land}
  defp parse_action(_other), do: :error

  defp recalculate(socket) do
    %{mass: mass, flight_path: flight_path} = socket.assigns

    with :ok <- validate_flight_path(flight_path),
         {:ok, fuel} <- calculate_fuel(mass, flight_path) do
      assign(socket, fuel: fuel, path_error: nil)
    else
      {:error, :missing_mass} -> assign(socket, fuel: nil, path_error: nil)
      {:error, message} -> assign(socket, fuel: nil, path_error: message)
    end
  end

  defp validate_flight_path([]), do: {:error, "the flight path must contain at least one step"}

  defp validate_flight_path(flight_path) do
    if FuelCalculationHelpers.valid_route?(flight_path) do
      :ok
    else
      {:error, "the flight path must not contain consecutive launch or land actions"}
    end
  end

  defp calculate_fuel(nil, _flight_path), do: {:error, :missing_mass}
  defp calculate_fuel(mass, flight_path), do: FuelCalculation.calculate(mass, flight_path)

  defp action_options, do: [{"Launch", "launch"}, {"Land", "land"}]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Interplanetary Fuel Calculator
        <:subtitle>
          Set your spacecraft mass, build a flight path, and watch the required
          fuel update in real time.
        </:subtitle>
      </.header>

      <div class="card bg-base-200 shadow-sm">
        <div class="card-body">
          <h2 class="card-title text-base">Spacecraft</h2>
          <.form for={@mass_form} id="mass-form" phx-change="validate_mass">
            <.input
              field={@mass_form[:mass]}
              type="text"
              inputmode="decimal"
              label="Mass (kg)"
              placeholder="e.g. 28801"
              phx-debounce="300"
            />
          </.form>
        </div>
      </div>

      <div class="card bg-base-200 shadow-sm">
        <div class="card-body">
          <div class="flex items-center justify-between">
            <h2 class="card-title text-base">Flight path</h2>
            <button
              :if={@flight_path != []}
              id="clear-path-button"
              type="button"
              class="btn btn-ghost btn-xs"
              phx-click="clear_path"
            >
              Clear all
            </button>
          </div>

          <.form
            for={@step_form}
            id="step-form"
            phx-change="validate_step"
            phx-submit="add_step"
            class="flex flex-col sm:flex-row sm:items-end gap-2"
          >
            <div class="flex-1">
              <.input
                field={@step_form[:action]}
                type="select"
                label="Action"
                options={action_options()}
              />
            </div>
            <div class="flex-1">
              <.input
                field={@step_form[:celestial_object]}
                type="select"
                label="Celestial object"
                options={FuelCalculationHelpers.celestial_objects()}
              />
            </div>
            <.button id="add-step-button" type="submit" variant="primary" class="btn btn-primary mb-2">
              <.icon name="hero-plus" class="size-4" /> Add step
            </.button>
          </.form>

          <p :if={@flight_path == []} id="empty-flight-path" class="text-sm opacity-60 italic">
            No steps yet. Add a launch or landing to begin your journey.
          </p>

          <ul :if={@flight_path != []} id="flight-path" class="mt-2 space-y-2">
            <li
              :for={{{action, celestial_obj}, index} <- Enum.with_index(@flight_path)}
              id={"flight-step-#{index}"}
              class="flex items-center gap-3 rounded-box bg-base-100 px-4 py-2 transition-colors hover:bg-base-300/40"
            >
              <span class="badge badge-neutral badge-sm">{index + 1}</span>
              <span class={[
                "badge badge-sm capitalize",
                if(action == :launch, do: "badge-primary", else: "badge-secondary")
              ]}>
                {action}
              </span>
              <span class="flex-1 font-medium">
                {FuelCalculationHelpers.celestial_object_label(celestial_obj)}
              </span>
              <button
                id={"remove-step-#{index}"}
                type="button"
                class="btn btn-ghost btn-xs btn-circle"
                aria-label={"Remove step #{index + 1}"}
                phx-click="remove_step"
                phx-value-index={index}
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </li>
          </ul>

          <div
            :if={@flight_path != [] && @path_error}
            id="path-error"
            class="alert alert-warning alert-soft mt-2"
            role="alert"
          >
            <.icon name="hero-exclamation-triangle" class="size-5" />
            <span>Invalid flight path: {@path_error}.</span>
          </div>
        </div>
      </div>

      <div class="stats bg-base-200 shadow-sm w-full">
        <div class="stat">
          <div class="stat-figure text-primary">
            <.icon name="hero-rocket-launch" class="size-8" />
          </div>
          <div class="stat-title">Total fuel required</div>
          <%= if @fuel do %>
            <div id="fuel-result" class="stat-value text-primary">{@fuel} kg</div>
            <div class="stat-desc">
              For {length(@flight_path)} step{if length(@flight_path) != 1, do: "s"} at {@mass} kg
            </div>
          <% else %>
            <div id="fuel-placeholder" class="stat-value opacity-30">—</div>
            <div class="stat-desc">
              <%= cond do %>
                <% @mass == nil -> %>
                  Enter a positive spacecraft mass
                <% @path_error -> %>
                  Fix the flight path: {@path_error}
                <% true -> %>
                  Build your flight path to see the fuel required
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
