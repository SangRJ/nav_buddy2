defmodule NavBuddy2.Section do
  @moduledoc """
  Represents a Level 2 navigation group within a sidebar.

  Sections group related navigation items under an optional heading.

  ## Fields

    * `:title` – section heading displayed above the items (optional)
    * `:items` – list of `NavBuddy2.Item` structs
    * `:permission` – optional permission atom

  ## Example

      %NavBuddy2.Section{
        title: "Quick Actions",
        items: [...]
      }
  """

  @type t :: %__MODULE__{
          title: String.t() | nil,
          items: [NavBuddy2.Item.t()],
          permission: atom() | nil
        }

  defstruct [
    :title,
    :permission,
    items: []
  ]
end
