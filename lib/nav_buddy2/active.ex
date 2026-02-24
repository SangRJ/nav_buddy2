defmodule NavBuddy2.Active do
  @moduledoc """
  Determines whether a navigation item is "active" based on the current path.

  Supports exact matching and prefix matching. Also checks children
  recursively — a parent is active if any of its children are active.
  """

  @doc """
  Returns `true` if the item (or any of its children) matches the current path.
  """
  @spec active?(NavBuddy2.Item.t(), String.t()) :: boolean()
  def active?(%{to: nil, children: []}, _current_path), do: false

  def active?(%{to: nil, children: children}, current_path) do
    Enum.any?(children, &active?(&1, current_path))
  end

  def active?(%{to: to, exact: true}, current_path) do
    normalize(current_path) == normalize(to)
  end

  def active?(%{to: to, children: children}, current_path) do
    normalized_path = normalize(current_path)
    normalized_to = normalize(to)

    normalized_path == normalized_to ||
      String.starts_with?(normalized_path, normalized_to <> "/") ||
      Enum.any?(children, &active?(&1, current_path))
  end

  @doc """
  Returns `true` if any item in the sidebar's sections matches the current path.
  Useful for determining which icon rail entry should be highlighted.
  """
  @spec sidebar_active?(NavBuddy2.Sidebar.t(), String.t()) :: boolean()
  def sidebar_active?(%{sections: sections}, current_path) do
    Enum.any?(sections, fn section ->
      Enum.any?(section.items, &active?(&1, current_path))
    end)
  end

  @doc """
  Finds the currently active item across all sidebars and returns
  `{sidebar_title, item_label}` or `nil` if nothing matches.

  Useful for displaying a page title header.
  """
  @spec find_active_item(list(NavBuddy2.Sidebar.t()), String.t()) ::
          {String.t(), String.t()} | nil
  def find_active_item(sidebars, current_path) when is_list(sidebars) do
    Enum.find_value(sidebars, fn sidebar ->
      Enum.find_value(sidebar.sections, fn section ->
        Enum.find_value(section.items, fn item ->
          find_active_in_item(item, current_path, sidebar.title)
        end)
      end)
    end)
  end

  defp find_active_in_item(item, current_path, sidebar_title) do
    # Check children first for more specific match
    child_match =
      Enum.find_value(item.children, fn child ->
        if active_self?(child, current_path) do
          {sidebar_title, child.label}
        end
      end)

    cond do
      child_match -> child_match
      active_self?(item, current_path) -> {sidebar_title, item.label}
      true -> nil
    end
  end

  # Check if this specific item (not children) matches the path
  defp active_self?(%{to: nil}, _current_path), do: false

  defp active_self?(%{to: to, exact: true}, current_path) do
    normalize(current_path) == normalize(to)
  end

  defp active_self?(%{to: to}, current_path) do
    normalized_path = normalize(current_path)
    normalized_to = normalize(to)

    normalized_path == normalized_to ||
      String.starts_with?(normalized_path, normalized_to <> "/")
  end

  @doc """
  Returns `true` when a sidebar is a "simple link" — i.e. it has exactly
  one section with one item that has a `to` path and no children.
  Returns the item's `to` path, or `nil` otherwise.
  """
  @spec simple_link_path(NavBuddy2.Sidebar.t()) :: String.t() | nil
  def simple_link_path(%{sections: [%{items: [%{to: to, children: []}]}]}) when not is_nil(to),
    do: to

  def simple_link_path(_), do: nil

  # Strip trailing slash for consistent matching
  defp normalize("/"), do: "/"
  defp normalize(path) when is_binary(path), do: String.trim_trailing(path, "/")
  defp normalize(_), do: ""
end
