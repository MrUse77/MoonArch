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

// Selene covers the bar, launcher, notification daemon, widget host and session
// menu that the desktop used to compose from four separate tools. Every one of
// them has had its configuration removed, so none may be offered again.
func TestDefaultCategories_QuickshellReplacesRetiredTools(t *testing.T) {
	categories := menu.DefaultCategories()

	offered := make(map[string]bool)
	for _, category := range categories {
		for _, pkg := range category.Packages {
			offered[pkg.Name] = true
		}
	}

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

	if !offered["aur/quickshell-git"] {
		t.Fatal("aur/quickshell-git is missing from the default categories")
	}
	for _, pkg := range categories[hyprland].Packages {
		if pkg.Name == "aur/quickshell-git" && !pkg.Selected {
			t.Error("aur/quickshell-git must be selected by default")
		}
	}

	for _, retired := range []string{"aur/waybar-git", "rofi", "dunst", "aur/eww", "aur/wlogout"} {
		if offered[retired] {
			t.Errorf("%s must not be offered: Selene replaces it and its configuration was removed", retired)
		}
	}
}
