defmodule NavBuddy2.Resolver do
  @moduledoc """
  Filters the navigation tree based on user permissions.

  Walks the entire tree (sidebars → sections → items → children)
  and removes any element the user is not permitted to see.
  Empty sections and sidebars are pruned automatically.
  """

  alias NavBuddy2.Permissions

  @doc """
  Filters a list of sidebars, removing anything the user cannot see.
  """
  @spec filter(list(NavBuddy2.Sidebar.t()), any()) :: list(NavBuddy2.Sidebar.t())
  def filter(sidebars, user) when is_list(sidebars) do
    sidebars
    |> Enum.filter(&Permissions.can_render?(&1, user))
    |> Enum.map(&filter_sidebar(&1, user))
    |> Enum.reject(&(&1.sections == []))
  end

  @doc """
  Filters a single sidebar's sections and items.
  """
  @spec filter_sidebar(NavBuddy2.Sidebar.t(), any()) :: NavBuddy2.Sidebar.t()
  def filter_sidebar(sidebar, user) do
    %{
      sidebar
      | sections:
          sidebar.sections
          |> Enum.filter(&Permissions.can_render?(&1, user))
          |> Enum.map(&filter_section(&1, user))
          |> Enum.reject(&(&1.items == []))
    }
  end

  defp filter_section(section, user) do
    %{
      section
      | items:
          section.items
          |> Enum.filter(&Permissions.can_render?(&1, user))
          |> Enum.map(&filter_item(&1, user))
    }
  end

  defp filter_item(item, user) do
    %{
      item
      | children:
          item.children
          |> Enum.filter(&Permissions.can_render?(&1, user))
          |> Enum.map(&filter_item(&1, user))
    }
  end

  @doc """
  Flattens the entire navigation tree into a searchable list of items.
  Useful for the command palette.
  """
  @spec flatten(list(NavBuddy2.Sidebar.t())) :: list(map())
  def flatten(sidebars) do
    for sidebar <- sidebars,
        section <- sidebar.sections,
        item <- section.items,
        entry <- flatten_item(item, sidebar.title, section.title) do
      entry
    end
  end

  defp flatten_item(item, sidebar_title, section_title) do
    parent_entry =
      if item.to do
        [
          %{
            label: item.label,
            to: item.to,
            icon: item.icon,
            sidebar: sidebar_title,
            section: section_title,
            breadcrumb: "#{sidebar_title} > #{section_title} > #{item.label}"
          }
        ]
      else
        []
      end

    child_entries =
      Enum.flat_map(item.children, fn child ->
        [
          %{
            label: child.label,
            to: child.to,
            icon: child.icon || item.icon,
            sidebar: sidebar_title,
            section: section_title,
            parent: item.label,
            breadcrumb: "#{sidebar_title} > #{item.label} > #{child.label}"
          }
        ]
      end)

    parent_entry ++ child_entries
  end
end
