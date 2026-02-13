defmodule NavBuddy2.Renderer.IconRail do
  @moduledoc """
  Renders the Level 1 icon rail — a vertical strip of icons
  representing each sidebar section.

  This mirrors the left-hand icon column from the React reference,
  with top-positioned and bottom-positioned items separated by a spacer.

  Uses daisyUI utility classes and Alpine.js for interactivity.
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
            <span class="text-primary-content text-xs font-bold">N</span>
          </div>
        <% end %>
      </div>

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
    # Check if this sidebar is active (visual state tracks URL, not just panel open state)
    is_active = Active.sidebar_active?(assigns.sidebar, assigns.current_path)

    assigns = assign(assigns, :is_active, is_active)

    ~H"""
    <div class="tooltip tooltip-right z-50" data-tip={@sidebar.title}>
      <button
        type="button"
        class={[
          "w-10 h-10 flex items-center justify-center rounded-lg transition-all duration-300",
          if(@is_active, do: "bg-primary text-primary-content shadow-sm", else: "text-base-content/60 hover:bg-base-200 hover:text-base-content")
        ]}
        phx-click="nav_buddy2:switch_sidebar"
        phx-value-id={@sidebar.id}
      >
        <Icon.icon name={@sidebar.icon} class="w-5 h-5" />
      </button>
    </div>
    """
  end
end
