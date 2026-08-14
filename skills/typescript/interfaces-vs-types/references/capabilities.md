# Capabilities — Types vs Interfaces

Companion to [`interfaces-vs-types`](../SKILL.md). Load when you need a quick capability check. Nuanced — don't get hung up; prefer **use interface until you need type**.

| Aspect                                          | Type | Interface |
| ----------------------------------------------- | ---- | --------- |
| Can describe functions                          | ✅   | ✅        |
| Can describe constructors                       | ✅   | ✅        |
| Can describe tuples                             | ✅   | ✅        |
| Interfaces can extend it                        | ⚠️   | ✅        |
| Classes can extend it                           | 🚫   | ✅        |
| Classes can implement it (`implements`)         | ⚠️   | ✅        |
| Can intersect another one of its kind           | ✅   | ⚠️        |
| Can create a union with another one of its kind | ✅   | 🚫        |
| Can be used to create mapped types              | ✅   | 🚫        |
| Can be mapped over with mapped types            | ✅   | ✅        |
| Expands in error messages and logs              | ✅   | 🚫        |
| Can be augmented                                | 🚫   | ✅        |
| Can be recursive                                | ⚠️   | ✅        |

⚠️ In some cases.
