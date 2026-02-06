# NavBuddy2

[![Hex.pm](https://img.shields.io/hexpm/v/nav_buddy2.svg)](https://hex.pm/packages/nav_buddy2)

**Permission-aware, multi-layout navigation engine for Phoenix LiveView.**

One navigation tree → multiple renderers → full daisyUI theming → Alpine.js animations.

## Features

- **Two-level sidebar** – icon rail + collapsible detail panel (like the React reference)
- **Horizontal navbar** – top navigation bar with dropdown menus
- **Mobile drawer** – slide-out navigation for small screens
- **Command palette** – ⌘K / Ctrl+K searchable overlay
- **Permission-aware** – items hidden from unauthorized users
- **3-level depth** – Sidebar → Section → Item (with optional children)
- **Layout persistence** – users pick sidebar or horizontal (persisted like dark mode)
- **daisyUI themed** – inherits your theme automatically
- **Alpine.js powered** – smooth transitions, no full-page reloads
- **LiveView-native** – uses `phx-click`, `navigate`, and Alpine for UI state

## Installation

Add to `mix.exs`:

```elixir
def deps do
  [
    {:nav_buddy2, "~> 0.2.0"}
  ]
end
```

## Quick Setup

### 1. Configure icon renderer

```elixir
# config/config.exs
config :nav_buddy2,
  icon_renderer: &MyAppWeb.NavIcon.render/1
```

Example renderer for Heroicons (default in Phoenix 1.7+):

```elixir
defmodule MyAppWeb.NavIcon do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <.icon name={"hero-#{@name}"} class={@class} />
    """
  end
end
```

### 2. Define your navigation

```elixir
defmodule MyAppWeb.Navigation do
  alias NavBuddy2.{Sidebar, Section, Item}

  def sidebars do
    [
      %Sidebar{
        id: :home,
        title: "Home",
        icon: :home,
        position: :top,
        sections: [
          %Section{
            title: "Overview",
            items: [
              %Item{label: "Dashboard", icon: :squares_2x2, to: "/", exact: true},
              %Item{
                label: "Projects",
                icon: :folder,
                children: [
                  %Item{label: "Active", to: "/projects/active"},
                  %Item{label: "Archived", to: "/projects/archived"}
                ]
              }
            ]
          }
        ]
      },
      %Sidebar{
        id: :settings,
        title: "Settings",
        icon: :cog_6_tooth,
        position: :bottom,
        permission: :admin,
        sections: [
          %Section{
            title: "Account",
            items: [
              %Item{label: "Profile", icon: :user, to: "/settings/profile"},
              %Item{label: "Security", icon: :shield_check, to: "/settings/security"}
            ]
          }
        ]
      }
    ]
  end
end
```

Or use the DSL builder:

```elixir
NavBuddy2.build(
  home: [
    title: "Home",
    icon: :home,
    sections: [
      [title: "Overview", items: [
        [label: "Dashboard", icon: :squares_2x2, to: "/", exact: true]
      ]]
    ]
  ]
)
```

### 3. Add to your layout

```heex
<NavBuddy2.Nav.nav
  sidebars={MyAppWeb.Navigation.sidebars()}
  current_user={@current_user}
  current_path={@current_path}
>
  <main class="flex-1 p-6">
    <%= @inner_content %>
  </main>
</NavBuddy2.Nav.nav>
```

### 4. Handle events in your LiveView

```elixir
def handle_event("nav_buddy2:switch_sidebar", %{"id" => id}, socket) do
  {:noreply, assign(socket, :active_sidebar_id, String.to_existing_atom(id))}
end
```

### 5. JavaScript setup

Install Alpine.js and the persist plugin:

```bash
npm install alpinejs @alpinejs/persist @alpinejs/collapse
```

In your `app.js`:

```javascript
import Alpine from "alpinejs"
import persist from "@alpinejs/persist"
import collapse from "@alpinejs/collapse"
import NavBuddy2Plugin from "nav_buddy2/assets/nav_buddy2"

Alpine.plugin(persist)
Alpine.plugin(collapse)
Alpine.plugin(NavBuddy2Plugin)

window.Alpine = Alpine
Alpine.start()
```

## Permissions

Implement the `NavBuddy2.PermissionResolver` behaviour:

```elixir
defmodule MyApp.NavPermissions do
  @behaviour NavBuddy2.PermissionResolver

  @impl true
  def can?(user, permission) do
    permission in user.permissions
  end
end
```

Configure it:

```elixir
config :nav_buddy2, permission_resolver: MyApp.NavPermissions
```

Items, sections, and sidebars with a `:permission` field will be hidden from users who lack that permission. If no resolver is configured, everything is visible.

## Layout Switching

Users can switch between sidebar and horizontal layouts at runtime. The preference is persisted in localStorage (like dark/light mode). A small floating toggle appears in the bottom-right corner.

Available layouts:
- `"sidebar"` – Two-level sidebar (icon rail + detail)
- `"horizontal"` – Top navigation bar
- `"auto"` – Sidebar on desktop, horizontal + drawer on mobile

## Component Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `sidebars` | list | required | List of `NavBuddy2.Sidebar` structs |
| `current_user` | any | required | User struct for permission checks |
| `current_path` | string | required | Current route path |
| `layout` | string | `"sidebar"` | Default layout mode |
| `collapsed` | boolean | `false` | Initial sidebar collapsed state |
| `active_sidebar_id` | any | first id | Currently active sidebar |
| `searchable` | boolean | `true` | Show search input |
| `command_palette` | boolean | `true` | Enable ⌘K palette |
| `class` | string | `""` | Root container classes |
| `sidebar_class` | string | `""` | Sidebar panel classes |
| `rail_class` | string | `""` | Icon rail classes |
| `horizontal_class` | string | `""` | Horizontal nav classes |
| `logo` | any | nil | Custom logo content |

## Architecture

```
Navigation Definition (structs)
        ↓
Permission Resolver (filter tree)
        ↓
Layout Router (sidebar | horizontal | auto)
        ↓
Renderer Layer (IconRail, Sidebar, Horizontal, MobileDrawer, CommandPalette)
        ↓
Client UI (Alpine.js + daisyUI + LiveView)
```

## Compared to NavBuddy v1

| Feature | v1 | v2 |
|---------|----|----|
| daisyUI support | ❌ | ✅ |
| Multiple layouts | ❌ | ✅ sidebar, horizontal, auto |
| Layout persistence | ❌ | ✅ localStorage |
| Command palette | ❌ | ✅ ⌘K |
| Mobile drawer | ❌ | ✅ |
| 3-level depth | ❌ | ✅ |
| Permission support | Basic | ✅ Full (sidebar, section, item) |
| Alpine.js animations | ❌ | ✅ |
| Search | ❌ | ✅ |
| Badges | ❌ | ✅ |

## License

MIT
