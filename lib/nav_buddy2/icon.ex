defmodule NavBuddy2.Icon do
  @moduledoc """
  Icon renderer component.

  nav_buddy2 is icon-system-agnostic. You must configure an icon renderer
  function that accepts a map with `:name` and `:class` keys.

  ## Configuration

  For Phoenix 1.7+ with Heroicons (the default), you can directly use CoreComponents.icon:

      # config/config.exs
      config :nav_buddy2, icon_renderer: &MyAppWeb.CoreComponents.icon/1

  NavBuddy2 automatically converts icon atom names like `:cog_6_tooth` to
  heroicons-compatible format like `"hero-cog-6-tooth"`.

  ## Custom Icon Systems

  For other icon systems, provide a renderer function that accepts a map with
  `:name` (string) and `:class` keys:

      defmodule MyAppWeb.NavIcon do
        use Phoenix.Component

        def render(assigns) do
          ~H\"\"\"
          <MyIconSystem.icon name={@name} class={@class} />
          \"\"\"
        end
      end

      config :nav_buddy2, icon_renderer: &MyAppWeb.NavIcon.render/1
  """

  use Phoenix.Component

  attr(:name, :atom, required: true, doc: "Icon name atom (e.g., :home, :cog_6_tooth)")
  attr(:class, :string, default: "w-5 h-5", doc: "CSS classes for the icon")
  attr(:"x-bind:class", :string, default: nil, doc: "Alpine.js class binding")
  attr(:rest, :global)

  def icon(assigns) do
    renderer = Application.get_env(:nav_buddy2, :icon_renderer)

    if is_nil(renderer) do
      raise """
      nav_buddy2 requires an :icon_renderer to be configured.

      Add to your config/config.exs:

          config :nav_buddy2,
            icon_renderer: &MyAppWeb.CoreComponents.icon/1

      For Phoenix 1.7+ with Heroicons, CoreComponents.icon works directly.
      """
    end

    # Convert atom name to heroicons-compatible string format
    # :cog_6_tooth -> "hero-cog-6-tooth"
    icon_name =
      assigns.name
      |> to_string()
      |> String.replace("_", "-")
      |> then(&("hero-" <> &1))

    # Re-combine x-bind:class into the attributes if it exists
    extra_opts =
      if assigns[:"x-bind:class"] do
        %{"x-bind:class" => assigns[:"x-bind:class"]}
      else
        %{}
      end

    assigns =
      assigns
      |> assign(:renderer, renderer)
      |> assign(:icon_name, icon_name)
      |> assign(:extra_opts, extra_opts)

    ~H"""
    <%= @renderer.(Map.merge(@rest, Map.merge(%{name: @icon_name, class: @class}, @extra_opts))) %>
    """
  end
end
