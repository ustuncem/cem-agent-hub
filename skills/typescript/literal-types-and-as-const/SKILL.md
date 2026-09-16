---
name: literal-types-and-as-const
description: >
  Preserve TypeScript literal types at the source with as const when
  exact values matter; leave widening when mutability or generalization
  is intended. Use when object properties widen to string or number
  despite const; when choosing as const vs a call-site literal
  assertion; when readonly tuples clash with mutable APIs; or when
  as const is treated as runtime or deep immutability.
---

# Literal Types and `as const`

**Object property literals widen even under `const`. Preserve exact values at the source with `as const` only when that precision is intended.**

## Core principle

- `const x = "GET"` infers `"GET"`. `let x = "GET"` infers `string`.
- `const obj = { method: "GET" }` still gives `method: string` — `const` blocks rebinding the variable, not mutating or generalizing property types.
- `as const` on a literal expression: keeps literals from widening, makes object properties `readonly`, and turns array literals into readonly tuples.
- Prefer fixing inference at the source over asserting a literal at the call site.
- `as const` is a type-level const context, not runtime freeze and not deep immutability of referenced values.
- Widening is often correct. Do not reach for `as const` reflexively.

## Decision procedure

For every literal / `as const` choice, walk top-down and stop at the first match.

1. **Downstream code needs the exact literal** (method name, discriminant-like value, fixed config key/value)? → `as const` (or an equivalent source-level const context) on the literal expression.
   Done when: the binding keeps the literal type without a call-site `"…" as "…"` assertion.

2. **The value should stay general or mutable** (user-editable fields, `string[]` / mutable object APIs, values that will be reassigned)? → leave the widened type; do not add `as const`.
   Done when: the type matches the intended mutability and range.

3. **A consumer fails because a property widened to `string`/`number`?** → fix the producer with `as const` (or a named literal/union type at the source), not an assertion where it is used.
   Done when: the call site type-checks from inferred literals.

4. **`as const` is being used only to silence an unrelated type error?** → stop. Fix the real types; `as const` is not a generic escape hatch.
   Done when: the change either preserves intended literals or is removed.

5. **Readonly / tuple shape from `as const` conflicts with an API that expects mutable arrays or writable properties?** → drop `as const`, or copy into a mutable structure at the boundary.
   Done when: the value matches the API’s mutability contract.

## What `as const` does not do

- It does not freeze values at runtime.
- It does not deeply freeze referenced mutable data: nested object/array *literals* become readonly in the type, but a referenced mutable array/object can still be mutated through that reference.
- It does not replace validating external data or choosing `: Type` / `satisfies` (see neighboring skills).

## Common traps

- Assuming `const obj` preserves property literal types.
- Asserting `"GET"` at the consumer instead of preserving inference at the source.
- Ignoring the readonly / readonly-tuple tradeoff with mutable APIs.
- Treating `as const` as deep or runtime immutability.
- Preserving literals when mutability or generalization is the real intent.

## Examples

- `const` vs `let`, object widening + `as const`, readonly tuple vs mutable API, and referenced mutability: [examples.md](references/examples.md)
