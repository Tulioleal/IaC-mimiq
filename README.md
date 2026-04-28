# PVC Infrastructure

OpenTofu configuration for PVC lives here.

This stack provisions:

- A versioned GCS bucket for remote OpenTofu state bootstrap
- A dedicated VPC, subnet, and firewall rules for the backend VM
- A Compute Engine VM for the FastAPI backend with a Docker startup script
- A private Cloud SQL for PostgreSQL instance, database, and application user
- Two GCS buckets for voice samples and generated outputs with lifecycle policies

## Layout

```text
infra/
├── bootstrap/               # One-time state bucket bootstrap (local state)
├── environments/
│   └── prod/                # Production stack using the GCS remote backend
└── modules/
    ├── compute/
    ├── database/
    ├── network/
    └── storage/
```

## Bootstrap Remote State

The GCS backend bucket must exist before `tofu init` can use it, so the bootstrap stack is intentionally separate and uses local state.

1. Copy `bootstrap/terraform.tfvars.example` to `bootstrap/terraform.tfvars` and fill it in.
2. Run:

```bash
cd infra/bootstrap
tofu init
tofu apply
```

## Deploy Production

1. Copy `environments/prod/tofu.tfvars.example` to `environments/prod/tofu.tfvars` and fill it in.
2. Initialize the prod stack with the bucket created in the bootstrap step:

```bash
cd infra/environments/prod
tofu init -backend-config="bucket=<your-state-bucket-name>"
tofu plan
tofu apply
```

The prod backend is intentionally configured with a partial `gcs` backend block so the bucket name is supplied at init time instead of hardcoded in VCS.

## Notes

- `backend_container_image` is optional. If you leave it empty, the VM still installs Docker and writes the environment file, but it will not start a backend container yet.
- Database and application secrets can be injected through `backend_secret_env`. Those values are marked sensitive in OpenTofu, but they still become part of state and instance metadata because of the startup script approach. Moving secrets to Secret Manager is a sensible next hardening step.
- Bucket names must be globally unique in GCS. `bucket_name_prefix` should therefore be organization-specific.
