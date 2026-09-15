package installer

import (
	"slices"
	"testing"

	"github.com/MrUse77/dots-cli/pkg/installer/plan"
	"github.com/MrUse77/dots-cli/pkg/installer/ui/menu"
)

// The TUI menu names the packages that collectPackages resolves inside a group.
// Exclusion matches names verbatim, so a menu entry that does not appear exactly
// in its group's package list can never be deselected.
func TestDefaultCategories_PackageNamesMatchCatalogGroups(t *testing.T) {
	for _, category := range menu.DefaultCategories() {
		// Hyprland plugins install through hyprpm, not through the package catalog.
		if category.Key == plan.GroupPlugins {
			continue
		}

		installed := collectPackages(plan.Options{Groups: []string{category.Key}})
		for _, pkg := range category.Packages {
			if !slices.Contains(installed, pkg.Name) {
				t.Errorf("menu package %q of group %q is absent from the catalog package list; deselecting it would still install nothing", pkg.Name, category.Key)
			}
		}
	}
}

// Selene owns the freedesktop notifications bus at runtime, so the legacy
// launcher and notification daemon stay installed-but-dormant instead of absent:
// the documented rollback turns rofi and dunst back on without a package install.
// Waybar is fully retired with Selene and is no longer a fallback. The Quickshell
// shell leads the category it now defaults to.
func TestDefaultCategories_QuickshellLeadsDormantFallbacks(t *testing.T) {
	categories := menu.DefaultCategories()

	hyprland := -1
	for i := range categories {
		if categories[i].Key == plan.GroupHyprland {
			hyprland = i
			break
		}
	}
	if hyprland < 0 {
		t.Fatalf("no %q category in the default categories", plan.GroupHyprland)
	}

	packages := categories[hyprland].Packages
	index := make(map[string]int, len(packages))
	for i, pkg := range packages {
		index[pkg.Name] = i
	}

	shell, ok := index["aur/quickshell-git"]
	if !ok {
		t.Fatal("aur/quickshell-git is missing from the Hyprland category")
	}
	if !packages[shell].Selected {
		t.Error("aur/quickshell-git must be selected by default")
	}

	for _, fallback := range []string{"rofi", "dunst"} {
		i, ok := index[fallback]
		if !ok {
			t.Errorf("%s is missing from the Hyprland category", fallback)
			continue
		}
		if shell > i {
			t.Errorf("aur/quickshell-git must be listed before %s, got indexes %d and %d", fallback, shell, i)
		}
		if !packages[i].Selected {
			t.Errorf("%s must stay pre-selected as a dormant fallback; the documented rollback expects it installed", fallback)
		}
	}
}
