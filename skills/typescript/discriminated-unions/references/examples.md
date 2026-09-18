# Examples — Discriminated Unions

Companion to [`discriminated-unions`](../SKILL.md). Load when the decision procedure needs a concrete form.

## Bad: one object with conditional optionals

A single request type allows impossible combinations (`data` and `error` together, or neither when "ready"):

```ts
type RequestState = {
  status: "idle" | "loading" | "success" | "error";
  data?: User;
  error?: string;
};

function userName(state: RequestState): string {
  if (state.status === "success") {
    return state.data!.name;
  }
  return "";
}
```

`data!` papers over a model that still permits `{ status: "success" }` with no `data`.

## Good: one member per valid variant

```ts
type RequestState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: User }
  | { status: "error"; error: string };
```

`status: "success"` without `data` is not representable. No `!` required after narrowing.

## Narrowing unlocks the payload

```ts
function userName(state: RequestState): string {
  if (state.status === "success") {
    return state.data.name;
  }
  return "";
}

function describe(state: RequestState): string {
  switch (state.status) {
    case "idle":
      return "idle";
    case "loading":
      return "loading";
    case "success":
      return state.data.name;
    case "error":
      return state.error;
  }
}
```

After checking `status`, TypeScript knows the full member — variant fields are ordinary required properties on that branch.

## Exhaustive handling with `never`

When every variant must be covered, assign the remainder to `never`. A new member then fails to compile:

```ts
function assertNever(value: never): never {
  throw new Error(`Unhandled: ${JSON.stringify(value)}`);
}

function describe(state: RequestState): string {
  switch (state.status) {
    case "idle":
      return "idle";
    case "loading":
      return "loading";
    case "success":
      return state.data.name;
    case "error":
      return state.error;
    default:
      return assertNever(state);
  }
}

// Later:
// type RequestState = ... | { status: "cancelled" };
// Error in default: { status: "cancelled" } is not assignable to never
```

Use a plain `default` fallback instead when unknown/future variants are intentionally accepted — do not force `never` in that case.
