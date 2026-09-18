---
name: narrowing-and-type-guards
description: >
  Narrow TypeScript values from trustworthy runtime evidence and control
  flow; prefer safe typeof/equality/in/instanceof checks and semantic
  reusable guards over assertions or repeated structural checks. Use when
  writing or reviewing type predicates (value is T), typeof/in/instanceof
  narrowing, truthiness vs explicit nullish checks, early-return
  elimination of union members, inferred predicates, or when narrowing is
  lost after reassignment or mutation. For discriminated-union design and
  never exhaustiveness, use discriminated-unions. For as Type, use
  type-assertions.
---

# Narrowing and Type Guards

**Narrow from runtime evidence TypeScript understands; put complex or domain checks in semantic guards, not scattered structural chains or `as`.**

## Core principle

- Narrowing is flow-sensitive: it changes the observed type on a path, not the declared type of the binding.
- Prefer ordinary checks TypeScript already understands: `typeof`, equality, `in`, `instanceof`.
- Use reachability and early returns to eliminate union members; remaining paths narrow automatically.
- Truthiness is a semantic check (is this value usable?), not a generic defined-value check.
- `typeof value === "object"` includes `null` — exclude it when you mean a non-null object.
- `"prop" in value` proves presence; it may not uniquely identify a union member when that property is optional on more than one member.
- A user-defined predicate `value is T` is a contract for both the true and false branches — the runtime check must justify both.
- Prefer inferred predicates when modern TypeScript already infers the correct narrowing; add an explicit `value is T` only when the claim is needed and true.
- Reassignment and mutation can invalidate or prevent narrowing; treat narrowed facts as tied to a stable value.
- Keep trivial checks inline. Move complex, repeated, or domain-specific runtime checks into semantic utilities (`isApiError`, `isUser`, `isSuccessfulResponse`).

## Decision procedure

For every narrowing or guard choice, walk top-down and stop at the first match.

1. **A built-in check proves the needed type** (`typeof`, equality, `in`, `instanceof`, early return)? → use it inline on that path.
   Done when: use happens only after the evidence; no `as` fills a gap.

2. **The real requirement is definedness, and `0` / `""` / `false` are valid?** → check explicitly (`!== undefined`, `!= null`, etc.), not truthiness.
   Done when: falsey-but-valid values remain on the kept path.

3. **`typeof … === "object"` is used for a non-null object?** → also exclude `null`.
   Done when: the true branch cannot be `null`.

4. **`"prop" in value` is used to pick a union member, and `prop` is optional on multiple members?** → do not treat presence alone as identity; add a check that uniquely distinguishes the member (or remodel — see `discriminated-unions`).
   Done when: the true branch is only the intended member.

5. **The same complex or domain-shaped check appears (or will appear) at multiple call sites?** → extract a semantic guard utility; call sites use the name, not nested structural validation.
   Done when: application code reads `if (isApiError(error))` (or similar); structural detail lives inside the guard.

6. **Writing `value is T` (or relying on an inferred predicate)?** → ensure the implementation proves `T` on true and not-`T` (for the relevant domain) on false. Prefer inference when it already matches; annotate only when the explicit claim is required and sound.
   Done when: both branches are honest; no common false-negative lies about the false branch.

7. **The value is reassigned or mutated after a successful narrow?** → re-check, or narrow a `const` / local copy that does not change.
   Done when: use sites still have valid evidence for the type they assume.

8. **Still reaching for `as` because evidence is missing?** → do not assert; add a real check or fix the types (see `type-assertions`).
   Done when: the path is proven or the model is fixed.

## Common traps

- Repeating long structural checks at multiple call sites instead of a semantic guard utility.
- Predicates that look right for common values but violate the false-branch contract.
- `typeof value === "object"` without excluding `null`.
- Truthiness when valid values such as `0` or `""` must be preserved.
- Assuming `"prop" in value` always selects exactly one union member.
- Replacing missing runtime evidence with `as`.
- Assuming a narrowing remains valid after reassignment or mutation.
- Explicit predicate annotations when TypeScript already infers the predicate correctly.
- Naming guards after implementation details instead of domain meaning when the check is domain semantics.

## Examples

- Control-flow narrowing, truthiness, `in`, semantic guards, unsound/inferred predicates, and mutation: [examples.md](references/examples.md)
