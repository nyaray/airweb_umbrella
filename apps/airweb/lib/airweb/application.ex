defmodule Airweb.Application do
  @moduledoc """
  The Airweb Application Service.

  The airweb system business domain lives in this application.

  Exposes API to clients such as the `Airweb.Web` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link([
    ], strategy: :one_for_one, name: Airweb.Supervisor)
  end
end
