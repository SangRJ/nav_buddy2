defmodule NavBuddy2.Resolver do
  alias NavBuddy2.Permissions

  def filter_sidebar(sidebar, user) do
    %{
      sidebar
      | sections:
          sidebar.sections
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
          |> Enum.reject(&(&1.children == [] && &1.to == nil))
    }
  end

  defp filter_item(item, user) do
    %{item | children: Enum.filter(item.children, &Permissions.can_render?(&1, user))}
  end
end
