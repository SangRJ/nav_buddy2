defmodule NavBuddy2.Renderer.Sidebar do
  use Phoenix.Component

  alias NavBuddy2.{Resolver, Active, Icon}

  attr(:sidebars, :list, required: true)
  attr(:current_user, :any, required: true)
  attr(:current_path, :string, required: true)
  attr(:collapsed, :boolean, default: false)

  def render(assigns) do
    sidebars =
      assigns.sidebars
      |> Enum.map(&Resolver.filter_sidebar(&1, assigns.current_user))

    assigns = assign(assigns, :sidebars, sidebars)

    ~H"""
    <aside
      x-data="{ collapsed: #{@collapsed} }"
      class={[
        "bg-base-100 border-r border-base-300 min-h-screen transition-all duration-300",
        @collapsed && "w-16",
        !@collapsed && "w-64"
      ]}
    >
      <!-- Collapse Toggle -->
      <div class="flex justify-end p-2">
        <button
          type="button"
          class="btn btn-ghost btn-sm"
          @click="collapsed = !collapsed"
        >
          <Icon.icon
            name={:chevron_left}
            class="w-4 h-4 transition-transform"
            x-bind:class="{ 'rotate-180': collapsed }"
          />
        </button>
      </div>

      <!-- Navigation -->
      <nav class="space-y-4">
        <%= for sidebar <- @sidebars do %>
          <div class="space-y-2">
            <!-- Sidebar Title -->
            <h2
              x-show="!collapsed"
              x-transition.opacity
              class="px-4 text-xs font-semibold uppercase text-base-content/60"
            >
              <%= sidebar.title %>
            </h2>

            <%= for section <- sidebar.sections do %>
              <div class="space-y-1">
                <!-- Section Title -->
                <p
                  x-show="!collapsed"
                  x-transition.opacity
                  class="px-4 pt-2 text-[11px] uppercase tracking-wide text-base-content/50"
                >
                  <%= section.title %>
                </p>

                <!-- Items -->
                <%= for item <- section.items do %>
                  <.nav_item
                    item={item}
                    current_path={@current_path}
                  />
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </nav>
    </aside>
    """
  end

  # Individual Navigation Item

  defp nav_item(assigns) do
    active? = Active.active?(assigns.item, assigns.current_path)
    assigns = assign(assigns, :active?, active?)

    ~H"""
    <div x-data="{ open: false }">
      <!-- Parent Item -->
      <div
        class={[
          "flex items-center gap-3 px-4 py-2 rounded-lg text-sm cursor-pointer select-none",
          @active? && "bg-base-300",
          !@active? && "hover:bg-base-200"
        ]}
        @click={@item.children != [] && "open = !open"}
      >
        <!-- Navigable item -->
        <%= if @item.to do %>
          <.link navigate={@item.to} class="flex items-center gap-3 w-full">
            <Icon.icon name={@item.icon} />
            <span
              x-show="!collapsed"
              x-transition.opacity
              class="truncate"
            >
              <%= @item.label %>
            </span>
          </.link>
        <% else %>
          <!-- Non-navigable group -->
          <Icon.icon name={@item.icon} />
          <span
            x-show="!collapsed"
            x-transition.opacity
            class="truncate"
          >
            <%= @item.label %>
          </span>
        <% end %>

        <!-- Chevron -->
        <%= if @item.children != [] do %>
          <Icon.icon
            name={:chevron_down}
            class="ml-auto w-4 h-4 transition-transform"
            x-show="!collapsed"
            x-bind:class="{ 'rotate-180': open }"
          />
        <% end %>
      </div>

      <!-- Children -->
      <div
        x-show="open && !collapsed"
        x-collapse
        class="ml-6 mt-1 space-y-1"
      >
        <%= for child <- @item.children do %>
          <.link
            navigate={child.to}
            class={[
              "block px-3 py-2 rounded-lg text-sm",
              Active.active?(child, @current_path) && "bg-base-300",
              !Active.active?(child, @current_path) && "hover:bg-base-200"
            ]}
          >
            <%= child.label %>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end
end
