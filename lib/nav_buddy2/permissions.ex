defmodule NavBuddy2.Permissions do
  def can_render?(%{permission: nil}, _user), do: true

  def can_render?(%{permission: permission}, user) do
    resolver =
      Application.get_env(:nav_buddy2, :permission_resolver)

    cond do
      is_nil(resolver) ->
        true

      function_exported?(resolver, :can?, 2) ->
        resolver.can?(user, permission)

      true ->
        raise """
        nav_buddy2 permission resolver must implement:

            can?(user, permission)
        """
    end
  end
end
