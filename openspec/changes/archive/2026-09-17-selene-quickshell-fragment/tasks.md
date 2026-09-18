# Tasks: the Quickshell bundle fragment (quickshell.json) for Selene

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~420 (≈160 authored across 12 small JSON fragments + ≈260 in tests/docs/selector) |
| 400-line budget risk | Medium |
| Chained PRs recommended | No |
| Delivery strategy | single-pr |
| Note | One coherent contract change: fragments, validator, tests and spec travel together; splitting them creates intermediate states where the contract and the guards disagree. |

## Dependency Graph

```text
T1 (fragments: schema + 12 bundles) ──┬──> T3 (theme-selector required_files) ──> T4 (selector tests)
                                      ├──> T5 (palette contract: assertions + pin)
                                      └──> T7 (spec delta)
T2 (generator + manual verification) ──┘
T6 (README + openspec context) ──> T7
T8 (verify suites + verify-report)
```

## 1. Fragment generation

- [x] 1.1 Escribir el generador de desarrollo (dev-time only) que replica la
      fórmula de `Theme.qml` y parsea la sintaxis real `palette = N=#hex`.
- [x] 1.2 Generar `quickshell.json` en los 12 bundles y verificar que cada
      fragmento es JSON válido con los 14 keys del contrato.
- [x] 1.3 Verificar manualmente tokyo-night contra la derivación runtime
      (bgDeep `#111219`, surface `#26293b`, surfaceBright `#272937`, textDim
      `#707692`).

## 2. Validación del selector

- [x] 2.1 Agregar `quickshell.json` a `required_files` en
      `home/.local/bin/moonarch/theme-selector`.
- [x] 2.2 Agregar el fixture del fragmento en `make_bundle` y el caso
      "missing Quickshell fragment is rejected" en
      `tests/moonarch-theme-selector_test.sh` (más exclusión de worktrees de
      submódulos en el barrido de herramientas retiradas: falsos positivos por
      hashes nix con `ewW`).

## 3. Contrato de paleta

- [x] 3.1 Extender `required_files` del test de paleta y agregar las
      aserciones por bundle: `version`, 13 tokens contra `waybar.css` /
      `ghostty.conf`, y las 4 derivaciones `mix()` en awk.
- [x] 3.2 Extender el set protegido de Tokyo Night (path + blob hash del
      fragmento).

## 4. Spec y documentación

- [x] 4.1 Delta `openspec/changes/2026-09-17-selene-quickshell-fragment/specs/moonarch-theme-selector/spec.md`
      (cuatro consumidores; contrato del fragmento).
- [x] 4.2 Actualizar `README.md` y el contexto de `openspec/config.yaml`.

## 5. Verificación

- [x] 5.1 `bash tests/moonarch-theme-palette_test.sh` y
      `bash tests/moonarch-theme-selector_test.sh` en verde.
- [x] 5.2 `bash test.sh` completo (incluye Docker Stow).
- [x] 5.3 Escribir `verify-report.md`.