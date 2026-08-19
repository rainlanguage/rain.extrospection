---
paths:
  - "src/**"
  - "test/**"
  - "foundry.toml"
---

# Mutation and coverage campaigns run under `FOUNDRY_PROFILE=mutation`

```bash
nix develop -c bash -c 'FOUNDRY_PROFILE=mutation forge test'
```

`ExtrospectConstantsTest` (`test/src/concrete/Extrospect.constants.t.sol`) pins
`type(Extrospect).creationCode` and `type(Extrospect).runtimeCode` against the
`EXTROSPECT_*_V1` constants. Those compiler outputs change for any edit to any
source file reachable from `Extrospect`, so `testExtrospectCreationBytecode` and
`testExtrospectRuntimeCodehash` both fail under every source mutation, whether or
not the mutated behaviour is observable. A campaign run on the default profile
scores every mutant `KILLED` and measures nothing.

`[profile.mutation]` in `foundry.toml` sets
`no_match_contract = "ExtrospectConstantsTest"` and inherits everything else from
`default`. The default profile keeps the pins, so CI and releases still catch
constant drift.
