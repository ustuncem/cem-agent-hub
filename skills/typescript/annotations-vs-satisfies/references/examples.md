# Examples — Annotations vs Satisfies

Companion to [`annotations-vs-satisfies`](../SKILL.md). Load when the decision procedure needs a concrete form.

## Annotate known, stable contracts

A value that *is* the contract should be annotated so the rest of the program sees that type:

```ts
interface User {
  id: string;
  name: string;
}

function toUser(row: Row): User {
  return { id: row.id, name: row.name };
}

const current: User = { id: "1", name: "Ada" };
```

`satisfies` here only checks the initializer. It does not make `User` the type of the binding, and it is the wrong tool for parameters and return types:

```ts
function toUser(row: Row) {
  return { id: row.id, name: row.name } satisfies User;
}

const current = { id: "1", name: "Ada" } satisfies User;
```

Prefer the annotation whenever the expected shape is known and stable.

## Use `satisfies` to keep a more specific inferred type

`satisfies` checks assignability without widening the value to the constraint. That matters when later code needs literal keys or literal values:

```ts
const routes = {
  home: "/",
  settings: "/settings",
} satisfies Record<string, `/${string}`>;

type RouteName = keyof typeof routes;
// "home" | "settings"

function pathFor(name: RouteName): string {
  return routes[name];
}
```

An annotation would type-check the object and then forget the keys:

```ts
const routes: Record<string, `/${string}`> = {
  home: "/",
  settings: "/settings",
};

type RouteName = keyof typeof routes;
// string
```

Use `as const satisfies` when the constraint must hold and the literals must stay literal:

```ts
type Status = "pending" | "done";

const statusLabel = {
  pending: "Pending",
  done: "Done",
} as const satisfies Record<Status, string>;

statusLabel.pending;
// "Pending"
```

## Do not use `satisfies` just because it preserves inference

If nothing downstream needs the narrower type, an annotation is clearer:

```ts
interface Theme {
  primary: string;
  accent: string;
}

const theme: Theme = {
  primary: "#111111",
  accent: "#00aaff",
};
```

```ts
const theme = {
  primary: "#111111",
  accent: "#00aaff",
} satisfies Theme;
```

The second form preserves `"#111111"` on `primary` for no benefit. Annotations are usually clearer when defining contracts.

## API responses: do not invent a strict contract

Documented fields you have actually seen can be named. Do not add fields, nullability, or requiredness the docs and payloads do not support:

```ts
interface SearchHit {
  id: string;
  title: string;
}

interface SearchResponse {
  results: SearchHit[];
}
```

This invents guarantees the API may not keep:

```ts
interface SearchResponse {
  results: SearchHit[];
  total: number;
  nextCursor: string | null;
  facets: Record<string, number>;
}
```

When the contract is still uncertain, prefer a discovery-oriented type over a strict one you guessed:

```ts
type SearchResponse = {
  results: SearchHit[];
} & Record<string, unknown>;
```

If the correct strictness is unclear, ask whether they want a strict documented contract or a more permissive/discovery-oriented type. Tighten only from documentation or observed responses.
