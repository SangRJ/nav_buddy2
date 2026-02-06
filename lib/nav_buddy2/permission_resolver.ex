defmodule NavBuddy2.PermissionResolver do
  @moduledoc """
  Behaviour for permission resolution.

  Implement this behaviour in your application to control which
  navigation items are visible to each user.

  ## Example

      defmodule MyApp.NavPermissions do
        @behaviour NavBuddy2.PermissionResolver

        @impl true
        def can?(user, permission) do
          permission in user.permissions
        end
      end

  Then configure it:

      config :nav_buddy2, permission_resolver: MyApp.NavPermissions
  """

  @doc """
  Returns `true` if the given user has the given permission.

  The `user` argument is whatever your app passes as `current_user`
  to the nav component — nav_buddy2 never inspects it.
  """
  @callback can?(user :: any(), permission :: atom()) :: boolean()
end
