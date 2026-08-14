# Examples — Any vs Unknown

Companion to [`any-vs-unknown`](../SKILL.md). Load when the decision procedure needs a concrete form.

## Unknown at untyped boundaries

`JSON.parse` and similar I/O return values whose type is not known — type them as `unknown` and narrow before use:

```ts
function parseConfig(raw: string): Config {
  const data: unknown = JSON.parse(raw);
  if (!isConfig(data)) {
    throw new Error("Invalid config");
  }
  return data;
}

function isConfig(value: unknown): value is Config {
  return (
    typeof value === "object" &&
    value !== null &&
    "apiUrl" in value &&
    typeof value.apiUrl === "string"
  );
}
```

`catch` bindings are `unknown` under `useUnknownInCatchVariables` (on with `strict`). Narrow before using the error:

```ts
try {
  await load();
} catch (error: unknown) {
  const message = error instanceof Error ? error.message : String(error);
  log(message);
}
```

## Generics instead of `any`

When the caller knows `T`, thread it through. Do not erase it with `any`:

```ts
function first<T>(items: T[]): T | undefined {
  return items[0];
}
```

```ts
// Wrong — callers lose the element type
function first(items: any[]): any {
  return items[0];
}
```

## Unions and named types instead of `any`

If the set of shapes is known, name it. `any` is not a substitute for a union:

```ts
type Result<T> = { ok: true; value: T } | { ok: false; error: string };

function unwrap<T>(result: Result<T>): T {
  if (!result.ok) {
    throw new Error(result.error);
  }
  return result.value;
}
```

## Object bags

Untyped maps hold `unknown` values, not `any`:

```ts
function readFlag(flags: Record<string, unknown>, name: string): boolean {
  const value = flags[name];
  return value === true;
}
```

## Why `any` is unsafe

A value typed `any` can be accessed, called, assigned, and passed without compiler validation — mistakes compile:

```ts
function handle(data: any) {
  data.foo.bar();
  const n: number = data;
  takesUser(data);
}
```

The same value as `unknown` is unusable until narrowed:

```ts
function handle(data: unknown) {
  data.foo.bar();
  // Property 'foo' does not exist on type 'unknown'.

  const n: number = data;
  // Type 'unknown' is not assignable to type 'number'.
}
```

`unknown` is assignable to `unknown` and `any` only. `any` is assignable in both directions.

## Escape hatch: isolate `any`

Use `any` only when a safe type is impractical. Wrap the boundary so the rest of the program never sees `any`:

```ts
import { legacyLookup } from "untyped-legacy-sdk";

function lookupUser(id: string): unknown {
  // legacyLookup is untyped; isolate the any here.
  const result: any = legacyLookup(id);
  return result as unknown;
}
```

Do not leak `any` through public parameters or return types. Do not use `as any` to silence an error in otherwise typed code.
