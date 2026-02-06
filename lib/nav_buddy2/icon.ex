defmodule NavBuddy2.Icon do
  use Phoenix.Component

  attr(:name, :atom, required: true)
  attr(:class, :string, default: "w-5 h-5")

  def icon(assigns) do
    renderer =
      Application.get_env(:nav_buddy2, :icon_renderer)

    if is_nil(renderer) do
      raise """
      nav_buddy2 requires an :icon_renderer to be configured.

      Example:

          config :nav_buddy2,
            icon_renderer: &MyAppWeb.Icon.icon/1
      """
    end

    ~H"""
    <%= @renderer.(%{name: @name, class: @class}) %>
    """
  end
end
