defmodule NavBuddy2.Renderer.IconRail do
  use Phoenix.Component

  alias NavBuddy2.{Resolver, Icon}

  attr(:sidebars, :list, required: true)
  attr(:current_user, :any, required: true)
  attr(:active_sidebar_id, :any, required: true)

  def render(assigns) do
    sidebars =
      assigns.sidebars
      |> Enum.map(&Resolver.filter_sidebar(&1, assigns.current_user))
      |> Enum.reject(&(&1.sections == []))

    assigns = assign(assigns, :sidebars, sidebars)

    ~H"""
    <aside
      class="w-16 bg-base-100 border-r border-base-300 min-h-screen flex flex-col items-center py-4 gap-2"
    >
      <!-- Top icons -->
      <%= for sidebar <- @sidebars do %>
        <button
          type="button"
          class={[
            "w-10 h-10 flex items-center justify-center rounded-lg transition-colors",
            sidebar.id == @active_sidebar_id && "bg-base-300",
            sidebar.id != @active_sidebar_id && "hover:bg-base-200"
          ]}
          phx-click="nav:switch"
          phx-value-id={sidebar.id}
          title={sidebar.title}
        >
          <Icon.icon name={sidebar.icon} />
        </button>
      <% end %>

      <!-- Spacer -->
      <div class="flex-1"></div>

      <!-- Bottom area (future: settings, profile) -->
      <div class="w-10 h-10 rounded-full bg-base-300"></div>
    </aside>
    """
  end
end
