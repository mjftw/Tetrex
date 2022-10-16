defmodule TetrexWeb.PageController do
  use TetrexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
