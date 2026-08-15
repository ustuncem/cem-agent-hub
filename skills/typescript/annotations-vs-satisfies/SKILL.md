---
name: annotations-vs-satisfies
description: >
  Prefer explicit TypeScript type annotations when the expected shape is
  known and stable; use satisfies to verify conformance while preserving
  a more specific inferred type. Use when choosing `: Type` vs satisfies,
  typing config or const objects, route maps, or lookup tables; when
  defining application contracts; or when typing API responses whose
  documentation may be incomplete, outdated, or uncertain.
---

# Annotations vs Satisfies

**Keep application-owned types explicit and strict while allowing pragmatic flexibility when external API contracts are uncertain.**

## Core principle

- Prefer explicit type annotations when the expected shape is known and stable.
- Use `satisfies` when you want to verify that a value conforms to a type while preserving its more specific inferred type.
- Do not use `satisfies` automatically just because it preserves inference; annotations are usually clearer when defining contracts.

## API typing

Be more careful:

- Real-world APIs often have incomplete, outdated, or inaccurate documentation.
- Sometimes API types have to be discovered incrementally from actual responses.
- Overly strict annotations can become counterproductive when the API contract is still uncertain.
- When working on API response types and the correct strictness is unclear, ask the user whether they want a strict documented contract or a more permissive/discovery-oriented type.
- Avoid inventing strict API guarantees that are not supported by documentation or observed responses.

## Decision procedure

For every `: Type` vs `satisfies Type` choice, walk top-down and stop at the first match.

1. **Function parameters, return types, or a named contract the rest of the program should see?** → annotate.
   Done when: the value is that type going forward, not a one-off inferred shape.

2. **The expected shape is known, stable, and application-owned?** → annotate.
   Done when: config, models, and other app types are explicit contracts.

3. **Conformance must be checked, but later code needs the more specific inferred type** (literal keys, literal values, `keyof typeof` maps)? → `satisfies`.
   Done when: missing/wrong properties fail the check, and the inferred type stays narrow. Use `as const satisfies` when literals must stay literal.

4. **`satisfies` is being added only to preserve inference, with no downstream use of that specificity?** → annotate instead.
   Done when: the annotation is the contract; inference preservation is not a goal by itself.

5. **External API request/response, and the contract is incomplete, outdated, or not yet observed?** → do not invent a strict shape. Ask whether they want a strict documented contract or a more permissive/discovery-oriented type.
   Done when: every required field is backed by docs or a real payload, at the strictness the user chose.

## Examples

- Annotations vs `satisfies`, when not to reach for `satisfies`, and API response strictness: [examples.md](references/examples.md)
