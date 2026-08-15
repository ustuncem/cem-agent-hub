# Examples — Optional vs Undefined

Companion to [`optional-vs-undefined`](../SKILL.md). Load when the decision procedure needs a concrete form.

## The two shapes

```ts
interface OptionalFoo {
  foo?: string;
}

interface PresentFoo {
  foo: string | undefined;
}
```

`OptionalFoo` may omit `foo`. `PresentFoo` must include the key.

```ts
const absent: OptionalFoo = {};
const present: PresentFoo = { foo: undefined };
```

Reading both still yields `string | undefined`. The difference is whether the key exists.

## Object construction

Omit the key only when the property is optional:

```ts
const ok: OptionalFoo = {};
const alsoOk: OptionalFoo = { foo: "hi" };
```

A required `| undefined` property cannot be left off:

```ts
const missing: PresentFoo = {};
// Property 'foo' is missing in type '{}' but required in type 'PresentFoo'.

const cleared: PresentFoo = { foo: undefined };
const set: PresentFoo = { foo: "hi" };
```

Without `exactOptionalPropertyTypes`, `{ foo: undefined }` is also assignable to `OptionalFoo`. That assignment is the default-settings hole; see below.

## Function parameters

An optional parameter may be omitted. A required `T | undefined` parameter must be passed:

```ts
function optionalName(name?: string) {}
optionalName();
optionalName("Ada");
optionalName(undefined);

function presentName(name: string | undefined) {}
presentName();
// Expected 1 arguments, but got 0.
presentName("Ada");
presentName(undefined);
```

Same rule for object parameters: optional fields may be dropped from the argument object; required `| undefined` fields must still appear.

```ts
function patchUser(fields: { nickname?: string }) {}
patchUser({});

function clearNickname(fields: { nickname: string | undefined }) {}
clearNickname({ nickname: undefined });
```

## Property existence checks

`=== undefined` cannot tell missing from present-`undefined`:

```ts
const optional: OptionalFoo = {};
const present: PresentFoo = { foo: undefined };

optional.foo === undefined; // true
present.foo === undefined; // true
```

Use `"foo" in obj` or `Object.hasOwn` when the key itself matters:

```ts
"foo" in optional; // false
"foo" in present; // true

Object.hasOwn(optional, "foo"); // false
Object.hasOwn(present, "foo"); // true
```

Optional chaining and defaults also collapse both states: `obj.foo ?? fallback` and `{ foo = fallback } = obj` treat missing and `undefined` the same.

## `exactOptionalPropertyTypes`

With the flag on, optional no longer accepts an explicit `undefined` unless you write `| undefined`:

```ts
const settings: { theme?: "dark" | "light" } = {
  theme: undefined,
};
// Type 'undefined' is not assignable to type '"dark" | "light"'.
```

Allow both absence and explicit `undefined` only when that is the model:

```ts
const settings: { theme?: "dark" | "light" | undefined } = {
  theme: undefined,
};
```

The flag also blocks assigning a required `| undefined` object into an optional one (the source can hold `undefined`), and assigning an optional object into a required `| undefined` one (the source can omit the key).

Reading an optional property is still `T | undefined`. The flag tightens writes and assignability, not reads.

## Intentional modeling

Absence is meaningful — omit means "not provided" / "leave unchanged":

```ts
interface UserPatch {
  nickname?: string;
}
```

The key should always exist — `undefined` means "cleared" / "no value yet":

```ts
interface UserRecord {
  nickname: string | undefined;
}
```

Do not write `nickname?: string | undefined` unless missing and explicit `undefined` are both valid and you will distinguish them with `"nickname" in obj`.

When the meaning is unclear, ask before typing the field. Do not default to `?` or `| undefined`:

```
Should `nickname` be omitted when unset (`nickname?: string`), always present
with a possibly undefined value (`nickname: string | undefined`), or both
(`nickname?: string | undefined`)?
```
