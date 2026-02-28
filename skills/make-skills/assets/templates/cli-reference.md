---
name: using-TOOLNAME
description: >-
  Execute TOOLNAME commands for [primary use cases].
  Use when [trigger phrases], working with [file types/contexts],
  or managing [domain objects].
---

# TOOLNAME Reference

## Authentication

```bash
# Login / configure credentials
TOOLNAME auth login
TOOLNAME config set KEY VALUE
```

## Core Operations

### Create

```bash
TOOLNAME create RESOURCE --flag value
```

### Read / List

```bash
TOOLNAME list RESOURCES
TOOLNAME get RESOURCE_ID
TOOLNAME describe RESOURCE_ID --format json
```

### Update

```bash
TOOLNAME update RESOURCE_ID --flag new-value
```

### Delete

```bash
TOOLNAME delete RESOURCE_ID [--force]
```

## Common Workflows

### Workflow: [Name]

```bash
# Step 1: [Description]
TOOLNAME command-1

# Step 2: [Description]
TOOLNAME command-2

# Step 3: [Description]
TOOLNAME command-3
```

### Workflow: [Name]

```bash
# [Multi-step recipe]
```

## Flags Reference

| Flag | Short | Description |
|------|-------|-------------|
| `--output` | `-o` | Output format (json, yaml, table) |
| `--quiet` | `-q` | Suppress non-essential output |
| `--verbose` | `-v` | Enable detailed logging |

## Error Recovery

| Error | Cause | Fix |
|-------|-------|-----|
| `AUTH_FAILED` | Expired credentials | Run `TOOLNAME auth login` |
| `NOT_FOUND` | Resource doesn't exist | Verify ID with `TOOLNAME list` |
| `PERMISSION_DENIED` | Insufficient access | Check role assignments |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `TOOLNAME_CONFIG` | Config file path |
| `TOOLNAME_TOKEN` | Auth token override |
