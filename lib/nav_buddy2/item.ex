defmodule NavBuddy2.Item do
  defstruct [
    :id,
    :label,
    :icon,
    :to,
    :permission,
    :badge,
    :exact,
    children: []
  ]
end
