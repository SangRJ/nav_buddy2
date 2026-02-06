defmodule NavBuddy2.Sidebar do
  @moduledoc """
  Represents a Level 1 navigation group (the icon rail entry).

  Each sidebar maps to one icon in the icon rail and contains
  a list of sections that appear in the detail sidebar.

  ## Fields

    * `:id` – unique identifier (atom or string)
    * `:title` – display title shown in the detail sidebar header
    * `:icon` – icon name (atom) passed to the configured icon renderer
    * `:sections` – list of `NavBuddy2.Section` structs
    * `:position` – `:top` or `:bottom` placement in the icon rail (default `:top`)
    * `:permission` – optional permission atom; if present, the entire sidebar
      is hidden from users who lack this permission

  ## Example

      %NavBuddy2.Sidebar{
        id: :dashboard,
        title: "Dashboard",
        icon: :home,
        sections: [...],
        position: :top,
        permission: :view_dashboard
      }
  """

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          title: String.t(),
          icon: atom(),
          sections: [NavBuddy2.Section.t()],
          position: :top | :bottom,
          permission: atom() | nil
        }

  defstruct [
    :id,
    :title,
    :icon,
    :permission,
    sections: [],
    position: :top
  ]
end
