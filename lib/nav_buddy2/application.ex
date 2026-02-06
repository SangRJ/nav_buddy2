defmodule NavBuddy2.Application do
  @moduledoc false
  # NavBuddy2 is a library — no supervised processes needed.
  # This module exists only to satisfy mix structure.

  use Application

  @impl true
  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: NavBuddy2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
