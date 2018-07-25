# Microeconometrics.jl

This package provides support for microeconometric estimation. It supports complex weighted data and covariance structures (e.g., clustered). Please report bugs by [opening an issue](https://github.com/lbittarello/Microeconometrics.jl/issues/new). Information about specific versions can be found on the [release page](https://github.com/lbittarello/Microeconometrics.jl/releases).

## Supported estimators

More models are planned. If your preferred model is not currently available, [file an issue](https://github.com/lbittarello/Microeconometrics.jl/issues/new) or [contribute](#contributing)!

- [Linear regression](estimators.md#linear-regression)
    - Ordinary least squares
    - Linear IV (two-stage least squares and GMM)
- [Binary choice](estimators.md#binary-choice)
    - Logit
    - Probit
    - Complementary log-log
- [Count data](estimators.md#count-data)
    - Poisson
    - IV Poisson with additive errors
    - IV Poisson with multiplicative errors
- [Reweighting methods](estimators.md#reweighting-methods)
    - Inverse probability weighting
    - Abadie (2003)
    - Frölich and Melly (2013)
    - Tan (2006)

## Package manual

```@contents
Pages = [
        "getting_started.md",
        "model_specification.md",
        "correlation_structures.md",
        "estimators.md",
        "methods.md",
        "bootstrapping.md",
        "contributing.md",
        "to_do.md",
    ]
Depth = 2
```