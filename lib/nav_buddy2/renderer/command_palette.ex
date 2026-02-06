defmodule NavBuddy2.Renderer.CommandPalette do
  @moduledoc """
  Renders a command palette (⌘K / Ctrl+K) overlay.

  Flattens the entire navigation tree into a searchable list,
  providing keyboard-navigable quick access to any route.

  Features:
    - Fuzzy search across all navigation items
    - Keyboard navigation (↑↓ arrows, Enter, Escape)
    - Breadcrumb display showing sidebar > section > item
    - Alpine.js powered — no server roundtrips for UI filtering
  """

  use Phoenix.Component

  alias NavBuddy2.{Resolver, Icon}

  attr(:sidebars, :list, required: true, doc: "Full list of NavBuddy2.Sidebar structs")
  attr(:current_user, :any, required: true, doc: "Current user for permission filtering")
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  def render(assigns) do
    entries =
      assigns.sidebars
      |> Resolver.filter(assigns.current_user)
      |> Resolver.flatten()
      |> Enum.filter(& &1.to)

    assigns = assign(assigns, :entries, entries)

    ~H"""
    <div
      x-data={command_palette_data(@entries)}
      x-on:nav-buddy2:open-command-palette.window="openPalette()"
      x-on:keydown.meta.k.window.prevent="togglePalette()"
      x-on:keydown.ctrl.k.window.prevent="togglePalette()"
      x-on:keydown.escape.window="closePalette()"
    >
      <%!-- Backdrop --%>
      <div
        x-show="open"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        class="fixed inset-0 z-50 bg-black/60 flex items-start justify-center pt-[15vh]"
        x-on:click.self="closePalette()"
        style="display: none;"
      >
        <%!-- Palette container --%>
        <div
          x-show="open"
          x-transition:enter="transition ease-out duration-200"
          x-transition:enter-start="opacity-0 scale-95 -translate-y-4"
          x-transition:enter-end="opacity-100 scale-100 translate-y-0"
          x-transition:leave="transition ease-in duration-150"
          x-transition:leave-start="opacity-100 scale-100"
          x-transition:leave-end="opacity-0 scale-95 -translate-y-4"
          class={[
            "w-full max-w-lg bg-base-100 rounded-2xl shadow-2xl border border-base-300 overflow-hidden",
            @class
          ]}
          x-on:click.outside="closePalette()"
        >
          <%!-- Search input --%>
          <div class="flex items-center gap-3 px-4 py-3 border-b border-base-300">
            <Icon.icon name={:search} class="w-5 h-5 text-base-content/50 shrink-0" />
            <input
              type="text"
              placeholder="Search navigation..."
              class="flex-1 bg-transparent border-none outline-none text-base text-base-content placeholder:text-base-content/40"
              x-model="query"
              x-ref="searchInput"
              x-on:input="filterEntries()"
              x-on:keydown.arrow-down.prevent="moveDown()"
              x-on:keydown.arrow-up.prevent="moveUp()"
              x-on:keydown.enter.prevent="go()"
            />
            <kbd class="kbd kbd-sm text-base-content/40">ESC</kbd>
          </div>

          <%!-- Results --%>
          <div class="max-h-80 overflow-y-auto p-2" x-ref="resultsList">
            <template x-if="filtered.length === 0">
              <div class="px-4 py-8 text-center text-base-content/50 text-sm">
                No results found
              </div>
            </template>

            <template x-for="(entry, index) in filtered" x-bind:key="index">
              <a
                x-bind:href="entry.to"
                class="flex items-center gap-3 px-3 py-2.5 rounded-lg cursor-pointer transition-colors text-sm group"
                x-bind:class="index === selectedIndex ? 'bg-primary text-primary-content' : 'hover:bg-base-200 text-base-content'"
                x-on:mouseenter="selectedIndex = index"
                x-on:click.prevent="goTo(entry.to)"
                data-phx-link="redirect"
                data-phx-link-state="push"
              >
                <span
                  class="w-5 h-5 shrink-0 flex items-center justify-center"
                  x-bind:class="index === selectedIndex ? 'text-primary-content' : 'text-base-content/60'"
                >
                  <Icon.icon name={:arrow_right} class="w-4 h-4" />
                </span>
                <div class="flex-1 min-w-0">
                  <div class="font-medium truncate" x-text="entry.label"></div>
                  <div
                    class="text-xs truncate mt-0.5"
                    x-bind:class="index === selectedIndex ? 'text-primary-content/70' : 'text-base-content/40'"
                    x-text="entry.breadcrumb"
                  ></div>
                </div>
              </a>
            </template>
          </div>

          <%!-- Footer --%>
          <div class="flex items-center justify-between px-4 py-2 border-t border-base-300 text-xs text-base-content/40">
            <div class="flex items-center gap-2">
              <kbd class="kbd kbd-xs">↑↓</kbd>
              <span>Navigate</span>
            </div>
            <div class="flex items-center gap-2">
              <kbd class="kbd kbd-xs">↵</kbd>
              <span>Open</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp command_palette_data(entries) do
    serialized =
      entries
      |> Enum.map(fn entry ->
        %{
          label: entry.label,
          to: entry.to,
          breadcrumb: entry.breadcrumb,
          searchable: String.downcase("#{entry.label} #{entry.breadcrumb}")
        }
      end)
      |> inspect_json()

    """
    {
      open: false,
      query: '',
      selectedIndex: 0,
      entries: #{serialized},
      filtered: #{serialized},
      openPalette() {
        this.open = true;
        this.query = '';
        this.selectedIndex = 0;
        this.filtered = this.entries;
        this.$nextTick(() => this.$refs.searchInput?.focus());
      },
      closePalette() {
        this.open = false;
        this.query = '';
      },
      togglePalette() {
        this.open ? this.closePalette() : this.openPalette();
      },
      filterEntries() {
        const q = this.query.toLowerCase();
        this.filtered = q === '' ? this.entries : this.entries.filter(e => e.searchable.includes(q));
        this.selectedIndex = 0;
      },
      moveDown() {
        if (this.selectedIndex < this.filtered.length - 1) this.selectedIndex++;
        this.scrollToSelected();
      },
      moveUp() {
        if (this.selectedIndex > 0) this.selectedIndex--;
        this.scrollToSelected();
      },
      scrollToSelected() {
        this.$nextTick(() => {
          const list = this.$refs.resultsList;
          const item = list?.children[this.selectedIndex + 1];
          if (item) item.scrollIntoView({ block: 'nearest' });
        });
      },
      go() {
        const entry = this.filtered[this.selectedIndex];
        if (entry) this.goTo(entry.to);
      },
      goTo(path) {
        this.closePalette();
        if (window.liveSocket) {
          window.liveSocket.pushHistoryPatch(path, 'push', null);
        } else {
          window.location.href = path;
        }
      }
    }
    """
  end

  # Simple JSON-like serialization for Alpine inline data.
  # We avoid a JSON library dependency by building the string manually.
  defp inspect_json(entries) do
    items =
      Enum.map(entries, fn entry ->
        """
        {label:#{escape_js(entry.label)},to:#{escape_js(entry.to)},breadcrumb:#{escape_js(entry.breadcrumb)},searchable:#{escape_js(entry.searchable)}}
        """
        |> String.trim()
      end)
      |> Enum.join(",")

    "[#{items}]"
  end

  defp escape_js(nil), do: "''"

  defp escape_js(val) when is_binary(val) do
    escaped =
      val
      |> String.replace("\\", "\\\\")
      |> String.replace("'", "\\'")
      |> String.replace("\n", "\\n")

    "'#{escaped}'"
  end
end
