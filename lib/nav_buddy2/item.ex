defmodule NavBuddy2.Item do
  @moduledoc """
  Represents a Level 3 navigation item or child link.

  Items are the actual navigable entries. They can optionally
  contain children to create expandable/collapsible sub-menus.

  ## Fields

    * `:id` – unique identifier (atom or string, optional – auto-generated if nil)
    * `:label` – display text
    * `:icon` – icon name atom (optional for children)
    * `:to` – navigation path (nil for non-navigable group headings)
    * `:permission` – optional permission atom
    * `:badge` – badge text or count (rendered as daisyUI badge)
    * `:badge_class` – CSS class for the badge (e.g. "badge-primary")
    * `:exact` – when true, only mark active on exact path match
    * `:children` – nested list of `NavBuddy2.Item` for sub-menus
    * `:target` – link target attribute (e.g. "_blank")
    * `:method` – HTTP method for non-GET actions (e.g. :delete)
    * `:open_by_default` – start with children expanded

  ## Example

      %NavBuddy2.Item{
        id: :kitchen,
        label: "Kitchen",
        icon: :check_circle,
        children: [
          %NavBuddy2.Item{label: "Wash dishes", to: "/tasks/kitchen/wash"},
          %NavBuddy2.Item{label: "Clean sink", to: "/tasks/kitchen/sink"}
        ]
      }
  """

  @type t :: %__MODULE__{
          id: atom() | String.t() | nil,
          label: String.t(),
          icon: atom() | nil,
          to: String.t() | nil,
          permission: atom() | nil,
          badge: String.t() | integer() | nil,
          badge_class: String.t() | nil,
          exact: boolean(),
          children: [t()],
          target: String.t() | nil,
          method: atom() | nil,
          open_by_default: boolean()
        }

  defstruct [
    :id,
    :label,
    :icon,
    :to,
    :permission,
    :badge,
    :badge_class,
    :target,
    :method,
    exact: false,
    children: [],
    open_by_default: false
  ]
end
