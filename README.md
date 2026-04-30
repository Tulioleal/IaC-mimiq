# PVC Infrastructure

OpenTofu configuration for the PVC GCP foundation lives here.

This stack provisions:

- A versioned GCS bucket for remote OpenTofu state bootstrap
- GitHub Actions Workload Identity Federation for keyless OpenTofu applies
- Optional frontend GitHub Actions identity for pushing frontend Docker images
- Required GCP API enablement for compute, SQL, storage, Artifact Registry, Cloud Run, logging, and monitoring
- A dedicated VPC, subnet, and firewall rules for the backend VM
- Private service networking for Cloud SQL private IP connectivity
- A Compute Engine VM for the FastAPI backend with a Docker startup script
- A private Cloud SQL for PostgreSQL instance, database, and application user
- Two GCS buckets for voice samples and generated outputs with lifecycle policies
- An Artifact Registry Docker repository for frontend images
- An optional Cloud Run service for the Next.js frontend

This repository does not provision Vast.ai GPU instances. GPU startup remains part of the backend and TTS GitHub Actions control path described in the PRD.

## Layout

```text
infra/
├── .github/
│   └── workflows/
│       └── apply.yml         # Applies the prod stack from GitHub Actions
├── bootstrap/               # One-time state bucket bootstrap (local state)
├── environments/
│   └── prod/                # Production stack using the GCS remote backend
└── modules/
    ├── compute/
    ├── database/
    ├── frontend-cloud-run/
    ├── network/
    └── storage/
```

## Bootstrap Resources

The bootstrap stack creates resources needed before production can use remote state or GitHub OIDC:

- GCS state bucket with versioning, uniform bucket-level access, public access prevention, and `prevent_destroy`
- GitHub Actions service account for OpenTofu CI
- Workload Identity Pool and provider restricted to the configured GitHub repository and ref
- IAM access for the CI account to manage state and provision the production stack
- Optional frontend CI service account and OIDC provider when `frontend_github_repository` is configured

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

1. Copy `environments/prod/terraform.tfvars.example` to `environments/prod/terraform.tfvars` and fill it in.
2. Initialize the prod stack with the bucket created in the bootstrap step:

```bash
cd infra/environments/prod
tofu init -backend-config="bucket=<your-state-bucket-name>"
tofu plan
tofu apply
```

The prod backend is intentionally configured with a partial `gcs` backend block so the bucket name is supplied at init time instead of hardcoded in VCS.

## Production Resources

The production environment enables required GCP APIs and composes the modules below.

| Module | Resources |
|---|---|
| `network` | Custom VPC, regional subnet, private service networking allocation/peering, SSH firewall, optional app firewall |
| `storage` | `<bucket_name_prefix>-samples` and `<bucket_name_prefix>-outputs` buckets with delete lifecycle rules |
| `frontend-cloud-run` | Artifact Registry Docker repository and optional Cloud Run frontend service |
| `database` | Private Cloud SQL PostgreSQL instance, application database, application user, backups, point-in-time recovery, Query Insights |
| `compute` | Backend VM, backend service account, Docker startup script, optional backend container systemd service |

The backend VM receives environment variables for database connectivity, GCP project/region, and the samples/outputs buckets. Additional non-sensitive values come from `backend_env`; sensitive values come from `backend_secret_env`.

The frontend Cloud Run service receives backend connection settings at runtime. By default, OpenTofu derives them from the backend VM external IP and `backend_service_port`:

```text
BACKEND_API_BASE_URL=http://<backend_external_ip>:<backend_service_port>
PUBLIC_WS_BASE_URL=ws://<backend_external_ip>:<backend_service_port>
```

For production, prefer explicit TLS-backed overrides instead of the derived VM IP URLs:

```hcl
frontend_backend_api_base_url = "https://api.example.com"
frontend_public_ws_base_url   = "wss://api.example.com"
```

These values are merged into `frontend_env`, so additional frontend runtime variables can still be supplied there. If `frontend_env` contains `BACKEND_API_BASE_URL` or `PUBLIC_WS_BASE_URL`, that explicit map value takes precedence.

## GitHub Actions Apply

`.github/workflows/apply.yml` runs on pushes to `main` that change Terraform/OpenTofu files or the workflow itself. It:

- Authenticates to GCP through Workload Identity Federation
- Runs `tofu fmt -check`, `tofu init`, `tofu validate`, `tofu plan`, and `tofu apply`
- Uses repository variables for project, region, zone, CIDR allowlists, image names, and the state bucket
- Uses repository secrets for database password and sensitive backend environment variables

## Notes

- `backend_container_image` is optional. If you leave it empty, the VM still installs Docker and writes the environment file, but it will not start a backend container yet.
- Database and application secrets can be injected through `backend_secret_env`. Those values are marked sensitive in OpenTofu, but they still become part of state and instance metadata because of the startup script approach. Moving secrets to Secret Manager is a sensible next hardening step.
- `frontend_enabled` controls whether Cloud Run is created. The Artifact Registry repository is always created for frontend images.
- `frontend_public` grants `allUsers` the Cloud Run invoker role when public frontend access is desired.
- `frontend_backend_api_base_url` and `frontend_public_ws_base_url` let operators inject HTTPS/WSS production domains into the frontend without rebuilding the Docker image. If left empty, OpenTofu derives HTTP/WS URLs from the backend VM external IP.
- Browser WebSockets from an HTTPS frontend require `wss://`; the derived `ws://<ip>:<port>` value is only suitable for early non-TLS testing.
- Bucket names must be globally unique in GCS. `bucket_name_prefix` should therefore be organization-specific.
