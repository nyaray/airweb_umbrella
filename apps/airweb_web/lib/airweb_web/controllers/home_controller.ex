defmodule Airweb.Web.HomeController do
  use Airweb.Web, :controller

  require Logger

  alias Airweb.AirTime, as: AirTime

  @template "index.html"

  def index(conn, _params), do: render(conn, @template)

  def process(conn, params) do
    user_input = params["user_input"]
    render_opts = process_input(user_input)
    render(conn, @template, Keyword.merge(render_opts, user_input: user_input))
  end

  def csrf_token(conn), do: Plug.Conn.get_session(conn, :csrf_token)

  defp process_input(user_input) do
    split_input = String.splitter(user_input, "\n")

    case AirTime.parse(split_input) do
      {:ok, {num_lines, parse_result}} ->
        [num_lines: num_lines, result: AirTime.build_output(parse_result)]
      {:error, {num_lines, errors}} ->
        [num_lines: num_lines, errors: serialize_errors(errors)]
    end
  end

  defp serialize_errors(errors), do: Enum.map(errors, &inspect/1)

end
