# Charts Guide

This directory contains the Helm charts for all managed services.

## Naming Convention

The **Helm Chart Name** must match the system-wide service name exactly.
This ensures consistency across:
*   RGD Name (`definitions/<service>.yaml`)
*   Software Template Name (`software-templates/<service>/template.yaml`)
*   Helm Chart Name (`charts/<service>/Chart.yaml`)

## Dependencies

### The `lib` Chart
**Every chart MUST include the `lib` chart as a dependency.**
The `lib` chart contains global configurations, shared manifests, and common logic required by all managed services.


## Composite Services

If a service is a combination of multiple managed services (e.g., a "LAMP Stack" combining Linux, Apache, MySQL, PHP):

*   **Do not use Helm sub-chart dependencies** for the managed components.
*   **Instead, use the Managed Service Resources**.
    *   Your chart's `templates/` should include the Custom Resources (CRs) for the constituent services (instances of their RGDs).
    *   For example, to include a Postgres database, define a `kind: Postgres` resource in your templates, rather than depending on the `postgres` chart directly.

This ensures that all components are governed by their respective Resource Graph Definitions (RGDs), maintaining consistent platform policies and lifecycle management.
