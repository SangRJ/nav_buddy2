defmodule NavBuddy2.Permissions do
  @moduledoc """
  Permission checking utilities.

  Delegates to the configured `NavBuddy2.PermissionResolver` implementation
  to decide whether a navigation element should be rendered for a user.
  """

  @doc """
  Returns `true` if the element should be rendered for the user.

  Elements without a `:permission` field (or with `permission: nil`)
  are always rendered.
  """
  @spec can_render?(map(), any()) :: boolean()
  def can_render?(%{permission: nil}, _user), do: true
  def can_render?(%{permission: permission}, nil) when not is_nil(permission), do: false

  def can_render?(%{permission: permission}, user) do
    resolver = Application.get_env(:nav_buddy2, :permission_resolver)

    cond do
      is_nil(resolver) ->
        true

      Code.ensure_loaded?(resolver) && function_exported?(resolver, :can?, 2) ->
        resolver.can?(user, permission)

      true ->
        raise """
        nav_buddy2 permission resolver #{inspect(resolver)} must implement:

            @behaviour NavBuddy2.PermissionResolver

            def can?(user, permission), do: ...
        """
    end
  end
end
