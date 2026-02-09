defmodule NavBuddy2.Nav do
  @moduledoc """
  The main navigation component — the single entry point for rendering.

  Orchestrates all renderers based on the chosen layout. Supports:

    - `"sidebar"` – Two-level sidebar (icon rail + detail sidebar)
    - `"horizontal"` – Top navigation bar with dropdowns
    - `"auto"` – Sidebar on desktop, drawer on mobile (default)

  The layout choice is persisted client-side via Alpine.js + localStorage,
  so users keep their preference across sessions (like dark/light mode).

  ## Usage

      <NavBuddy2.Nav.nav
        sidebars={@nav_sidebars}
        current_user={@current_user}
        current_path={@current_path}
      />

  ## Layout switching

  The component emits `phx-click="nav_buddy2:switch_layout"` events.
  Handle them in your LiveView:

      def handle_event("nav_buddy2:switch_layout", %{"layout" => layout}, socket) do
        {:noreply, assign(socket, :nav_layout, layout)}
      end

      def handle_event("nav_buddy2:switch_sidebar", %{"id" => id}, socket) do
        {:noreply, assign(socket, :active_sidebar_id, String.to_existing_atom(id))}
      end
  """

  use Phoenix.Component

  alias NavBuddy2.Renderer.{IconRail, Sidebar, Horizontal, MobileDrawer, CommandPalette}

  attr(:sidebars, :list, required: true, doc: "List of NavBuddy2.Sidebar structs")
  attr(:current_user, :any, required: true, doc: "Current user (passed to permission resolver)")
  attr(:current_path, :string, required: true, doc: "Current route path")

  attr(:layout, :string, default: "sidebar", doc: "Layout mode: sidebar | horizontal | auto")
  attr(:collapsed, :boolean, default: false, doc: "Initial sidebar collapsed state")
  attr(:active_sidebar_id, :any, default: nil, doc: "Currently active sidebar id")
  attr(:searchable, :boolean, default: true, doc: "Enable search in sidebar")
  attr(:command_palette, :boolean, default: true, doc: "Enable ⌘K command palette")

  attr(:class, :string, default: "", doc: "Additional CSS classes for root container")
  attr(:sidebar_class, :string, default: "", doc: "Additional CSS classes for sidebar")
  attr(:rail_class, :string, default: "", doc: "Additional CSS classes for icon rail")
  attr(:horizontal_class, :string, default: "", doc: "Additional CSS classes for horizontal nav")

  attr(:logo, :any, default: nil, doc: "Custom logo content")

  slot(:inner_block, doc: "Page content slot (rendered beside navigation)")

  def nav(assigns) do
    active_id =
      assigns.active_sidebar_id ||
        case assigns.sidebars do
          [first | _] -> first.id
          [] -> nil
        end

    active_sidebars =
      Enum.filter(assigns.sidebars, &(&1.id == active_id))

    assigns =
      assigns
      |> assign(:active_sidebar_id, active_id)
      |> assign(:active_sidebars, active_sidebars)

    ~H"""
    <div
      class={["nav-buddy2", @class]}
      x-data={"{ navLayout: $persist('#{@layout}').as('nav_buddy2_layout') }"}
      id="nav-buddy2-root"
    >
      <%!-- Sidebar layout --%>
      <div x-show="navLayout === 'sidebar'" x-cloak class="flex min-h-screen">
        <IconRail.render
          sidebars={@sidebars}
          current_user={@current_user}
          current_path={@current_path}
          active_sidebar_id={@active_sidebar_id}
          class={@rail_class}
          logo={@logo}
        />

        <Sidebar.render
          sidebars={@active_sidebars}
          current_user={@current_user}
          current_path={@current_path}
          collapsed={@collapsed}
          searchable={@searchable}
          class={@sidebar_class}
        />

        <main class="flex-1 min-w-0">
          <%= render_slot(@inner_block) %>
        </main>
      </div>

      <%!-- Horizontal layout --%>
      <div x-show="navLayout === 'horizontal'" x-cloak class="flex flex-col min-h-screen">
        <Horizontal.render
          sidebars={@sidebars}
          current_user={@current_user}
          current_path={@current_path}
          class={@horizontal_class}
          logo={@logo}
        />

        <main class="flex-1">
          <%= render_slot(@inner_block) %>
        </main>
      </div>

      <%!-- Auto layout: sidebar on lg+, horizontal + drawer on mobile --%>
      <div x-show="navLayout === 'auto'" x-cloak>
        <%!-- Desktop: sidebar layout --%>
        <div class="hidden lg:flex min-h-screen">
          <IconRail.render
            sidebars={@sidebars}
            current_user={@current_user}
            current_path={@current_path}
            active_sidebar_id={@active_sidebar_id}
            class={@rail_class}
            logo={@logo}
          />

          <Sidebar.render
            sidebars={@active_sidebars}
            current_user={@current_user}
            current_path={@current_path}
            collapsed={@collapsed}
            searchable={@searchable}
            class={@sidebar_class}
          />

          <main class="flex-1 min-w-0">
            <%= render_slot(@inner_block) %>
          </main>
        </div>

        <%!-- Mobile: horizontal + drawer --%>
        <div class="lg:hidden flex flex-col min-h-screen">
          <Horizontal.render
            sidebars={@sidebars}
            current_user={@current_user}
            current_path={@current_path}
            class={@horizontal_class}
            logo={@logo}
          />

          <main class="flex-1">
            <%= render_slot(@inner_block) %>
          </main>
        </div>
      </div>

      <%!-- Mobile drawer (always rendered for hamburger trigger) --%>
      <MobileDrawer.render
        sidebars={@sidebars}
        current_user={@current_user}
        current_path={@current_path}
      />

      <%!-- Command palette --%>
      <%= if @command_palette do %>
        <CommandPalette.render
          sidebars={@sidebars}
          current_user={@current_user}
        />
      <% end %>

      <%!-- Layout switcher toggle --%>
      <.layout_switcher />
    </div>
    """
  end

  # Layout Switcher

  defp layout_switcher(assigns) do
    ~H"""
    <div
      class="fixed bottom-4 right-4 z-30"
      x-data="{ showMenu: false }"
    >
      <div class="dropdown dropdown-top dropdown-end">
        <button
          type="button"
          class="btn btn-circle btn-sm bg-base-200 shadow-lg border border-base-300 hover:bg-base-300"
          x-on:click="showMenu = !showMenu"
          title="Switch layout"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
            <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z" />
          </svg>
        </button>

        <div
          x-show="showMenu"
          x-transition
          x-on:click.outside="showMenu = false"
          class="menu bg-base-200 rounded-box w-52 p-2 shadow-lg mb-2 border border-base-300"
          style="display: none;"
        >
          <li>
            <button
              type="button"
              x-on:click="navLayout = 'sidebar'; showMenu = false"
              x-bind:class="navLayout === 'sidebar' ? 'active' : ''"
              class="flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M3 4a1 1 0 011-1h4a1 1 0 011 1v12a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm8 0a1 1 0 011-1h4a1 1 0 011 1v12a1 1 0 01-1 1h-4a1 1 0 01-1-1V4z" clip-rule="evenodd" />
              </svg>
              <span>Sidebar</span>
            </button>
          </li>
          <li>
            <button
              type="button"
              x-on:click="navLayout = 'horizontal'; showMenu = false"
              x-bind:class="navLayout === 'horizontal' ? 'active' : ''"
              class="flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h12a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6z" clip-rule="evenodd" />
              </svg>
              <span>Horizontal</span>
            </button>
          </li>
          <li>
            <button
              type="button"
              x-on:click="navLayout = 'auto'; showMenu = false"
              x-bind:class="navLayout === 'auto' ? 'active' : ''"
              class="flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
                <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z" />
              </svg>
              <span>Auto (responsive)</span>
            </button>
          </li>
        </div>
      </div>
    </div>
    """
  end
end
