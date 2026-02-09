# Shared Backstage Template Steps

This directory contains reusable step definitions that can be referenced across multiple software templates.

## Usage

Reference these steps in your template.yaml using YAML anchors or by copying the step definition.

## Available Steps

- `fetch-template.yaml` - Scaffold files from a skeleton directory
- `kubernetes-apply.yaml` - Apply manifests to Kubernetes cluster
- `catalog-register.yaml` - Register resources in Backstage catalog
