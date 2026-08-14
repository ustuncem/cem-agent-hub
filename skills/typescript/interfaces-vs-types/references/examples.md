# Examples — Interfaces vs Types

Companion to [`interfaces-vs-types`](../SKILL.md). Load when the decision procedure needs a concrete form.

## Object contracts

Prefer `interface` for named object structures:

```ts
interface User {
  id: string;
  name: string;
}
```

A simple object type alias is still valid — leave it when editing unless composition, implementation, augmentation, or local convention requires a change:

```ts
type User = {
  id: string;
  name: string;
};
```

Prefer `interface` when the object will be extended, implemented by a class, exposed as an augmentable public API, or composed from multiple object contracts.

## Object composition

Prefer interface inheritance over intersection-based object composition when every participant is an ordinary object structure:

```ts
interface Entity extends Identifiable, Timestamped {
  name: string;
}
```

Reserve this form for cases where `&` is required (e.g. mixing with non-object type-level forms):

```ts
type Entity = Identifiable &
  Timestamped & {
    name: string;
  };
```

## Unions and discriminated unions

```ts
type RequestState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error };
```

Model mutually exclusive states as a discriminated union, not as one interface with optional fields tied to `status`.

## Type transformations

```ts
type UserPatch = Partial<Pick<User, "name" | "email">>;

type ApiResult<T> = T extends Error
  ? { success: false; error: T }
  : { success: true; data: T };
```

Name complex calculated types when reused:

```ts
type ResultFor<T> = T extends UserInput
  ? User
  : T extends ProductInput
    ? Product
    : unknown;

interface Repository {
  find<T>(input: T): ResultFor<T>;
}
```

## Tuples, primitives, functions, branded types

```ts
type Coordinates = [number, number];

type UserId = string & {
  readonly __brand: "UserId";
};

type EventHandler<T> = (event: T) => void;
```

## React component props

Extending an object contract:

```ts
interface ButtonProps extends BaseButtonProps {
  loading?: boolean;
}
```

Mutually exclusive variants:

```ts
type ButtonProps =
  | {
      variant: "link";
      href: string;
      onPress?: never;
    }
  | {
      variant: "action";
      onPress: () => void;
      href?: never;
    };
```

## Declaration merging

Use when merging is intentional:

```ts
interface Window {
  analytics: AnalyticsClient;
}
```

Use a type alias when the contract should stay closed to declaration merging. Closed-to-merging is not exactness — TypeScript remains structurally typed.
