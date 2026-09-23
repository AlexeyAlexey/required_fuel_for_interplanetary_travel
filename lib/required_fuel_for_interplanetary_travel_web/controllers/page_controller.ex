defmodule RequiredFuelForInterplanetaryTravelWeb.PageController do
  use RequiredFuelForInterplanetaryTravelWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
