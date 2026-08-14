# Performance — Interfaces vs Types

Companion to [`interfaces-vs-types`](../SKILL.md). Load when IntelliSense, hover quality, or compile time is the reason for a change.

## What matters

The `type` keyword itself is not a performance problem. Cost comes from shape complexity:

- Large intersections
- Large unions
- Intersections involving unions
- Deeply recursive conditional types
- Repeated anonymous calculated types
- Excessive generic inference
- Large inferred public return types

## Prefer for object contracts

```ts
interface Combined extends A, B, C {}
```

over:

```ts
type Combined = A & B & C;
```

when `A`, `B`, and `C` are ordinary object contracts — interface relationships cache more effectively, flatten more clearly, and usually produce clearer errors and hovers.

Named type aliases help when they cache or simplify a repeated calculated type.

## Refactor bar

Refactor an existing definition only when at least one holds:

- The current model is semantically incorrect
- Object intersections are hard to understand
- Type errors are unclear
- IntelliSense or compiler performance is measurably affected
- The definition is already being modified for another reason

Optimize measured complexity, not syntax preference. Project-specific framework notes (e.g. Next.js) do not justify a universal TypeScript keyword rule.
