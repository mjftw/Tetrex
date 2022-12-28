defmodule TetrexWeb.PageControllerTest do
  use TetrexWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Ready Player 1"
  end
end
