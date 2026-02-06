defmodule NavBuddy2 do
  @moduledoc """
  Permission-aware, multi-layout navigation engine for Phoenix LiveView.

  nav_buddy2 takes a single navigation definition and renders it as:

    - **Two-level sidebar** – icon rail + collapsible detail panel
    - **Horizontal navbar** – top navigation bar with dropdowns
    - **Mobile drawer** – slide-out drawer for small screens
    - **Command palette** – ⌘K / Ctrl+K searchable overlay

  ## Quick Start

  ### 1. Define your navigation tree

      defmodule MyAppWeb.Navigation do
        alias NavBuddy2.{Sidebar, Section, Item}

        def sidebars do
          [
            %Sidebar{
              id: :dashboard,
              title: "Dashboard",
              icon: :home,
              position: :top,
              sections: [
                %Section{
                  title: "Overview",
                  items: [
                    %Item{
                      label: "Home",
                      icon: :home,
                      to: "/",
                      exact: true
                    },
                    %Item{
                      label: "Analytics",
                      icon: :chart_bar,
                      to: "/analytics",
                      permission: :view_analytics,
                      children: [
                        %Item{label: "Revenue", to: "/analytics/revenue"},
                        %Item{label: "Users", to: "/analytics/users"}
                      ]
                    }
                  ]
                }
              ]
            },
            %Sidebar{
              id: :settings,
              title: "Settings",
              icon: :cog,
              position: :bottom,
              permission: :manage_settings,
              sections: [
                %Section{
                  title: "Account",
                  items: [
                    %Item{label: "Profile", icon: :user, to: "/settings/profile"},
                    %Item{label: "Security", icon: :shield, to: "/settings/security"}
                  ]
                }
              ]
            }
          ]
        end
      end

  ### 2. Configure icon renderer

      # config/config.exs
      config :nav_buddy2,
        icon_renderer: &MyAppWeb.NavIcon.render/1

  ### 3. Optionally configure permissions

      config :nav_buddy2,
        permission_resolver: MyApp.NavPermissions

  ### 4. Use in your layout

      <NavBuddy2.Nav.nav
        sidebars={MyAppWeb.Navigation.sidebars()}
        current_user={@current_user}
        current_path={@current_path}
      >
        <main class="p-6">
          <%= @inner_content %>
        </main>
      </NavBuddy2.Nav.nav>

  ### 5. Handle events in your LiveView

      def handle_event("nav_buddy2:switch_sidebar", %{"id" => id}, socket) do
        {:noreply, assign(socket, :active_sidebar_id, String.to_existing_atom(id))}
      end

  ## Alpine.js Setup

  nav_buddy2 uses Alpine.js for client-side UI state (collapse, dropdowns,
  layout persistence). Add the plugin to your `app.js`:

      import NavBuddy2Plugin from "nav_buddy2/assets/nav_buddy2"
      Alpine.plugin(NavBuddy2Plugin)

  You also need the `@alpinejs/persist` plugin for layout preference persistence:

      import persist from "@alpinejs/persist"
      Alpine.plugin(persist)

  ## Design Principles

    1. One navigation tree, many renderers
    2. Permissions resolved before rendering
    3. Client-side UI state, server-side data state
    4. No ownership of host concerns (icons, auth, JSON, DB)
    5. Stable data contracts, composable renderers
  """

  alias NavBuddy2.{Sidebar, Section, Item}

  @doc """
  Convenience function to build a sidebar struct.
  """
  @spec sidebar(keyword()) :: Sidebar.t()
  def sidebar(attrs) when is_list(attrs) do
    struct!(Sidebar, attrs)
  end

  @doc """
  Convenience function to build a section struct.
  """
  @spec section(keyword()) :: Section.t()
  def section(attrs) when is_list(attrs) do
    struct!(Section, attrs)
  end

  @doc """
  Convenience function to build an item struct.
  """
  @spec item(keyword()) :: Item.t()
  def item(attrs) when is_list(attrs) do
    struct!(Item, attrs)
  end

  @doc """
  Builds a complete navigation tree from a keyword list DSL.

  ## Example

      NavBuddy2.build([
        dashboard: [
          title: "Dashboard",
          icon: :home,
          sections: [
            [title: "Main", items: [
              [label: "Home", icon: :home, to: "/"]
            ]]
          ]
        ]
      ])
  """
  @spec build(keyword()) :: [Sidebar.t()]
  def build(definition) when is_list(definition) do
    Enum.map(definition, fn {id, opts} ->
      sections =
        Keyword.get(opts, :sections, [])
        |> Enum.map(fn section_opts ->
          items =
            Keyword.get(section_opts, :items, [])
            |> Enum.map(&build_item/1)

          section(Keyword.put(section_opts, :items, items))
        end)

      sidebar(
        opts
        |> Keyword.put(:id, id)
        |> Keyword.put(:sections, sections)
      )
    end)
  end

  defp build_item(opts) when is_list(opts) do
    children =
      Keyword.get(opts, :children, [])
      |> Enum.map(&build_item/1)

    item(Keyword.put(opts, :children, children))
  end
end
