defmodule Airweb.Web.PageController do
  use Airweb.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", params: ""
  end

  def process(conn, params) do
    user_input = params["user_input"]
    result = String.upcase user_input
    render conn, "index.html", user_input: user_input, result: result
  end

  def csrf_token(conn) do
    Plug.Conn.get_session(conn, :csrf_token)
  end

end
