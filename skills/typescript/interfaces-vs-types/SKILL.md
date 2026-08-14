---
name: interfaces-vs-types
description: >
  Choose between TypeScript interface and type by object-contract vs
  type-level shape. Use when defining a new type, composing object
  contracts with extends or intersections, modeling unions or
  mutually exclusive props, or editing an existing interface/type
  declaration.
---

# Interfaces vs Types

Pick by **object contract** vs **type-level** shape.

## Core rule

- **Object contract** → prefer `interface` (especially when extended, implemented, or declaration-merged).
- **Type-level** (unions, tuples, primitives, functions, mapped/conditional/template-literal/branded types, other transforms) → `type`.

## Decision procedure

For every new type definition, walk top-down and stop at the first match.

1. **Union** (including discriminated)? → `type`.
   Done when: mutually exclusive variants are a union, not optional fields on one shape.

2. **Type-level form** — tuple, primitive alias, function, template-literal, branded, conditional, or mapped? → `type`.
   Done when: the declaration uses `type` for that form.

3. **Object contract extending other object contracts?** → `interface extends`.
   Done when: composition uses `extends` for ordinary object shapes.

4. **Class will implement it, or declaration merging is intentional?** → `interface`.
   Done when: implement/merge intent is explicit in the choice.

5. **Simple object shape, no composition?** → follow the local convention; leave either form alone.
   Done when: the declaration matches nearby files.

## Existing code

When editing a valid declaration:

1. Keep the existing `interface` or `type`.
2. Prefer replacing ordinary-object `&` intersections with `interface extends` when the file is already being touched, intersections are hard to read, errors are unclear, or language-service cost is measured.
3. Leave unions, mapped, conditional, tuple, and branded forms as `type`.
4. Check downstream usage before changing exported public types.
5. Add declaration merging only when required.

## React props

- Object-shaped props that extend another object contract → `interface extends`.
- Mutually exclusive prop variants → discriminated `type` union.

## Examples and performance

- Concrete forms (contracts, composition, unions, transforms, props, merging): [examples.md](references/examples.md)
- When IntelliSense or compile time drives the change: [performance.md](references/performance.md)
