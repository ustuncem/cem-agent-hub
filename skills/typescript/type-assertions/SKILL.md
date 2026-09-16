---
name: type-assertions
description: >
  Use TypeScript type assertions (as Type) only when the compiler
  cannot infer a type the developer already knows. Use when writing
  or removing as Type, as any, as unknown as Type, or angle-bracket
  assertions; when silencing type errors; or when typing untrusted
  or external data instead of validating it. For literal widening
  and as const, use literal-types-and-as-const.
---

# Type Assertions

**Fix the underlying type information rather than overriding the compiler.**

## Core principle

- Type assertions (`as Type`) tell TypeScript to trust the developer's knowledge about a value's type.
- They do not perform runtime validation and can hide real type errors.
- Prefer type inference, narrowing, generics, type guards, or proper type definitions before using an assertion.
- Do not use assertions simply to silence TypeScript errors.
- Use assertions only when the developer genuinely has information that TypeScript cannot infer.
- Treat `as any` and `as unknown as Type` as strong warning signs and avoid them unless absolutely necessary.
- For external or untrusted data, prefer runtime validation instead of asserting the expected type.

## Decision procedure

For every `as Type` (including `as any`, `as unknown as Type`, and `<Type>value`), walk top-down and stop at the first match.

1. **A correct annotation, generic, or named type would make the assertion unnecessary?** → fix that type.
   Done when: the value type-checks without `as`.

2. **The value can be narrowed** (`typeof`, equality, `in`, `instanceof`, a type predicate, or a runtime schema)? → narrow.
   Done when: use happens only on the proven branch.

3. **The data is external or untrusted** (JSON, I/O, query params, third-party payloads)? → validate at runtime; do not assert the expected type.
   Done when: a guard or schema produces a typed value.

4. **The developer has information TypeScript cannot infer**, and the assertion is a related type (not a lie)? → a single, narrow `as Type`.
   Done when: the asserted type is the smallest true type, not `any`.

5. **Still failing only because of `any` or overlapping-but-unrelated types?** → do not reach for `as any` or `as unknown as Type` to silence it. Fix the types. Use those forms only when a safe alternative is genuinely impossible, isolated at the boundary, and commented.

## Existing assertions

When encountering `as Type`:

1. Delete it and see what the checker actually knows.
2. Prefer inference, a parameter/return annotation, a generic, a union, or a type guard over putting the assertion back.
3. Keep a remaining assertion only when TypeScript cannot express the fact, and keep it next to the reason.
4. Replace `as any` / `as unknown as Type` unless the surrounding types cannot be fixed.

`as const` is a const assertion (literal narrowing), not a type override. Prefer it over `as Type` when the goal is to keep a literal or readonly tuple. For when to use it and the readonly tradeoffs, see `literal-types-and-as-const`.

## Examples

- Replacing assertions, valid remaining uses, and warning forms: [examples.md](references/examples.md)
