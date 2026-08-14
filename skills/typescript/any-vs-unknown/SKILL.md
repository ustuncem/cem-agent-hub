---
name: any-vs-unknown
description: >
  Prefer unknown over any when a TypeScript value's type is not known.
  Use when choosing any vs unknown, typing JSON.parse, catch clauses,
  untyped inputs, loosely typed APIs, replacing any, or writing type
  guards before using an unknown value.
---

# Any vs Unknown

**Prefer `unknown` whenever the actual type is not known. `any` is an escape hatch, not a default.**

## Core principle

- `any` effectively opts out of TypeScript's type checking. Values typed as `any` can be accessed, called, assigned, and passed around without compiler validation.
- `unknown` represents a value whose type is not yet known while preserving TypeScript's safety guarantees. The value must be narrowed or validated before it can be used.
- Prefer `unknown` whenever the actual type is not known.
- Use `any` only when there is no practical type-safe alternative, such as unavoidable interaction with poorly typed third-party APIs or legacy code.

## Decision procedure

For every untyped or loosely typed value, walk top-down and stop at the first match.

1. **The real type is known or can be named?** → that type (or a union of known shapes).
   Done when: callers and callees share a defined type, not `any`/`unknown`.

2. **The type varies but is constrained by the caller?** → generic (`<T>`).
   Done when: the same `T` flows in and out instead of `any`.

3. **The type is not known yet** (JSON, I/O, `catch`, dynamic input)? → `unknown`, then narrow.
   Done when: use happens only after validation.

4. **Untyped object bag?** → `Record<string, unknown>` (or a defined interface), not `{ [key: string]: any }`.
   Done when: property values are `unknown` until narrowed.

5. **No practical type-safe alternative** (poorly typed third-party API, legacy JS you cannot wrap)? → `any` at the smallest boundary.
   Done when: the escape hatch is isolated; prefer wrapping so callers see `unknown` or a real type.

## Replacing existing `any`

When encountering `any`, first consider whether it can be replaced with `unknown`, a generic, a union, or a properly defined type.

1. Replace with a precise type or union if the shape is known.
2. Replace unconstrained values with `unknown` and add narrowing.
3. Replace "works for every T" APIs with generics.
4. Keep `any` only at the smallest boundary, with a comment naming why a safe type is impractical.

Do not use `as any` (or `any` parameters/returns) to silence a type error. Fix the types or narrow.

## Narrowing `unknown`

Before property access, calls, or assignment into a typed target: `typeof`, equality, `in`, `instanceof`, a user-defined type predicate, or a runtime schema. Do not assert `as T` unless surrounding checks already prove `T`.

## Examples

- Boundaries, replacements, narrowing, and the `any` escape hatch: [examples.md](references/examples.md)
