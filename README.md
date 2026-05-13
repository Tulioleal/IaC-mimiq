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

This repository does not provision RunPod pods. GPU provider lifecycle is owned by the backend, which receives RunPod configuration and secrets at runtime. The XTTS project only publishes the worker image consumed by RunPod.

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

The backend owns RunPod pod lifecycle for TTS. Configure these backend values for production:

```hcl
backend_env = {
  TTS_PROVIDER               = "runpod"
  RUNPOD_API_URL             = "https://rest.runpod.io/v1"
  RUNPOD_POD_NAME            = "pvc-xtts"
  RUNPOD_IMAGE_NAME          = "<dockerhub-user>/pvc-tts:latest"
  RUNPOD_GPU_TYPE_IDS        = "NVIDIA RTX 4090,NVIDIA RTX 3090,NVIDIA RTX A5000,NVIDIA A40"
  RUNPOD_GPU_TYPE_PRIORITY   = "availability"
  RUNPOD_MIN_RAM_PER_GPU     = "16"
  RUNPOD_MIN_VCPU_PER_GPU    = "4"
  RUNPOD_VOLUME_GB           = "40"
  RUNPOD_CONTAINER_DISK_GB   = "50"
  RUNPOD_PORTS               = "8000/http"
  RUNPOD_INTERRUPTIBLE       = "true"
  RUNPOD_START_RETRY_SECONDS = "300"
  RUNPOD_SHUTDOWN_ACTION     = "delete"
  TTS_IDLE_TIMEOUT_SECONDS   = "1800"
  BACKEND_URL                = "https://api.example.com"
  BACKEND_WS_URL             = "wss://api.example.com/internal/tts-worker/ws"
}

backend_secret_env = {
  RUNPOD_API_KEY  = "replace-me"
  INTERNAL_SECRET = "replace-me"
}
```

`RUNPOD_API_KEY` is a backend secret because the backend creates, monitors, and deletes idle RunPod pods. With the current VM startup-script approach, values in `backend_secret_env` are sensitive in OpenTofu output but still become part of OpenTofu state and Compute Engine instance metadata. Use an out-of-band secret injection path before adding the key here if storing it in state is not acceptable.

RunPod workers must call back to the backend over public HTTPS/WSS routes, including `/internal/tts-worker/ws`, `/internal/jobs/{job_id}/speaker.wav`, `/internal/jobs/{job_id}/result`, and `/internal/tts-offline`. Set public callback URLs in `backend_env` so the VM startup script exports reachable URLs to the backend container:

```hcl
backend_env = {
  BACKEND_URL    = "https://api.example.com"
  BACKEND_WS_URL = "wss://api.example.com/internal/tts-worker/ws"
}
```

If `BACKEND_WS_URL` is omitted, the compute module derives it from `BACKEND_URL`:

```text
BACKEND_URL=https://api.example.com
BACKEND_WS_URL=wss://api.example.com/internal/tts-worker/ws
```

For compatibility with older tfvars, `BACKEND_PUBLIC_URL` is still accepted as the callback base URL when `BACKEND_URL` is not set. If both are empty, the module falls back to VM-IP URLs for simple non-TLS deployments:

```text
BACKEND_URL=http://<backend_external_ip>:<backend_service_port>
BACKEND_WS_URL=ws://<backend_external_ip>:<backend_service_port>/internal/tts-worker/ws
```

Because RunPod egress IPs can vary, production ingress cannot usually rely on a stable RunPod CIDR allowlist. If exposing the backend app port broadly with `allowed_app_cidrs = ["0.0.0.0/0"]`, protect internal routes with HTTPS/WSS, `INTERNAL_SECRET`, and backend authentication middleware.

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
- Infra does not create RunPod pods. The backend owns RunPod pod lifecycle and deletes idle pods according to `TTS_IDLE_TIMEOUT_SECONDS` and `RUNPOD_SHUTDOWN_ACTION`.
- The XTTS project only publishes the worker image referenced by `RUNPOD_IMAGE_NAME`.
- `frontend_enabled` controls whether Cloud Run is created. The Artifact Registry repository is always created for frontend images.
- `frontend_public` grants `allUsers` the Cloud Run invoker role when public frontend access is desired.
- `frontend_backend_api_base_url` and `frontend_public_ws_base_url` let operators inject HTTPS/WSS production domains into the frontend without rebuilding the Docker image. If left empty, OpenTofu derives HTTP/WS URLs from the backend VM external IP.
- `BACKEND_URL` and `BACKEND_WS_URL` let operators inject the HTTPS/WSS production backend callback URLs used by RunPod workers. If left empty, OpenTofu derives HTTP/WS backend callback URLs from the backend VM external IP.
- `BACKEND_PUBLIC_URL` remains supported as a callback base URL for older tfvars, but new configuration should use `BACKEND_URL` and `BACKEND_WS_URL`.
- Browser WebSockets from an HTTPS frontend require `wss://`; the derived `ws://<ip>:<port>` value is only suitable for early non-TLS testing.
- Bucket names must be globally unique in GCS. `bucket_name_prefix` should therefore be organization-specific.
