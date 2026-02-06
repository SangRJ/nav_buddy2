defmodule NavBuddy2.Nav do
  use Phoenix.Component

  attr(:sidebars, :list, required: true)
  attr(:current_user, :any, required: true)
  attr(:current_path, :string, required: true)

  attr(:layout, :string, default: "sidebar")
  attr(:collapsed, :boolean, default: false)

  def nav(assigns) do
    ~H"""
    <%= case @layout do %>
      <% "sidebar" -> %>
        <NavBuddy2.Renderer.Sidebar.render
          sidebars={@sidebars}
          current_user={@current_user}
          current_path={@current_path}
          collapsed={@collapsed}
        />

      <% _ -> %>
        <NavBuddy2.Renderer.Sidebar.render
          sidebars={@sidebars}
          current_user={@current_user}
          current_path={@current_path}
          collapsed={@collapsed}
        />
    <% end %>
    """
  end
end
