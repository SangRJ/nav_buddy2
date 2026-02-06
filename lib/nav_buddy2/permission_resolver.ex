defmodule NavBuddy2.PermissionResolver do
  @callback can?(user :: any(), permission :: atom()) :: boolean()
end
