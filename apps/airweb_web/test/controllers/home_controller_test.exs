defmodule Airweb.Web.HomeControllerTest do
  use Airweb.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "AirWeb - Om du tröttnat på att räkna timmar..."
  end

end
