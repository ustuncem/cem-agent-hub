---
name: optional-vs-undefined
description: >
  Treat a TypeScript optional property (foo?: string) as a key that may
  be absent, and foo: string | undefined as a required key whose value
  may be undefined. Use when choosing ? vs | undefined, enabling
  exactOptionalPropertyTypes, constructing objects, typing function
  parameters, checking whether a property exists, or when it is unclear
  whether a field may be omitted.
---

# Optional vs Undefined

**Optional means the property may be completely absent, while `| undefined` means the property is required to exist but its value may be `undefined`.**

## Core principle

- `foo?: string` — the key may be missing. Reading it still yields `string | undefined`.
- `foo: string | undefined` — the key must be present; the value may be `undefined`.
- Do not treat these as interchangeable. Use `?` when absence is meaningful, and `| undefined` when the key itself should always exist.
- `exactOptionalPropertyTypes` makes the distinction stricter: optional properties cannot be assigned `undefined` unless `| undefined` is written.

## Decision procedure

For every optional vs `| undefined` choice, walk top-down and stop at the first match.

1. **The key should always exist**, even when there is no value (cleared field, initialized slot, present map entry)? → `foo: T | undefined`.
   Done when: object literals must include `foo`, and `"foo" in obj` is true.

2. **Absence is meaningful** (not provided, omit from a patch, optional argument or option)? → `foo?: T`.
   Done when: the key may be omitted, and callers are not forced to pass `undefined`.

3. **Both missing and explicit `undefined` are valid and distinct?** → `foo?: T | undefined`, and distinguish with `"foo" in obj` (or `Object.hasOwn`), not `=== undefined`.
   Done when: the type allows omit _and_ `foo: undefined`, and checks match that model.

4. **Unsure whether the key may be missing, must always exist, or both?** → ask. Do not guess `?` vs `| undefined`.
   Ask whether the key may be omitted (`foo?: T`), must always exist with a possibly undefined value (`foo: T | undefined`), or both (`foo?: T | undefined`).
   Done when: the user has chosen one of those three.

## Construction, parameters, and checks

- **Objects:** `{}` is assignable to `{ foo?: string }`. It is not assignable to `{ foo: string | undefined }` — that type requires `{ foo: undefined }` or `{ foo: "…" }`.
- **Functions:** `name?: string` may be omitted (`f()`). `name: string | undefined` must be passed (`f(undefined)`).
- **Existence:** `obj.foo === undefined` is true for both missing and present-`undefined`. Use `"foo" in obj` or `Object.hasOwn(obj, "foo")` when the distinction matters.
- **`exactOptionalPropertyTypes`:** `{ foo?: string }` rejects `{ foo: undefined }`. Allow that assignment only with `foo?: string | undefined` (or a required `foo: string | undefined`).

## Examples

- Object literals, parameters, existence checks, `exactOptionalPropertyTypes`, and asking when unsure: [examples.md](references/examples.md)
