defmodule NavBuddy2.Nav do
  use Phoenix.Component

  alias NavBuddy2.Renderer.{IconRail, Sidebar}

  attr(:sidebars, :list, required: true)
  attr(:current_user, :any, required: true)
  attr(:current_path, :string, required: true)

  attr(:layout, :string, default: "sidebar")
  attr(:collapsed, :boolean, default: false)
  attr(:active_sidebar_id, :any, default: nil)

  def nav(assigns) do
    active_id =
      assigns.active_sidebar_id ||
        assigns.sidebars |> List.first() |> Map.get(:id)

    assigns = assign(assigns, :active_sidebar_id, active_id)

    ~H"""
    <div class="flex">
      <%= if @layout == "sidebar" do %>
        <IconRail.render
          sidebars={@sidebars}
          current_user={@current_user}
          active_sidebar_id={@active_sidebar_id}
        />

        <Sidebar.render
          sidebars={Enum.filter(@sidebars, &(&1.id == @active_sidebar_id))}
          current_user={@current_user}
          current_path={@current_path}
          collapsed={@collapsed}
        />
      <% end %>
    </div>
    """
  end
end
