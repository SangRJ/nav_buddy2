defmodule NavBuddy2Test do
  use ExUnit.Case

  alias NavBuddy2.{Sidebar, Section, Item, Active, Permissions, Resolver}

  # ---------------------------------------------------------------------------
  # Test data helpers
  # ---------------------------------------------------------------------------

  defp sample_item(overrides \\ []) do
    defaults = [label: "Test", icon: :home, to: "/test", children: []]
    struct!(Item, Keyword.merge(defaults, overrides))
  end

  defp sample_section(overrides \\ []) do
    defaults = [title: "Test Section", items: [sample_item()]]
    struct!(Section, Keyword.merge(defaults, overrides))
  end

  defp sample_sidebar(overrides \\ []) do
    defaults = [id: :test, title: "Test", icon: :home, sections: [sample_section()]]
    struct!(Sidebar, Keyword.merge(defaults, overrides))
  end

  # ---------------------------------------------------------------------------
  # Struct tests
  # ---------------------------------------------------------------------------

  describe "NavBuddy2.Sidebar" do
    test "creates with defaults" do
      sidebar = %Sidebar{id: :home, title: "Home", icon: :home}
      assert sidebar.sections == []
      assert sidebar.position == :top
      assert sidebar.permission == nil
    end

    test "supports bottom position" do
      sidebar = %Sidebar{id: :settings, title: "Settings", icon: :cog, position: :bottom}
      assert sidebar.position == :bottom
    end
  end

  describe "NavBuddy2.Section" do
    test "creates with defaults" do
      section = %Section{title: "Main"}
      assert section.items == []
      assert section.permission == nil
    end
  end

  describe "NavBuddy2.Item" do
    test "creates with defaults" do
      item = %Item{label: "Home"}
      assert item.children == []
      assert item.exact == false
      assert item.open_by_default == false
      assert item.badge == nil
      assert item.permission == nil
    end

    test "supports all fields" do
      item = %Item{
        id: :home,
        label: "Home",
        icon: :home,
        to: "/",
        permission: :view_home,
        badge: "3",
        badge_class: "badge-primary",
        exact: true,
        target: "_blank",
        children: [%Item{label: "Child", to: "/child"}]
      }

      assert item.badge == "3"
      assert item.exact == true
      assert length(item.children) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Active detection tests
  # ---------------------------------------------------------------------------

  describe "NavBuddy2.Active" do
    test "exact match" do
      item = sample_item(to: "/dashboard", exact: true)
      assert Active.active?(item, "/dashboard") == true
      assert Active.active?(item, "/dashboard/sub") == false
    end

    test "prefix match (default)" do
      item = sample_item(to: "/projects")
      assert Active.active?(item, "/projects") == true
      assert Active.active?(item, "/projects/123") == true
      assert Active.active?(item, "/projectsxyz") == false
    end

    test "nil path item is not active" do
      item = sample_item(to: nil)
      assert Active.active?(item, "/anything") == false
    end

    test "parent active when child matches" do
      child = sample_item(to: "/tasks/kitchen")
      parent = sample_item(to: nil, children: [child])
      assert Active.active?(parent, "/tasks/kitchen") == true
      assert Active.active?(parent, "/other") == false
    end

    test "trailing slashes are normalized" do
      item = sample_item(to: "/test/")
      assert Active.active?(item, "/test") == true
      assert Active.active?(item, "/test/") == true
    end

    test "sidebar_active? checks all sections" do
      sidebar =
        sample_sidebar(
          sections: [
            %Section{title: "A", items: [sample_item(to: "/page-a")]},
            %Section{title: "B", items: [sample_item(to: "/page-b")]}
          ]
        )

      assert Active.sidebar_active?(sidebar, "/page-a") == true
      assert Active.sidebar_active?(sidebar, "/page-b") == true
      assert Active.sidebar_active?(sidebar, "/page-c") == false
    end
  end

  # ---------------------------------------------------------------------------
  # Permission tests
  # ---------------------------------------------------------------------------

  describe "NavBuddy2.Permissions" do
    setup do
      # Clear any configured resolver
      Application.delete_env(:nav_buddy2, :permission_resolver)
      :ok
    end

    test "nil permission always renders" do
      item = sample_item(permission: nil)
      assert Permissions.can_render?(item, nil) == true
      assert Permissions.can_render?(item, %{}) == true
    end

    test "with permission but no resolver configured, renders by default" do
      item = sample_item(permission: :admin)
      assert Permissions.can_render?(item, %{}) == true
    end

    test "with permission but nil user, does not render" do
      item = sample_item(permission: :admin)
      assert Permissions.can_render?(item, nil) == false
    end
  end

  # ---------------------------------------------------------------------------
  # Resolver tests
  # ---------------------------------------------------------------------------

  describe "NavBuddy2.Resolver" do
    setup do
      Application.delete_env(:nav_buddy2, :permission_resolver)
      :ok
    end

    test "filter preserves visible items" do
      sidebars = [sample_sidebar()]
      result = Resolver.filter(sidebars, %{})
      assert length(result) == 1
      assert hd(result).id == :test
    end

    test "filter removes empty sidebars" do
      sidebar = sample_sidebar(sections: [])
      result = Resolver.filter([sidebar], %{})
      assert result == []
    end

    test "filter_sidebar preserves structure" do
      sidebar = sample_sidebar()
      result = Resolver.filter_sidebar(sidebar, %{})
      assert result.id == :test
      assert length(result.sections) == 1
    end

    test "flatten produces searchable entries" do
      child = sample_item(label: "Child", to: "/test/child")
      item = sample_item(label: "Parent", to: "/test", children: [child])
      section = sample_section(items: [item])
      sidebar = sample_sidebar(title: "My Sidebar", sections: [section])

      entries = Resolver.flatten([sidebar])
      assert length(entries) == 2

      parent_entry = Enum.find(entries, &(&1.label == "Parent"))
      assert parent_entry.to == "/test"
      assert parent_entry.sidebar == "My Sidebar"

      child_entry = Enum.find(entries, &(&1.label == "Child"))
      assert child_entry.to == "/test/child"
    end

    test "flatten skips items without paths" do
      item = sample_item(to: nil, children: [])
      section = sample_section(items: [item])
      sidebar = sample_sidebar(sections: [section])

      entries = Resolver.flatten([sidebar])
      assert entries == []
    end
  end

  # ---------------------------------------------------------------------------
  # Builder DSL tests
  # ---------------------------------------------------------------------------

  describe "NavBuddy2.build/1" do
    test "builds navigation from keyword list" do
      result =
        NavBuddy2.build(
          home: [
            title: "Home",
            icon: :home,
            sections: [
              [
                title: "Main",
                items: [
                  [label: "Dashboard", icon: :squares, to: "/"]
                ]
              ]
            ]
          ]
        )

      assert length(result) == 1
      sidebar = hd(result)
      assert sidebar.id == :home
      assert sidebar.title == "Home"
      assert length(sidebar.sections) == 1
      assert hd(sidebar.sections).title == "Main"
      assert length(hd(sidebar.sections).items) == 1
    end

    test "builds nested children" do
      result =
        NavBuddy2.build(
          tasks: [
            title: "Tasks",
            icon: :check,
            sections: [
              [
                title: "Work",
                items: [
                  [
                    label: "Projects",
                    icon: :folder,
                    children: [
                      [label: "Project A", to: "/projects/a"],
                      [label: "Project B", to: "/projects/b"]
                    ]
                  ]
                ]
              ]
            ]
          ]
        )

      item = hd(hd(hd(result).sections).items)
      assert item.label == "Projects"
      assert length(item.children) == 2
      assert hd(item.children).label == "Project A"
    end
  end

  # ---------------------------------------------------------------------------
  # Convenience function tests
  # ---------------------------------------------------------------------------

  describe "convenience functions" do
    test "sidebar/1" do
      s = NavBuddy2.sidebar(id: :test, title: "Test", icon: :home)
      assert %Sidebar{} = s
      assert s.id == :test
    end

    test "section/1" do
      s = NavBuddy2.section(title: "Test")
      assert %Section{} = s
      assert s.title == "Test"
    end

    test "item/1" do
      i = NavBuddy2.item(label: "Test", to: "/test")
      assert %Item{} = i
      assert i.label == "Test"
    end
  end
end
