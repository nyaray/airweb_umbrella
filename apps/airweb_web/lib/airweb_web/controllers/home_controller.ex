defmodule Airweb.Web.HomeController do
  use Airweb.Web, :controller

  require Logger

  alias Airweb.AirTime, as: AirTime

  def index(conn, _params) do
    render conn, "index.html", user_input: "", result: ""
  end

  def process(conn, params) do
    user_input = params["user_input"]

    case AirTime.parse(user_input) do
      {:ok, parse_result} ->
        result = AirTime.build_output(parse_result)
        render conn, "index.html", user_input: user_input, result: result
      {:error, errors} ->
        render conn, "index.html",
          user_input: user_input,
          errors: serialize_errors(errors)
    end
  end

  def csrf_token(conn) do
    Plug.Conn.get_session(conn, :csrf_token)
  end

  defp serialize_errors(errors) do
    errors
    |> Enum.map(&inspect/1)
  end

end
