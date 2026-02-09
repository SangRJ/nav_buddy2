/**
 * NavBuddy2 Alpine.js Plugin
 *
 * Provides:
 *   - Layout persistence (sidebar / horizontal) via localStorage
 *   - Sidebar collapsed state persistence
 *   - Client-side active navigation tracking (no re-renders)
 *   - Alpine x-collapse directive (if not already registered)
 *   - Custom event helpers
 *
 * Usage:
 *   import NavBuddy2 from "nav_buddy2/assets/nav_buddy2"
 *   Alpine.plugin(NavBuddy2)
 *
 * Or load via CDN/script tag and it auto-registers.
 */

const NAV_BUDDY2_STORAGE_KEY = "nav_buddy2_preferences";

// Soft spring easing for smooth animations
const SOFT_SPRING_EASING = "cubic-bezier(0.25, 1.1, 0.4, 1)";

function getPreferences() {
  try {
    const raw = localStorage.getItem(NAV_BUDDY2_STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function setPreference(key, value) {
  try {
    const prefs = getPreferences();
    prefs[key] = value;
    localStorage.setItem(NAV_BUDDY2_STORAGE_KEY, JSON.stringify(prefs));
  } catch {
    // localStorage not available — silent fail
  }
}

/**
 * Normalize path for comparison (remove trailing slashes)
 */
function normalizePath(path) {
  if (!path) return "/";
  return path.replace(/\/+$/, "") || "/";
}

/**
 * Check if a path is active (exact or prefix match)
 */
function isPathActive(itemPath, currentPath, exact = false) {
  const normalized = normalizePath(currentPath);
  const itemNormalized = normalizePath(itemPath);
  
  if (exact) {
    return normalized === itemNormalized;
  }
  
  // Prefix match: /projects matches /projects/123
  if (normalized === itemNormalized) return true;
  return normalized.startsWith(itemNormalized + "/");
}

/**
 * Alpine.js plugin
 */
export default function NavBuddy2Plugin(Alpine) {
  // ---------------------------------------------------------------------------
  // Navigation store – tracks current path client-side (no re-renders!)
  // ---------------------------------------------------------------------------
  Alpine.store("nav", {
    currentPath: window.location.pathname,
    activeSidebarId: null,
    
    /**
     * Check if a path is active
     * @param {string} path - The path to check
     * @param {boolean} exact - If true, require exact match
     */
    isActive(path, exact = false) {
      return isPathActive(path, this.currentPath, exact);
    },
    
    /**
     * Check if any child path is active (for parent items)
     * @param {string[]} childPaths - Array of child paths
     */
    isChildActive(childPaths) {
      return childPaths.some(path => this.isActive(path));
    }
  });

  // ---------------------------------------------------------------------------
  // Watch for LiveView navigation and update current path
  // ---------------------------------------------------------------------------
  document.addEventListener("phx:page-loading-stop", () => {
    Alpine.store("nav").currentPath = window.location.pathname;
  });

  // Also handle popstate for browser back/forward
  window.addEventListener("popstate", () => {
    Alpine.store("nav").currentPath = window.location.pathname;
  });

  // ---------------------------------------------------------------------------
  // $navBuddy2 magic – access persisted preferences anywhere
  // ---------------------------------------------------------------------------
  Alpine.magic("navBuddy2", () => ({
    get layout() {
      return getPreferences().layout || "sidebar";
    },
    set layout(val) {
      setPreference("layout", val);
    },
    get sidebarCollapsed() {
      return getPreferences().sidebarCollapsed || false;
    },
    set sidebarCollapsed(val) {
      setPreference("sidebarCollapsed", val);
    },
    // Expose easing for use in inline styles
    easing: SOFT_SPRING_EASING,
  }));

  // ---------------------------------------------------------------------------
  // x-nav-persist directive – auto-persist a value to localStorage
  // Usage: <div x-data="{ layout: 'sidebar' }" x-nav-persist="layout">
  // ---------------------------------------------------------------------------
  Alpine.directive("nav-persist", (el, { expression }, { effect, evaluateLater, evaluate }) => {
    const getValue = evaluateLater(expression);

    // Restore from storage on init
    const prefs = getPreferences();
    if (prefs[expression] !== undefined) {
      evaluate(`${expression} = '${prefs[expression]}'`);
    }

    // Watch for changes and persist
    effect(() => {
      getValue((value) => {
        setPreference(expression, value);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // x-collapse directive (borrowed from @alpinejs/collapse if not present)
  // Provides smooth accordion expand/collapse behavior with soft spring easing
  // ---------------------------------------------------------------------------
  if (!Alpine.directive("collapse")) {
    Alpine.directive("collapse", (el, { modifiers }, { cleanup }) => {
      const duration = modifiers.includes("duration")
        ? modifiers[modifiers.indexOf("duration") + 1] || "300"
        : "300";

      // Set initial styles with soft spring easing
      el.style.overflow = "hidden";
      el.style.transition = `height ${duration}ms ${SOFT_SPRING_EASING}`;

      const setHeight = () => {
        el.style.height = el.scrollHeight + "px";
      };

      const collapse = () => {
        el.style.height = el.scrollHeight + "px";
        // Force reflow
        el.offsetHeight; // eslint-disable-line no-unused-expressions
        el.style.height = "0px";
      };

      const expand = () => {
        el.style.height = "0px";
        // Force reflow
        el.offsetHeight; // eslint-disable-line no-unused-expressions
        setHeight();
      };

      // Observe x-show changes via MutationObserver
      const observer = new MutationObserver((mutations) => {
        for (const mutation of mutations) {
          if (mutation.attributeName === "style") {
            const isHidden = el.style.display === "none";
            if (!isHidden && el.style.height === "0px") {
              expand();
            }
          }
        }
      });

      observer.observe(el, { attributes: true, attributeFilter: ["style"] });

      cleanup(() => observer.disconnect());
    });
  }
}

/**
 * LiveView hook for nav_buddy2 events.
 *
 * Attach to the root nav element to handle phx events
 * for layout switching and sidebar toggling.
 *
 * Usage in your app.js:
 *   import { NavBuddy2Hook } from "nav_buddy2/assets/nav_buddy2"
 *   let liveSocket = new LiveSocket("/live", Socket, {
 *     hooks: { NavBuddy2: NavBuddy2Hook }
 *   })
 */
export const NavBuddy2Hook = {
  mounted() {
    // Listen for layout preference changes from Alpine
    this.el.addEventListener("nav-buddy2:layout-changed", (e) => {
      this.pushEvent("nav_buddy2:layout_changed", {
        layout: e.detail.layout,
      });
    });

    // Listen for sidebar collapsed state changes
    this.el.addEventListener("nav-buddy2:sidebar-collapsed", (e) => {
      setPreference("sidebarCollapsed", e.detail.collapsed);
    });
  },
};

// Export utilities for external use
export { SOFT_SPRING_EASING, isPathActive, normalizePath };
