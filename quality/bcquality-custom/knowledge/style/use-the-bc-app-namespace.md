---
bc-version: [all]
domain: style
keywords: [namespace, using, bc-app, flemmingbakkensen]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Put bc-app objects in the FlemmingBakkensen.MyBCApp namespace

## Description

Every object in the main app is declared in `FlemmingBakkensen.MyBCApp` or a sub-namespace of it. Test app objects use `FlemmingBakkensen.MyBCApp.Test`. CodeCop AA0247 only enforces that some namespace exists, so a wrong or copied namespace (for example one taken from a BCApps sample) still compiles.

## Best Practice

Start each file with `namespace FlemmingBakkensen.MyBCApp[.<Area>];` and reference other objects with `using` statements.

## Anti Pattern

A namespace copied from Microsoft sources (`Microsoft.Sales.Document`, `System.Utilities`) or any namespace outside `FlemmingBakkensen.MyBCApp`. Microsoft and System namespaces are reserved and PTE0021 rejects them.
