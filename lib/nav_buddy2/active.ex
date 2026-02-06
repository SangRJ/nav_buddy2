defmodule NavBuddy2.Active do
  def active?(item, current_path) do
    cond do
      is_nil(item.to) ->
        false

      item.exact ->
        current_path == item.to

      true ->
        String.starts_with?(current_path, item.to)
    end
  end
end
