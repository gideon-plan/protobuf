# Choice/Life Adoption Plan: protobuf

## Summary

- **Error type**: `BridgeError` defined in lattice.nim -- move to `decode.nim`
- **Files to modify**: 5 + re-export module
- **Result sites**: 4
- **Life**: Not applicable

## Steps

1. Delete `src/protobuf/lattice.nim`
2. Move `BridgeError* = object of CatchableError` to `src/protobuf/decode.nim`
3. Add `requires "basis >= 0.1.0"` to nimble
4. In every file importing lattice:
   - Replace `import.*lattice` with `import basis/code/choice`
   - Replace `Result[T, E].good(v)` with `good(v)`
   - Replace `Result[T, E].bad(e[])` with `bad[T]("protobuf", e.msg)`
   - Replace `Result[T, E].bad(BridgeError(msg: "x"))` with `bad[T]("protobuf", "x")`
   - Replace return type `Result[T, BridgeError]` with `Choice[T]`
5. Update re-export: `export lattice` -> `export choice`
6. Update tests
