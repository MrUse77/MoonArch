package installer

import (
	"testing"

	"github.com/MrUse77/dots-cli/pkg/installer/plan"
)

func TestActionCatalogGSettingsAreExternalInStableOrder(t *testing.T) {
	actions, err := NewActionCatalog().ExternalActions(t.TempDir(), t.TempDir(), plan.Options{})
	if err != nil {
		t.Fatal(err)
	}
	seen := 0
	for _, action := range actions {
		if action.Command.Name != "gsettings" {
			continue
		}
		seen++
		if action.Classification != "external" {
			t.Errorf("gsettings action classified as %q", action.Classification)
		}
		if len(action.Command.Args) != 4 || action.Command.Args[0] != "set" {
			t.Errorf("unexpected gsettings command: %#v", action.Command)
		}
	}
	if seen != 5 {
		t.Fatalf("gsettings actions = %d, want 5", seen)
	}
}
