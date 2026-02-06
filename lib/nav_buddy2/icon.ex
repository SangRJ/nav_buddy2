defmodule NavBuddy2.Icon do
  @moduledoc """
  Icon renderer component.

  nav_buddy2 is icon-system-agnostic. You must configure an icon renderer
  function that accepts a map with `:name` and `:class` keys.

  ## Configuration

      # config/config.exs
      config :nav_buddy2, icon_renderer: &MyAppWeb.CoreComponents.icon/1

  ## Heroicons example (Phoenix 1.7+ default)

      # The renderer receives %{name: :home, class: "w-5 h-5"}
      # and should return a HEEx template rendering that icon.

      defmodule MyAppWeb.NavIcon do
        use Phoenix.Component

        def render(assigns) do
          ~H\"\"\"
          <.icon name={"hero-\#{@name}"} class={@class} />
          \"\"\"
        end
      end

      config :nav_buddy2, icon_renderer: &MyAppWeb.NavIcon.render/1
  """

  use Phoenix.Component

  attr(:name, :atom, required: true, doc: "Icon name atom")
  attr(:class, :string, default: "w-5 h-5", doc: "CSS classes for the icon")
  attr(:rest, :global)

  def icon(assigns) do
    renderer = Application.get_env(:nav_buddy2, :icon_renderer)

    if is_nil(renderer) do
      raise """
      nav_buddy2 requires an :icon_renderer to be configured.

      Add to your config/config.exs:

          config :nav_buddy2,
            icon_renderer: &MyAppWeb.NavIcon.render/1

      Your renderer function should accept a map with :name and :class keys.
      """
    end

    assigns = assign(assigns, :renderer, renderer)

    ~H"""
    <%= @renderer.(%{name: @name, class: @class}) %>
    """
  end
end
