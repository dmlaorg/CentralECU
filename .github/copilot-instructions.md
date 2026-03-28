# Copilot Instructions for CentralECU

## Big picture (model-first repository)
- This repo is a **domain modeling workspace**, not a conventional app/service codebase.
- Source-of-truth models live in `DMLA/`, `SysML/`, and `SysMLv2/`.
- Runtime behavior is encoded in DMLA entities/operations (constraints, validation, tests), especially:
  - `DMLA/bootstrap.dmla` (meta-model base types, validation pipeline, utility ops)
  - `DMLA/Automotive.dmla` (ASIL domain model + automotive contracts)
  - `DMLA/CentralEcu.dmla` (Central ECU composition model + connect logic + tests)

## Boundaries and data flow
- `DMLA/*.dmla` defines executable modeling semantics and domain constraints.
- `SysML/*.xml` and `SysMLv2/CentralEcu.sysml` are parallel model representations for architecture/spec exchange.
- `output/entities.xml` is a generated serialized entity graph (compiled/interpreted model output).

## How validation and constraints are implemented
- Validation is meta-chain based via `ValidateGlobal` and `ValidateSelf` in `DMLA/bootstrap.dmla`.
- Domain rules are implemented in overrides/contracts, not in external scripts:
  - `Automotive.ASIL.Validate(...)` enforces type/value rules.
  - `AutomotiveElement.Check(...)` enforces decomposition safety constraints.
- In `DMLA/CentralEcu.dmla`, use existing patterns (`@Type`, `@Cardinality`, `@ContractSlot`, `override operation`, etc.) when adding model elements.

## Model composition patterns to preserve
- Keep inheritance and slot typing explicit (`entity X : Y`, `new slot`, `@Type = {TypeRef = ...}`, etc.).
- Preserve existing naming style for domain entities (e.g., `SoC`, `Core`, `EmbeddedSoftware`, `AutomotiveRequirement`).
- Prefer extending existing contracts/validators over introducing parallel validation mechanisms.
- Keep connection semantics through typed ports/interfaces (see `Port`, `Input`, `Output`, `Connect(...)`, etc.).

## Developer workflow (discoverable in repo)
- VS Code debug config exists in `DMLA/.vscode/launch.json` using debugger type `dsharp` (`D#: Run`).
- Use this launch profile for stepping through DMLA execution/validation logic.
- There is no conventional `package.json`/`csproj`/test runner in this repo root; model validation is in itself strong coherency test, more formal test cases are model annotations inside DMLA files tagged with `@Test` or `@FalseTest`.
- Tests can be executed in DMLA by calling a test runner `operation` in an `--entrypoint` option that collects the test cases, prompts their evaluation via `TestEntities` or `TestDomain` calls and outputs their results to terminal via `PrintTestResults` in a nicely formatted manner.
- Test Annotation meta is defined in the `DMLA/workspace.dmla` file by `slot testUtilsTestAnnotationMeta`.

## Editing guidance for AI agents
- Prefer editing `DMLA/*.dmla` for behavioral/domain changes.
- Treat `output/entities.xml` as generated outputs unless task explicitly requests artifact edits.
- Keep `SysMLv2` aligned conceptually with DMLA domain terms when adding/changing architecture concepts.
- Make minimal, model-consistent changes; avoid introducing external build systems or unrelated tooling.
- Revert, adapt, revise your changes so that you minimize new occurence in the `PROBLEMS` vindow of VS Code.
- Always prompt model validation after a change and make corrections based on the validation errors provided.
- Always run formal DMLA tests, if available, and make corrections based on the test report printed to the terminal.
- Avoid editing `SysML` folder; these are artifacts of the Enterprise Architect GUI architecture tool.

## Quick examples to follow
- New safety rule: implement as `override operation ValidationError[] Validate(...)` or contract `Check(...)` near existing automotive rules in `DMLA/Automotive.dmla`.
- New ECU part type: derive from `CentralEcuElement`/`CentralEcuComposition`, add typed/cardinality-constrained slots as in `DMLA/CentralEcu.dmla`.
- New architecture-level SysML concept: update both `SysMLv2/CentralEcu.sysml` according to DMLA entities in `*.dmla` files because semantics must stay synchronized.
- Example DMLA test call: `dmla run --source "testing.dmla" "workspace.dmla" "bootstrap.dmla" -nobootstrap --entrypoint RunTests.AllUnitTests`