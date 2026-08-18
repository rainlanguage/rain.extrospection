# Audits

Reports live in `audit/protofire/`. Each report carries a **Reviews** table
naming the commits it reviewed, and a **Scope > Contracts** table naming the
Solidity files it covers.

Every report's scope table is the union of files across the commits in its own
Reviews table, not the scope of its latest round alone. A report therefore lists
paths that do not exist at the commit it most recently reviewed.

This file records, per report, how the stated scope compares to `src/` at the
latest commit that report reviewed.

## `rain.extrospection.f2c4f5a.feb-2026.pdf`

Reviews `60f35a0` (30/01/26), `4c0aed6` (05/02/26), `f2c4f5a` (10/02/26).

Scope lists 8 files. `src/` at `f2c4f5a` holds the same 8 files.

## `rain.extrospection.ab33ddb-r2.1.feb-2026.pdf`

Reviews `60f35a0` (30/01/26), `4c0aed6` (05/02/26), `ab33ddb` (10/02/26). The
extracted text is identical to the `f2c4f5a` report apart from the commit hash
in the third Reviews row.

Scope lists 8 files. `src/` at `ab33ddb` holds 7. Scope names
`src/concrete/Extrospection.sol`, which does not exist at `ab33ddb`. Every file
in the tree is scoped.

## `rain.extrospection.v0.1.1-r3.0.may-2026.pdf`

Reviews `60f35a0` (30/01/26), `4c0aed6` (05/02/26), `ab33ddb` (10/02/26),
`f9a4674` (24/02/26), `2b0d2cf` (26/05/26, tag `v0.1.1`).

Scope lists 13 files. `src/` at `2b0d2cf` holds 9.

Scoped, absent from `src/` at `2b0d2cf`:

- `src/concrete/Extrospection.sol`
- `src/interface/deprecated/IExtrospectBytecodeV1.sol`
- `src/interface/IExtrospectBytecodeV2.sol`
- `src/interface/IExtrospectERC1167ProxyV1.sol`
- `src/interface/IExtrospectInterpreterV1.sol`

Present in `src/` at `2b0d2cf`, not scoped:

- `src/lib/LibExtrospectMetamorphic.sol`

The 13 scoped paths are the union of the files present across the five reviewed
commits, less `src/lib/LibExtrospectMetamorphic.sol`.

Two findings, `H02` and `L03`, carry
`Path: src/interface/IExtrospectInterpreterV1.sol`, a path absent at `2b0d2cf`.
Both are marked found at `60f35a0`/`4c0aed6` and fixed before `2b0d2cf`.

## Coverage of `src/lib/LibExtrospectMetamorphic.sol`

`src/lib/LibExtrospectMetamorphic.sol` exists at `f9a4674` and `2b0d2cf`, the
fourth and fifth reviewed commits. No report in `audit/protofire/` names it in
its scope table. No finding in any report names it: the only finding path that
reaches it is `M02`, whose `Path` is the wildcard `src/*`, found at `60f35a0`
where the file did not yet exist. The string `metamorphic` does not appear in
the extracted text of any of the three reports.

The library supplies `IExtrospectV1.checkNotMetamorphic` and
`IExtrospectV1.scanMetamorphicRisk` through `src/concrete/Extrospect.sol`.

## Reproducing

Extract a report's scope table (`pdftotext` is in nixpkgs `poppler-utils`):

```
pdftotext -layout audit/protofire/<report>.pdf - \
  | sed -n '/^Scope$/,/^Technical analysis/p'
```

List the source tree at a reviewed commit:

```
git ls-tree -r --name-only <commit> -- src/
```

Compare the current tree against the latest audited commit:

```
git diff --stat 2b0d2cf HEAD -- src/
```
