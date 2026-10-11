---
bc-version: [all]
domain: style
keywords: [namespace, using, BCGrokBot, flemmingbakkensen]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Put BCGrokBot objects in the FlemmingBakkensen.BCGrokBot namespace

## Description

Every object in the main app is declared in `FlemmingBakkensen.BCGrokBot` or a sub-namespace of it. Test app objects use `FlemmingBakkensen.BCGrokBot.Test`. CodeCop AA0247 only enforces that some namespace exists, so a wrong or copied namespace (for example one taken from a BCApps sample) still compiles.

## Best Practice

Start each file with `namespace FlemmingBakkensen.BCGrokBot[.<Area>];` and reference other objects with `using` statements.

## Anti Pattern

A namespace copied from Microsoft sources (`Microsoft.Sales.Document`, `System.Utilities`) or any namespace outside `FlemmingBakkensen.BCGrokBot`. Microsoft and System namespaces are reserved and PTE0021 rejects them.
