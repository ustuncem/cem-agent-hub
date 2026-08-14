# Examples — Type Assertions

Companion to [`type-assertions`](../SKILL.md). Load when the decision procedure needs a concrete form.

## Fix the types instead of asserting

A mismatch usually means the declared type is wrong. Annotate or genericize; do not silence the error:

```ts
function idsOf(users: User[]): string[] {
  return users.map((user) => user.id);
}
```

```ts
function idsOf(users: User[]): string[] {
  return users.map((user) => user.id as string);
}
```

The second form hides that `id` might be missing. Prefer a `User` where `id` is `string`.

## Narrow or guard instead of `as Type`

```ts
function area(el: Element): number {
  if (!(el instanceof HTMLCanvasElement)) {
    throw new Error("Expected a canvas");
  }
  return el.width * el.height;
}
```

```ts
function area(el: Element): number {
  const canvas = el as HTMLCanvasElement;
  return canvas.width * canvas.height;
}
```

The assertion has no runtime check; a `Div` throws at `.width`.

## External data: validate, do not assert

`JSON.parse` and similar sources are untrusted. A type predicate or schema yields a real `Config`; `as Config` does not:

```ts
function parseConfig(raw: string): Config {
  const data: unknown = JSON.parse(raw);
  if (!isConfig(data)) {
    throw new Error("Invalid config");
  }
  return data;
}
```

```ts
function parseConfig(raw: string): Config {
  return JSON.parse(raw) as Config;
}
```

The assertion compiles even when the payload is `{ "nope": true }`.

## When an assertion is warranted

Use `as Type` only for a fact TypeScript cannot infer, and keep the asserted type tight:

```ts
const canvas = document.querySelector("#main-canvas");
if (canvas === null) {
  throw new Error("Missing #main-canvas");
}
const ctx = (canvas as HTMLCanvasElement).getContext("2d");
```

Markup guarantees this id is a canvas; TypeScript only knows `Element`.

`as const` preserves literals; it is not a type override:

```ts
const routes = ["/home", "/settings"] as const;
```

Prefer a variable annotation over asserting an empty collection:

```ts
const items: Item[] = [];
```

## Warning signs: `as any` and `as unknown as Type`

These compile almost anything. They hide real errors and skip relatedness checks (`as Type` still requires overlap). Avoid them unless a boundary cannot be typed and the hole is isolated:

```ts
function readLegacy(id: string): unknown {
  const result = legacyLookup(id) as any;
  return result as unknown;
}
```

```ts
const user = payload as unknown as User;
```

The double assertion forces an unrelated type. Do not use `as any` (or `<Type>value`) to make an assignment compile. Fix the underlying types.
