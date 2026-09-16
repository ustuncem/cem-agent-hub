# Examples — Literal Types and `as const`

Companion to [`literal-types-and-as-const`](../SKILL.md). Load when the decision procedure needs a concrete form.

## `const` vs `let` literal inference

A `const` binding initialized with a string literal keeps the literal type. A `let` binding widens:

```ts
const method = "GET";
// "GET"

let methodLet = "GET";
// string
```

## Object property widening and `as const`

`const` on the object does not keep property literals. Properties still widen, so a function that requires `"GET" | "POST"` rejects `req.method`:

```ts
function handleRequest(url: string, method: "GET" | "POST") {
  /* ... */
}

const req = { url: "https://example.com", method: "GET" };
// method: string

handleRequest(req.url, req.method);
// Error: string is not assignable to "GET" | "POST"
```

Preserve literals at the source:

```ts
const req = { url: "https://example.com", method: "GET" } as const;
// method: "GET"

handleRequest(req.url, req.method);
```

Prefer that over asserting at the call site:

```ts
handleRequest(req.url, req.method as "GET");
```

## Readonly tuple vs a mutable API

`as const` on an array makes a readonly tuple. APIs that take mutable `T[]` reject it:

```ts
function pushId(ids: string[], id: string) {
  ids.push(id);
}

const seed = ["a", "b"] as const;
// readonly ["a", "b"]

pushId(seed, "c");
// Error: readonly tuple is not assignable to string[]
```

When the API needs mutability, leave the array widened (or copy into a mutable array at the boundary):

```ts
const seed = ["a", "b"];
// string[]

pushId(seed, "c");
```

## Referenced mutable data stays mutable

`as const` makes the *containing* properties readonly in the type. It does not freeze a mutable value that was only referenced:

```ts
const arr = [1, 2, 3, 4];

const foo = {
  name: "foo",
  contents: arr,
} as const;

// foo.name = "bar";     // error — readonly
// foo.contents = [];    // error — readonly
foo.contents.push(5); // allowed — arr is still a mutable number[]
```

`as const` is not runtime immutability and not a deep freeze of shared references.
