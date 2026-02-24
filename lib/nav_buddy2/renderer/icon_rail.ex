defmodule NavBuddy2.Renderer.IconRail do
  @moduledoc """
  Renders the Level 1 icon rail — a vertical strip of icons
  representing each sidebar section.

  This mirrors the left-hand icon column from the React reference,
  with top-positioned and bottom-positioned items separated by a spacer.

  Features:
    - Simple-link sidebars navigate directly on click
    - Multi-item sidebars show a flyout panel when the detail sidebar is collapsed
    - Toggle button to expand/collapse the detail sidebar
    - Uses daisyUI utility classes and Alpine.js for interactivity
  """

  use Phoenix.Component

  alias NavBuddy2.{Resolver, Icon, Active}

  attr(:sidebars, :list, required: true, doc: "Full list of NavBuddy2.Sidebar structs")
  attr(:current_user, :any, required: true, doc: "Current user for permission filtering")
  attr(:active_sidebar_id, :any, required: true, doc: "Currently active sidebar id")
  attr(:current_path, :string, default: "/", doc: "Current route path for auto-active detection")
  attr(:class, :string, default: "", doc: "Additional CSS classes for the rail container")
  attr(:logo, :any, default: nil, doc: "Slot or assign for a custom logo at the top")

  def render(assigns) do
    sidebars = Resolver.filter(assigns.sidebars, assigns.current_user)

    top_items = Enum.filter(sidebars, &(&1.position == :top))
    bottom_items = Enum.filter(sidebars, &(&1.position == :bottom))

    assigns =
      assigns
      |> assign(:top_items, top_items)
      |> assign(:bottom_items, bottom_items)

    ~H"""
    <aside class={[
      "w-16 bg-base-100 border-r border-base-300 flex flex-col items-center py-4 gap-2 shrink-0 sticky top-0 h-screen rounded-l-2xl z-20",
      @class
    ]}>
      <%!-- Logo area --%>
      <div class="mb-2 w-10 h-10 flex items-center justify-center">
        <%= if @logo do %>
          <%= @logo %>
        <% else %>
          <div class="w-7 h-7 rounded-lg bg-primary flex items-center justify-center">
            <span class="text-primary-content text-xs font-bold">NB</span>
          </div>
        <% end %>
      </div>

      <div class="divider my-0 mx-0 h-0"></div>

      <%!-- Top navigation icons --%>
      <div class="flex flex-col gap-1 w-full items-center">
        <%= for sidebar <- @top_items do %>
          <.rail_button
            sidebar={sidebar}
            active_sidebar_id={@active_sidebar_id}
            current_path={@current_path}
          />
        <% end %>
      </div>

      <%!-- Spacer --%>
      <div class="flex-1"></div>

      <%!-- Bottom navigation icons --%>
      <div class="flex flex-col gap-1 w-full items-center">
        <%= for sidebar <- @bottom_items do %>
          <.rail_button
            sidebar={sidebar}
            active_sidebar_id={@active_sidebar_id}
            current_path={@current_path}
          />
        <% end %>
      </div>

      <%!-- User avatar placeholder --%>
      <div class="tooltip tooltip-right" data-tip="Profile">
        <div class="w-8 h-8 rounded-full bg-base-300 flex items-center justify-center cursor-pointer hover:ring-2 hover:ring-primary transition-all">
          <Icon.icon name={:user} class="w-4 h-4" />
        </div>
      </div>
    </aside>
    """
  end

  attr(:sidebar, :any, required: true)
  attr(:active_sidebar_id, :any, required: true)
  attr(:current_path, :string, required: true)

  defp rail_button(assigns) do
    is_active = Active.sidebar_active?(assigns.sidebar, assigns.current_path)
    simple_link = Active.simple_link_path(assigns.sidebar)

    assigns =
      assigns
      |> assign(:is_active, is_active)
      |> assign(:simple_link, simple_link)

    ~H"""
    <div
      class="relative"
      x-data="{ showFlyout: false, flyoutPos: { left: '0px', top: '0px' } }"
      @click.outside="showFlyout = false"
    >
      <div class="tooltip tooltip-right z-50" data-tip={@sidebar.title}>
        <%= if @simple_link do %>
          <%!-- Simple link: always navigate directly --%>
          <div
            class={[
              "w-10 h-10 flex items-center justify-center rounded-lg transition-colors duration-200",
              if(@is_active, do: "bg-primary text-primary-content shadow-sm", else: "text-base-content/60 hover:bg-base-200 hover:text-base-content")
            ]}
            x-on:mouseenter="$el.style.animation = 'nb2-wiggle 0.4s ease-in-out'"
            x-on:animationend="$el.style.animation = ''"
          >
            <.link navigate={@simple_link} class="flex items-center justify-center w-full h-full">
              <Icon.icon name={@sidebar.icon} class="w-5 h-5" />
            </.link>
          </div>
        <% else %>
          <%!-- Multi-item sidebar: two buttons, one for collapsed, one for expanded --%>
          <button
            type="button"
            class={[
              "w-10 h-10 flex items-center justify-center rounded-lg transition-colors duration-200",
              if(@is_active, do: "bg-primary text-primary-content shadow-sm", else: "text-base-content/60 hover:bg-base-200 hover:text-base-content")
            ]}
            x-show="$store.nav.sidebarCollapsed"
            x-on:mouseenter="$el.style.animation = 'nb2-wiggle 0.4s ease-in-out'"
            x-on:animationend="$el.style.animation = ''"
            @click="
              const rail = $el.closest('aside');
              const railRect = rail.getBoundingClientRect();
              const btnRect = $el.getBoundingClientRect();
              const viewH = window.innerHeight;
              const pad = 12;
              const btnCenterY = btnRect.top + btnRect.height / 2;
              flyoutPos = {
                left: (railRect.right + 8) + 'px',
                top: btnRect.top + 'px',
                bottom: 'auto'
              };
              showFlyout = !showFlyout;
              $nextTick(() => {
                const panel = $el.closest('[x-data]').querySelector('[x-ref=&quot;flyoutPanel&quot;]');
                if (panel) {
                  const pH = panel.offsetHeight;
                  let top;
                  if (btnCenterY > viewH / 2) {
                    top = btnRect.bottom - pH;
                  } else {
                    top = btnRect.top;
                  }
                  if (top + pH > viewH - pad) top = viewH - pH - pad;
                  if (top < pad) top = pad;
                  flyoutPos = {
                    left: (railRect.right + 8) + 'px',
                    top: top + 'px',
                    bottom: 'auto'
                  };
                }
              });
            "
          >
            <Icon.icon name={@sidebar.icon} class="w-5 h-5" />
          </button>
          <button
            type="button"
            class={[
              "w-10 h-10 flex items-center justify-center rounded-lg transition-colors duration-200",
              if(@is_active, do: "bg-primary text-primary-content shadow-sm", else: "text-base-content/60 hover:bg-base-200 hover:text-base-content")
            ]}
            x-show="!$store.nav.sidebarCollapsed"
            x-on:mouseenter="$el.style.animation = 'nb2-wiggle 0.4s ease-in-out'"
            x-on:animationend="$el.style.animation = ''"
            phx-click="nav_buddy2:switch_sidebar"
            phx-value-id={@sidebar.id}
          >
            <Icon.icon name={@sidebar.icon} class="w-5 h-5" />
          </button>
        <% end %>
      </div>

      <%!-- Flyout panel (only for multi-item sidebars in collapsed mode) --%>
      <%= unless @simple_link do %>
        <div
          x-ref="flyoutPanel"
          x-show="showFlyout"
          x-bind:style="'position:fixed;z-index:9999;min-width:17rem;left:' + flyoutPos.left + ';top:' + flyoutPos.top"
          x-transition:enter="transition ease-out duration-200"
          x-transition:enter-start="opacity-0 scale-95"
          x-transition:enter-end="opacity-100 scale-100"
          x-transition:leave="transition ease-in duration-150"
          x-transition:leave-start="opacity-100 scale-100"
          x-transition:leave-end="opacity-0 scale-95"
          x-cloak
        >
          <.flyout_content sidebar={@sidebar} current_path={@current_path} />
        </div>
      <% end %>
    </div>
    """
  end

  # Flyout panel content — compact rendering of sidebar sections/items

  attr(:sidebar, :any, required: true)
  attr(:current_path, :string, required: true)

  defp flyout_content(assigns) do
    ~H"""
    <ul
      class="menu bg-base-200 rounded-box shadow-lg border border-base-300 w-72 max-h-[70vh] overflow-y-auto p-2"
      x-data="{ flyoutExpanded: new Set() }"
    >
      <%!-- Sections --%>
      <%= for {section, section_idx} <- Enum.with_index(@sidebar.sections) do %>
        <%= if section.title do %>
          <li class="menu-title">
            <span><%= section.title %></span>
          </li>
        <% end %>
        <%= for {item, item_idx} <- Enum.with_index(section.items) do %>
          <.flyout_item
            item={item}
            item_key={"flyout-#{@sidebar.id}-#{section_idx}-#{item_idx}"}
            current_path={@current_path}
          />
        <% end %>
      <% end %>
    </ul>
    """
  end

  attr(:item, :any, required: true)
  attr(:item_key, :string, required: true)
  attr(:current_path, :string, required: true)

  defp flyout_item(assigns) do
    has_children? = assigns.item.children != []
    active? = Active.active?(assigns.item, assigns.current_path)

    child_active? =
      has_children? && Enum.any?(assigns.item.children, &Active.active?(&1, assigns.current_path))

    assigns =
      assigns
      |> assign(:has_children?, has_children?)
      |> assign(:active?, active?)
      |> assign(:child_active?, child_active?)

    ~H"""
    <li>
      <%= if @item.to do %>
        <.link
          navigate={@item.to}
          class={[
            "mb-1",
            if(@active?, do: "bg-primary/10 text-primary font-medium", else: "")
          ]}
          {if @item.target, do: [target: @item.target], else: []}
        >
          <%= if @item.icon do %>
            <Icon.icon name={@item.icon} class="w-4 h-4 shrink-0" />
          <% end %>
          <span class="truncate"><%= @item.label %></span>
          <%= if @item.badge do %>
            <span class={["badge badge-xs", @item.badge_class || "badge-ghost"]}>
              <%= @item.badge %>
            </span>
          <% end %>
        </.link>
      <% else %>
        <%!-- Non-navigable group heading with children toggle --%>
        <button
          type="button"
          class={["mb-2", if(@child_active?, do: "bg-primary/10 text-primary font-medium", else: "")]}
          x-on:click={"
            if (flyoutExpanded.has('#{@item_key}')) {
              flyoutExpanded.delete('#{@item_key}');
            } else {
              flyoutExpanded.add('#{@item_key}');
            }
            flyoutExpanded = new Set(flyoutExpanded);
          "}
        >
          <%= if @item.icon do %>
            <Icon.icon name={@item.icon} class="w-4 h-4 shrink-0" />
          <% end %>
          <span class="truncate flex-1 text-left"><%= @item.label %></span>
          <span
            class="shrink-0 transition-transform duration-200"
            x-bind:class={"flyoutExpanded.has('#{@item_key}') ? 'rotate-180' : ''"}
          >
            <Icon.icon name={:chevron_down} class="w-3 h-3 opacity-50" />
          </span>
        </button>
      <% end %>

      <%!-- Children --%>
      <%= if @has_children? do %>
        <ul
          x-show={"flyoutExpanded.has('#{@item_key}')"}
          x-collapse
        >
          <%= for child <- @item.children do %>
            <.flyout_child child={child} current_path={@current_path} />
          <% end %>
        </ul>
      <% end %>
    </li>
    """
  end

  attr(:child, :any, required: true)
  attr(:current_path, :string, required: true)

  defp flyout_child(assigns) do
    active? = Active.active?(assigns.child, assigns.current_path)
    assigns = assign(assigns, :active?, active?)

    ~H"""
    <li>
      <%= if @child.to do %>
        <.link
          navigate={@child.to}
          class={[if(@active?, do: "bg-primary/10 text-primary font-medium", else: "")]}
        >
          <%= @child.label %>
        </.link>
      <% else %>
        <span class="menu-title"><%= @child.label %></span>
      <% end %>
    </li>
    """
  end
end
