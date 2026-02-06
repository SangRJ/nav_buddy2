defmodule NavBuddy2.Renderer.MobileDrawer do
  @moduledoc """
  Renders a mobile-friendly drawer overlay for navigation.

  Uses daisyUI drawer + Alpine.js for smooth open/close.
  Listens for the `nav-buddy2:toggle-mobile-drawer` event
  dispatched by the horizontal navbar's hamburger button.

  The drawer renders the full navigation tree in a vertical
  accordion layout optimized for touch interactions.
  """

  use Phoenix.Component

  alias NavBuddy2.{Resolver, Active, Icon}

  attr(:sidebars, :list, required: true, doc: "Full list of NavBuddy2.Sidebar structs")
  attr(:current_user, :any, required: true, doc: "Current user for permission filtering")
  attr(:current_path, :string, required: true, doc: "Current route path")
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  def render(assigns) do
    sidebars = Resolver.filter(assigns.sidebars, assigns.current_user)
    assigns = assign(assigns, :filtered_sidebars, sidebars)

    ~H"""
    <div
      x-data="{ drawerOpen: false }"
      x-on:nav-buddy2:toggle-mobile-drawer.window="drawerOpen = !drawerOpen"
      x-on:keydown.escape.window="drawerOpen = false"
    >
      <%!-- Backdrop --%>
      <div
        x-show="drawerOpen"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        class="fixed inset-0 z-40 bg-black/50"
        x-on:click="drawerOpen = false"
        style="display: none;"
      ></div>

      <%!-- Drawer panel --%>
      <div
        x-show="drawerOpen"
        x-transition:enter="transition ease-out duration-300"
        x-transition:enter-start="-translate-x-full"
        x-transition:enter-end="translate-x-0"
        x-transition:leave="transition ease-in duration-200"
        x-transition:leave-start="translate-x-0"
        x-transition:leave-end="-translate-x-full"
        class={[
          "fixed inset-y-0 left-0 z-50 w-80 max-w-[85vw] bg-base-100 shadow-2xl flex flex-col",
          @class
        ]}
        style="display: none;"
      >
        <%!-- Drawer header --%>
        <div class="flex items-center justify-between p-4 border-b border-base-300">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
              <span class="text-primary-content text-sm font-bold">N</span>
            </div>
            <span class="font-semibold text-base-content">Navigation</span>
          </div>
          <button
            type="button"
            class="btn btn-ghost btn-sm btn-square"
            x-on:click="drawerOpen = false"
          >
            <Icon.icon name={:x_mark} class="w-5 h-5" />
          </button>
        </div>

        <%!-- Scrollable content --%>
        <div
          class="flex-1 overflow-y-auto p-4 space-y-4"
          x-data="{ expanded: new Set() }"
        >
          <%= for sidebar <- @filtered_sidebars do %>
            <div class="space-y-2">
              <%!-- Sidebar heading --%>
              <h3 class="text-xs font-semibold uppercase tracking-wider text-base-content/50 px-2">
                <span class="flex items-center gap-2">
                  <Icon.icon name={sidebar.icon} class="w-4 h-4" />
                  <%= sidebar.title %>
                </span>
              </h3>

              <%= for section <- sidebar.sections do %>
                <div class="space-y-0.5">
                  <%= if section.title do %>
                    <p class="px-3 py-1 text-xs font-medium text-base-content/40 uppercase tracking-wide">
                      <%= section.title %>
                    </p>
                  <% end %>

                  <%= for {item, item_idx} <- Enum.with_index(section.items) do %>
                    <.drawer_item
                      item={item}
                      item_key={"drawer-#{sidebar.id}-#{item_idx}"}
                      current_path={@current_path}
                    />
                  <% end %>
                </div>
              <% end %>
            </div>

            <div class="divider my-1"></div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:item, :any, required: true)
  attr(:item_key, :string, required: true)
  attr(:current_path, :string, required: true)

  defp drawer_item(assigns) do
    active? = Active.active?(assigns.item, assigns.current_path)
    has_children? = assigns.item.children != []

    assigns =
      assigns
      |> assign(:active?, active?)
      |> assign(:has_children?, has_children?)

    ~H"""
    <div>
      <div class={[
        "flex items-center gap-3 px-3 py-2.5 rounded-lg cursor-pointer select-none transition-colors",
        @active? && "bg-primary/10 text-primary",
        !@active? && "text-base-content hover:bg-base-200"
      ]}>
        <%= if @item.to do %>
          <div x-on:click="drawerOpen = false">
            <.link navigate={@item.to} class="flex items-center gap-3 w-full">
            <%= if @item.icon do %>
              <Icon.icon name={@item.icon} class="w-5 h-5" />
            <% end %>
            <span class="flex-1 text-sm"><%= @item.label %></span>
            <%= if @item.badge do %>
              <span class={["badge badge-sm", @item.badge_class || "badge-ghost"]}>
                <%= @item.badge %>
              </span>
            <% end %>
          </.link>
          </div>
        <% else %>
          <div
            class="flex items-center gap-3 w-full"
            x-on:click={"
              if (expanded.has('#{@item_key}')) {
                expanded.delete('#{@item_key}');
              } else {
                expanded.add('#{@item_key}');
              }
              expanded = new Set(expanded);
            "}
          >
            <%= if @item.icon do %>
              <Icon.icon name={@item.icon} class="w-5 h-5" />
            <% end %>
            <span class="flex-1 text-sm"><%= @item.label %></span>
            <%= if @has_children? do %>
              <span
                class="transition-transform duration-200"
                x-bind:class={"expanded.has('#{@item_key}') ? 'rotate-180' : ''"}
              >
                <Icon.icon name={:chevron_down} class="w-4 h-4 opacity-50" />
              </span>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Children --%>
      <%= if @has_children? do %>
        <div
          x-show={"expanded.has('#{@item_key}')"}
          x-collapse
          class="ml-6 mt-0.5 space-y-0.5 border-l-2 border-base-300 pl-3"
        >
          <%= for child <- @item.children do %>
            <.drawer_child child={child} current_path={@current_path} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:child, :any, required: true)
  attr(:current_path, :string, required: true)

  defp drawer_child(assigns) do
    active? = Active.active?(assigns.child, assigns.current_path)
    assigns = assign(assigns, :active?, active?)

    ~H"""
    <%= if @child.to do %>
      <div x-on:click="drawerOpen = false">
        <.link
          navigate={@child.to}
          class={[
            "block px-3 py-2 rounded-md text-sm transition-colors",
            @active? && "bg-primary/10 text-primary font-medium",
            !@active? && "text-base-content/70 hover:bg-base-200 hover:text-base-content"
          ]}
        >
          <%= @child.label %>
        </.link>
      </div>
    <% else %>
      <span class="block px-3 py-2 text-sm text-base-content/70">
        <%= @child.label %>
      </span>
    <% end %>
    """
  end
end
