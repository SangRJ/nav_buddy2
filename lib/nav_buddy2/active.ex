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

  # Strip trailing slash for consistent matching
  defp normalize("/"), do: "/"
  defp normalize(path) when is_binary(path), do: String.trim_trailing(path, "/")
  defp normalize(_), do: ""
end
