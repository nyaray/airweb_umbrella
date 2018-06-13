defmodule Airweb.Web.Router do
  use Airweb.Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    # plug :protect_from_forgery
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Airweb.Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", HomeController, :index)
    post("/", HomeController, :process)
  end

  # Other scopes may use custom stacks.
  # scope "/api", Airweb.Web do
  #   pipe_through :api
  # end
end
