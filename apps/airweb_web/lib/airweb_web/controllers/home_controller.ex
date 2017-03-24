defmodule Airweb.Web.HomeController do
  use Airweb.Web, :controller

  require Logger

  alias Airweb.AirTime, as: AirTime

  def index(conn, _params) do
    render conn, "index.html", user_input: "", result: "Fyll i och skicka in!"
  end

  def process(conn, params) do
    user_input = params["user_input"]
    result = AirTime.parse user_input
    render conn, "index.html", user_input: user_input, result: result
  end

  def csrf_token(conn) do
    Plug.Conn.get_session(conn, :csrf_token)
  end

end
