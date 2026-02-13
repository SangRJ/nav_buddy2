defmodule NavBuddy2.Renderer.Horizontal do
  @moduledoc """
  Renders a horizontal navigation bar with dropdown menus.

  Provides the same navigation tree but laid out horizontally
  across the top of the page. Supports:

    - Top-level items as navbar entries
    - Dropdown menus for sections with items
    - Mega-menu style for items with children
    - daisyUI navbar + dropdown components
    - Alpine.js for dropdown behavior
  """

  use Phoenix.Component

  alias NavBuddy2.{Resolver, Active, Icon}

  attr(:sidebars, :list, required: true, doc: "Full list of NavBuddy2.Sidebar structs")
  attr(:current_user, :any, required: true, doc: "Current user for permission filtering")
  attr(:current_path, :string, required: true, doc: "Current route path")
  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:logo, :any, default: nil, doc: "Logo content")

  def render(assigns) do
    sidebars = Resolver.filter(assigns.sidebars, assigns.current_user)
    assigns = assign(assigns, :filtered_sidebars, sidebars)

    ~H"""
    <nav
      class={["navbar bg-base-100/90 backdrop-blur border-b border-base-300 px-4 gap-2 sticky top-0 z-40", @class]}
      x-data="{ openDropdown: null }"
      x-on:click.outside="openDropdown = null"
    >
      <%!-- Logo / Brand --%>
      <div class="navbar-start">
        <%= if @logo do %>
          <%= @logo %>
        <% else %>
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
              <span class="text-primary-content text-sm font-bold">N</span>
            </div>
            <span class="font-semibold text-base-content hidden sm:inline">nav_buddy2</span>
          </div>
        <% end %>
      </div>

      <%!-- Center navigation items --%>
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal gap-1">
          <%= for sidebar <- @filtered_sidebars do %>
            <li>
              <%= if sidebar.sections != [] do %>
                <details
                  x-data="{ open: false }"
                  x-bind:open="open"
                  x-on:click.outside="open = false"
                >
                  <summary
                    class={[
                      "flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-colors",
                      Active.sidebar_active?(sidebar, @current_path) && "bg-primary/10 text-primary"
                    ]}
                    x-on:click="open = !open; $event.preventDefault()"
                  >
                    <Icon.icon name={sidebar.icon} class="w-4 h-4" />
                    <span><%= sidebar.title %></span>
                  </summary>
                  <ul class="menu bg-base-200 rounded-box z-50 w-64 p-2 shadow-lg">
                    <%= for section <- sidebar.sections do %>
                      <%= if section.title do %>
                        <li class="menu-title">
                          <span><%= section.title %></span>
                        </li>
                      <% end %>
                      <%= for item <- section.items do %>
                        <li>
                          <.horizontal_item item={item} current_path={@current_path} />
                        </li>
                      <% end %>
                    <% end %>
                  </ul>
                </details>
              <% else %>
                <span class="flex items-center gap-2 px-3 py-2">
                  <Icon.icon name={sidebar.icon} class="w-4 h-4" />
                  <span><%= sidebar.title %></span>
                </span>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>

      <%!-- Right side --%>
      <div class="navbar-end gap-2">
        <%!-- Search trigger --%>
        <button
          type="button"
          class="btn btn-ghost btn-sm btn-square"
          x-data
          x-on:click="$dispatch('nav-buddy2:open-command-palette')"
        >
          <Icon.icon name={:search} class="w-4 h-4" />
        </button>

        <%!-- Mobile menu trigger --%>
        <button
          type="button"
          class="btn btn-ghost btn-sm btn-square lg:hidden"
          x-data
          x-on:click="$dispatch('nav-buddy2:toggle-mobile-drawer', {})"
        >
          <Icon.icon name={:menu} class="w-5 h-5" />
        </button>

        <%!-- User avatar --%>
        <div class="w-8 h-8 rounded-full bg-base-300 flex items-center justify-center">
          <Icon.icon name={:user} class="w-4 h-4" />
        </div>
      </div>
    </nav>
    """
  end

  attr(:item, :any, required: true)
  attr(:current_path, :string, required: true)

  defp horizontal_item(assigns) do
    active? = Active.active?(assigns.item, assigns.current_path)
    assigns = assign(assigns, :active?, active?)

    ~H"""
    <%= if @item.children != [] do %>
      <details>
        <summary class={[@active? && "text-primary"]}>
          <%= if @item.icon do %>
            <Icon.icon name={@item.icon} class="w-4 h-4" />
          <% end %>
          <span><%= @item.label %></span>
        </summary>
        <ul>
          <%= for child <- @item.children do %>
            <li>
              <.horizontal_item item={child} current_path={@current_path} />
            </li>
          <% end %>
        </ul>
      </details>
    <% else %>
      <%= if @item.to do %>
        <.link
          navigate={@item.to}
          class={[
            "flex items-center gap-2 px-3 py-2 rounded-lg transition-colors",
            if(@active?, do: "bg-primary/10 text-primary", else: "hover:bg-base-200")
          ]}
        >
          <%= if @item.icon do %>
            <Icon.icon name={@item.icon} class="w-4 h-4" />
          <% end %>
          <span><%= @item.label %></span>
          <%= if @item.badge do %>
            <span class={["badge badge-sm", @item.badge_class || "badge-ghost"]}>
              <%= @item.badge %>
            </span>
          <% end %>
        </.link>
      <% else %>
        <span class="flex items-center gap-2 px-3 py-2 rounded-lg text-base-content/70">
          <%= if @item.icon do %>
            <Icon.icon name={@item.icon} class="w-4 h-4" />
          <% end %>
          <span><%= @item.label %></span>
        </span>
      <% end %>
    <% end %>
    """
  end
end
