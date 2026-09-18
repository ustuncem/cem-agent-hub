---
name: discriminated-unions
description: >
  Model variant-dependent TypeScript data as discriminated unions
  instead of one object with conditionally meaningful optional fields.
  Use when a status, kind, or type field gates which fields are valid;
  when optional data/error coexist unsafely; when narrowing should
  unlock variant-specific fields without casts or !; when exhaustiveness
  with never is needed; or when deciding a union is not the right model.
  For literal widening and as const, use literal-types-and-as-const.
---

# Discriminated Unions

**Model each valid variant as its own union member with a shared literal discriminant — do not pack mutually exclusive payloads into one loose object.**

## Core principle

- The smell: one object type, a `status` / `kind` / `type` field, and optional fields whose validity depends on that field.
- Each valid state should be a separate union member; all members share a discriminant with distinct literal values.
- Checking the discriminant narrows the entire object, so variant-specific fields are available without casts or non-null assertions.
- Prefer modeling valid states directly over allowing impossible combinations.
- Use `never` for exhaustive handling when every variant must be covered — adding a new variant should break those consumers.
- A fallback/`default` is valid when unknown or future variants are intentionally accepted.
- Fit when variants are finite, mutually exclusive, and carry different payloads. Do not force them when fields are genuinely independent or there is no meaningful variant/payload relationship.

## Decision procedure

For every variant-shaped type, walk top-down and stop at the first match.

1. **One type holds a tag plus optional fields that are only valid for some tag values?** → split into a discriminated union: one member per valid combination, shared discriminant with distinct literals.
   Done when: impossible combinations are unrepresentable, and narrowing the tag unlocks the payload without `!` or casts.

2. **A consumer must handle every known variant today?** → exhaustive `switch`/`if` with a `never` check on the remainder.
   Done when: adding a new union member produces a compile error at that consumer.

3. **Unknown or future variants are intentionally tolerated?** → keep a non-exhaustive fallback/`default`; do not pretend exhaustiveness with `never`.
   Done when: the fallback path is deliberate, not a silent hole in required coverage.

4. **Fields are independent, or there is no real variant/payload split?** → keep a single type (or ordinary union without forcing a discriminant).
   Done when: the model matches independence; no fake `kind` was invented.

5. **Still reaching for `!` or `as` to read a variant field?** → the model is still weak; return to step 1.
   Done when: access is safe after discriminant narrowing alone.

## Common traps

- One interface with many variant-dependent optional fields.
- Using `!` or casts to compensate for a weak model.
- Allowing impossible state combinations.
- Duplicate or non-distinguishing discriminant values.
- Using a fallback `default` when exhaustive handling is actually required.
- Assuming every union should be a discriminated union.
- Drifting into literal-widening concerns that belong to `literal-types-and-as-const`.

## Examples

- Bad optional request state, discriminated refactor, narrowing, and exhaustive `never`: [examples.md](references/examples.md)
