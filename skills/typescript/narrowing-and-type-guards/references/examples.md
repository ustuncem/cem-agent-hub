# Examples — Narrowing and Type Guards

Companion to [`narrowing-and-type-guards`](../SKILL.md). Load when the decision procedure needs a concrete form.

## Control-flow narrowing

Union input, `typeof`, early return — the remaining path narrows automatically:

```ts
function label(value: string | number): string {
  if (typeof value === "number") {
    return value.toFixed(2);
  }
  return value.toUpperCase();
}
```

After the early return, `value` is `string` with no cast.

## Truthiness vs explicit check

`!!value` removes valid falsey values. Prefer an explicit check when definedness is the real requirement:

```ts
function formatCount(count: number | undefined): string {
  if (count !== undefined) {
    return String(count); // keeps 0
  }
  return "n/a";
}
```

```ts
function formatCount(count: number | undefined): string {
  if (count) {
    return String(count); // drops 0
  }
  return "n/a";
}
```

Use truthiness only when "usable / non-empty" is the intended meaning.

## Property-presence narrowing

`in` proves presence. When the property is optional on more than one member, presence alone may not uniquely identify which member you have:

```ts
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "rect"; width: number; height?: number };

function area(shape: Shape): number {
  if ("radius" in shape) {
    return Math.PI * shape.radius ** 2;
  }
  return shape.width * (shape.height ?? shape.width);
}
```

Here `radius` uniquely distinguishes the circle. Contrast a weaker case:

```ts
type Packet =
  | { id: string; payload?: string }
  | { id: string; error?: string };

function describe(packet: Packet): string {
  if ("payload" in packet) {
    // Still Packet — both members may have optional keys; presence is not identity
    return packet.payload ?? "";
  }
  return "";
}
```

Do not treat `"prop" in value` as exclusive membership when `prop` is optional across members.

## Semantic reusable guard

Application code should call a named domain guard; structural validation lives inside:

```ts
type ApiError = { code: string; message: string };

function isApiError(error: unknown): error is ApiError {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    "message" in error &&
    typeof (error as { code: unknown }).code === "string" &&
    typeof (error as { message: unknown }).message === "string"
  );
}

function handleFailure(error: unknown): void {
  if (isApiError(error)) {
    showError(error.message);
  }
}
```

Do not repeat the nested structural checks at every call site.

## Unsound predicate

A predicate must justify both branches of `value is T`. This one returns the right answer for common inputs but lies about the false branch:

```ts
type User = { id: string; name: string };

// Unsound: returns false for { id, name } when name is "", but claims "not User"
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "name" in value &&
    typeof (value as { name: unknown }).name === "string" &&
    Boolean((value as { name: string }).name)
  );
}

function greet(value: unknown): string {
  if (isUser(value)) {
    return value.name;
  }
  // TypeScript treats value as not User — but a real User with name "" was rejected
  return "guest";
}
```

If `name: ""` is a valid `User`, the false branch is a lie. Drop the truthiness check, or claim a narrower type that matches the runtime rule.

## Inferred predicate

Modern TypeScript can infer a predicate from a simple boolean return. An explicit `value is T` is unnecessary when inference already matches:

```ts
function isString(value: unknown) {
  return typeof value === "string";
}

function upper(value: unknown): string {
  if (isString(value)) {
    return value.toUpperCase();
  }
  return "";
}
```

Add `value is string` only when you need an explicit contract that inference does not already provide, and the implementation still justifies both branches.

## Narrowing invalidated by mutation

Narrowing depends on the value remaining stable. Mutation after a check can make the observed type stale:

```ts
function readId(items: Array<{ id?: string }>): string {
  const item = items[0];
  if (item && typeof item.id === "string") {
    items[0] = { id: undefined }; // mutates the source
    return item.id; // type says string; runtime may no longer match the model you assumed
  }
  return "";
}
```

Re-check after mutation, or narrow a `const` local that you do not reassign and that does not alias mutable shared state you change afterward.
