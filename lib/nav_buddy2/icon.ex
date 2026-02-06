defmodule NavBuddy2.Icon do
  use Phoenix.Component

  attr(:name, :atom, required: true)
  attr(:class, :string, default: "w-5 h-5")

  def icon(assigns) do
    ~H"""
    <%= apply(Heroicons, @name, [%{class: @class}]) %>
    """
  end
end
