defmodule NavBuddy2.Renderer.Sidebar do
  @moduledoc """
  Renders the Level 2+3 detail sidebar panel.

  This is the collapsible sidebar that displays sections and items
  for the currently active icon rail entry. Features:

    - Collapsible width (w-72 → w-16) with smooth soft-spring transitions
    - Section headings that hide when collapsed
    - Expandable/collapsible menu items with children
    - Search input
    - daisyUI theming (adapts to any theme)
    - Client-side active state tracking (no re-renders on navigation!)
    - Alpine.js animations
  """

  use Phoenix.Component

  alias NavBuddy2.{Resolver, Icon, Active}


  attr(:sidebars, :list,
    required: true,
    doc: "List of sidebar structs (usually filtered to active)"
  )

  attr(:current_user, :any, required: true, doc: "Current user for permission filtering")
  attr(:current_path, :string, required: true, doc: "Current route path (used for initial render only)")
  attr(:collapsed, :boolean, default: false, doc: "Initial collapsed state")
  attr(:searchable, :boolean, default: true, doc: "Show search input")
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  def render(assigns) do
    sidebars =
      assigns.sidebars
      |> Enum.map(&Resolver.filter_sidebar(&1, assigns.current_user))

    assigns = assign(assigns, :sidebars, sidebars)

    ~H"""
    <aside
      x-data={"{
        collapsed: #{@collapsed},
        search: '',
        expanded: new Set()
      }"}
      x-init="$watch('collapsed', val => $dispatch('nav-buddy2:sidebar-collapsed', { collapsed: val }))"
      class={[
        "bg-base-100 border-r border-base-300 flex flex-col shrink-0 overflow-hidden sticky top-0 h-screen rounded-r-2xl",
        @class
      ]}
      x-bind:class="collapsed ? 'w-16' : 'w-72'"
      style="transition: width 500ms cubic-bezier(0.25, 1.1, 0.4, 1)"
    >
      <%= for sidebar <- @sidebars do %>
        <%!-- Header with title and collapse toggle --%>
        <div class="flex items-center justify-between px-2 pt-4 pb-2 shrink-0">
          <div
            x-show="!collapsed"
            x-transition:enter="transition ease-out duration-200"
            x-transition:enter-start="opacity-0 -translate-x-2"
            x-transition:enter-end="opacity-100 translate-x-0"
            x-transition:leave="transition ease-in duration-150"
            x-transition:leave-start="opacity-100"
            x-transition:leave-end="opacity-0"
            class="px-2"
          >
            <h2 class="text-lg font-semibold text-base-content truncate">
              <%= sidebar.title %>
            </h2>
          </div>

          <button
            type="button"
            class="btn btn-ghost btn-sm btn-square shrink-0"
            x-on:click="collapsed = !collapsed"
            x-bind:title="collapsed ? 'Expand sidebar' : 'Collapse sidebar'"
          >
            <span
              class="transition-transform duration-300"
              x-bind:class="collapsed ? 'rotate-180' : ''"
              style="transition-timing-function: cubic-bezier(0.25, 1.1, 0.4, 1)"
            >
              <Icon.icon name={:chevron_left} class="w-4 h-4" />
            </span>
          </button>
        </div>

        <%!-- Search --%>
        <%= if @searchable do %>
          <.search_input />
        <% end %>

        <%!-- Scrollable nav content --%>
        <nav class="flex-1 overflow-y-auto overflow-x-hidden px-2 pb-4 space-y-1">
          <%= for {section, section_idx} <- Enum.with_index(sidebar.sections) do %>
            <.section
              section={section}
              section_idx={section_idx}
              sidebar_id={sidebar.id}
              current_path={@current_path}
            />
          <% end %>
        </nav>
      <% end %>
    </aside>
    """
  end


  # Search


  defp search_input(assigns) do
    ~H"""
    <div
      class="px-2 pb-2 shrink-0"
      x-show="!collapsed"
      x-transition:enter="transition ease-out duration-200 delay-75"
      x-transition:enter-start="opacity-0"
      x-transition:enter-end="opacity-100"
      x-transition:leave="transition ease-in duration-100"
      x-transition:leave-start="opacity-100"
      x-transition:leave-end="opacity-0"
    >
      <label class="input input-sm input-bordered flex items-center gap-2 bg-base-200">
        <Icon.icon name={:magnifying_glass} class="w-4 h-4 opacity-50" />
        <input
          type="text"
          placeholder="Search..."
          class="grow bg-transparent border-none focus:outline-none text-sm"
          x-model="search"
        />
      </label>
    </div>
    """
  end


  # Section (Level 2)


  attr(:section, :any, required: true)
  attr(:section_idx, :integer, required: true)
  attr(:sidebar_id, :any, required: true)
  attr(:current_path, :string, required: true)

  defp section(assigns) do
    ~H"""
    <div class="pt-2">
      <%!-- Section title --%>
      <%= if @section.title do %>
        <div
          x-show="!collapsed"
          x-transition:enter="transition ease-out duration-200"
          x-transition:enter-start="opacity-0"
          x-transition:enter-end="opacity-100"
          x-transition:leave="transition ease-in duration-100"
          x-transition:leave-start="opacity-100"
          x-transition:leave-end="opacity-0"
          class="px-3 py-2"
        >
          <span class="text-xs font-medium uppercase tracking-wider text-base-content/50">
            <%= @section.title %>
          </span>
        </div>
      <% end %>

      <%!-- Items --%>
      <div class="space-y-0.5">
        <%= for {item, item_idx} <- Enum.with_index(@section.items) do %>
          <.nav_item
            item={item}
            item_key={"#{@sidebar_id}-#{@section_idx}-#{item_idx}"}
            current_path={@current_path}
          />
        <% end %>
      </div>
    </div>
    """
  end

  # Nav Item (Level 3) - Uses client-side active tracking

  attr(:item, :any, required: true)
  attr(:item_key, :string, required: true)
  attr(:current_path, :string, required: true)

  defp nav_item(assigns) do
    has_children? = assigns.item.children != []

    # Calculate active state server-side
    active? = Active.active?(assigns.item, assigns.current_path)

    # Check if any child is active (for parent highlighting/expansion)
    child_active? =
      has_children? && Enum.any?(assigns.item.children, &Active.active?(&1, assigns.current_path))

    assigns =
      assigns
      |> assign(:has_children?, has_children?)
      |> assign(:active?, active?)
      |> assign(:child_active?, child_active?)
      |> assign(:item_path, assigns.item.to)

    ~H"""
    <div
      x-data={"{
        get isOpen() { return expanded.has('#{@item_key}') }
      }"}
      x-init={"if (#{@child_active?}) expanded.add('#{@item_key}')"}
      x-show={"search === '' || '#{String.downcase(@item.label)}'.includes(search.toLowerCase())"}
    >
      <%!-- Parent item row --%>
      <div
        class={[
          "group flex items-center gap-3 rounded-lg cursor-pointer select-none transition-all duration-300",
          if(@active? || @child_active?, do: "bg-primary/10 text-primary", else: "text-base-content hover:bg-base-200")
        ]}
        x-bind:class="{
          'justify-center p-2': collapsed,
          'px-3 py-2': !collapsed
        }"
        style="transition-timing-function: cubic-bezier(0.25, 1.1, 0.4, 1)"
      >
        <%= if @item.to do %>
          <.link
            navigate={@item.to}
            class="flex items-center gap-3 w-full min-w-0"
            {if @item.target, do: [target: @item.target], else: []}
          >
            <.item_content
              item={@item}
              has_children?={@has_children?}
              item_key={@item_key}
              active?={@active?}
              child_active?={@child_active?}
            />
          </.link>
        <% else %>
          <div
            class="flex items-center gap-3 w-full min-w-0"
            x-on:click={"
              if (expanded.has('#{@item_key}')) {
                expanded.delete('#{@item_key}');
              } else {
                expanded.add('#{@item_key}');
              }
              expanded = new Set(expanded);
            "}
          >
            <.item_content
              item={@item}
              has_children?={@has_children?}
              item_key={@item_key}
              active?={@active?}
              child_active?={@child_active?}
            />
          </div>
        <% end %>
      </div>

      <%!-- Children --%>
      <%= if @has_children? do %>
        <div
          x-show={"expanded.has('#{@item_key}') && !collapsed"}
          x-collapse
          class="ml-4 mt-0.5 space-y-0.5 border-l-2 border-base-300 pl-3"
        >
          <%= for child <- @item.children do %>
            <.child_item child={child} current_path={@current_path} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:item, :any, required: true)
  attr(:has_children?, :boolean, required: true)
  attr(:item_key, :string, required: true)
  attr(:active?, :boolean, required: true)
  attr(:child_active?, :boolean, required: true)

  defp item_content(assigns) do
    ~H"""
    <%!-- Icon --%>
    <%= if @item.icon do %>
      <span class="shrink-0">
        <Icon.icon
          name={@item.icon}
          class={[
            "w-5 h-5 transition-colors duration-200",
            if(@active? || @child_active?, do: "text-primary", else: "text-base-content/70 group-hover:text-base-content")
          ]}
        />
      </span>
    <% end %>

    <%!-- Label --%>
    <span
      x-show="!collapsed"
      x-transition:enter="transition ease-out duration-200"
      x-transition:enter-start="opacity-0"
      x-transition:enter-end="opacity-100"
      x-transition:leave="transition ease-in duration-100"
      x-transition:leave-start="opacity-100"
      x-transition:leave-end="opacity-0"
      class="flex-1 truncate text-sm"
    >
      <%= @item.label %>
    </span>

    <%!-- Badge --%>
    <%= if @item.badge do %>
      <span
        x-show="!collapsed"
        class={["badge badge-sm", @item.badge_class || "badge-ghost"]}
      >
        <%= @item.badge %>
      </span>
    <% end %>

    <%!-- Chevron for items with children --%>
    <%= if @has_children? do %>
      <span
        x-show="!collapsed"
        class="shrink-0 transition-transform duration-200"
        x-bind:class={"expanded.has('#{@item_key}') ? 'rotate-180' : ''"}
      >
        <Icon.icon name={:chevron_down} class="w-4 h-4 opacity-50" />
      </span>
    <% end %>
    """
  end


  # Child Item (deepest level) - Uses server-side active tracking


  attr(:child, :any, required: true)
  attr(:current_path, :string, required: true)

  defp child_item(assigns) do
    active? = Active.active?(assigns.child, assigns.current_path)
    assigns = assign(assigns, :active?, active?)

    ~H"""
    <div>
      <%= if @child.to do %>
        <div class={[
          "rounded-md transition-colors duration-200",
          if(@active?, do: "bg-primary/10 text-primary font-medium", else: "text-base-content/70 hover:bg-base-200 hover:text-base-content")
        ]}>
          <.link
            navigate={@child.to}
            class="block px-3 py-1.5 rounded-md text-sm text-inherit"
          >
            <%= @child.label %>
          </.link>
        </div>
      <% else %>
        <span class="block px-3 py-1.5 text-sm text-base-content/70">
          <%= @child.label %>
        </span>
      <% end %>
    </div>
    """
  end
end
