# Multi-client Azure Virtual Desktop (AVD) Terraform deployment

A reusable Terraform starter for deploying one AVD environment per customer from the same codebase.
Each customer gets its own `.tfvars` file and its own remote state key. The code does not create or
manage the customer's Azure tenant, identity platform, DNS, domain controllers, or Azure subscription.

## What it deploys

- Resource group (optional creation; can use an existing resource group)
- VNet, session-host subnet, and NSG (optional creation; can use an existing subnet)
- AVD pooled host pool
- AVD workspace and desktop application group, plus association
- Windows multi-session session-host VMs and NICs
- Optional AD DS domain join extension
- AVD agent and bootloader installation/registration using the host-pool registration token
- Boot diagnostics using a customer-provided storage account URI (optional)

## Multi-client operating model

Use this repository unchanged for every customer. Create a separate client configuration and
backend key for each deployment. Prefer a separate Azure subscription per customer where possible.

Example:
```text
clients/
  contoso.tfvars
  fabrikam.tfvars
backends/
  contoso.hcl
  fabrikam.hcl
```

Each backend file must use a unique `key`, for example `avd/contoso/prod.tfstate`.
The Azure Storage account/container used for state should be in a secured platform subscription,
with blob versioning, soft delete, private access, and RBAC restricted to the deployment identity.
Do not share state keys between clients.

## Prerequisites

- Terraform >= 1.6
- Azure CLI and an identity with permissions to create the listed resources
- AzureRM provider 4.x
- A customer subscription, region, naming convention, and network/IP plan
- For domain-joined hosts: reachable AD DS domain controllers, DNS configured to resolve the domain,
  and an account permitted to join computers to the target OU
- A pre-created remote state storage account and container

Authenticate:
```bash
az login
az account set --subscription "<CUSTOMER-SUBSCRIPTION-ID>"
az account show
```

## Deploy a client

1. Copy `clients/client-example.tfvars` to `clients/<client>.tfvars` and update all values.
2. Copy `backends/client-example.hcl` to `backends/<client>.hcl`; set a unique state key.
3. Initialize:
   ```bash
   terraform init -backend-config=backends/<client>.hcl
   ```
4. Validate and review:
   ```bash
   terraform fmt -recursive
   terraform validate
   terraform plan -var-file=clients/<client>.tfvars -out=<client>.tfplan
   ```
5. Apply:
   ```bash
   terraform apply <client>.tfplan
   ```
6. Record outputs and test sign-in, profile management, application access, and scaling.
7. For another customer, select that customer's subscription and use their `.tfvars` and backend file.

To switch customers, use a fresh working directory or re-run `terraform init -reconfigure` with the
other backend. Never point two customers at the same state key.

## Domain join and credentials

`domain_join_enabled = false` by default. For AD DS, set it to `true` and provide the domain,
OU path, and join account credentials through sensitive variables. Avoid putting passwords in
`.tfvars`, source control, shell history, or pipeline logs. Supply `domain_join_username` and
`domain_join_password` using `TF_VAR_...` environment variables or a secure pipeline secret store.

Example:
```bash
export TF_VAR_domain_join_username="DOMAIN\\svc-avd-join"
export TF_VAR_domain_join_password="<retrieve-from-secret-store>"
```

The domain-join extension and AVD registration process can leave sensitive values in Terraform
state or deployment logs depending on provider/extension behavior. Treat state as confidential,
restrict access, and use short-lived credentials where possible. Rotate any join credentials
according to customer policy.

## Important implementation notes

- This is a deployable baseline, not a complete enterprise AVD landing zone.
- The default marketplace image offer/SKU is configurable. Confirm that the selected image is
  available in the target region and licensed for the customer's use before deployment.
- The AVD agent installation uses Microsoft's `aka.ms` download endpoints. Confirm endpoint
  reachability through customer egress controls and validate the current supported installer
  behavior before production rollout.
- The default design creates a pooled host pool with breadth-first load balancing. It does not
  configure FSLogix profile storage. For production multi-user deployments, configure Azure Files
  or Azure NetApp Files with the appropriate identity integration, permissions, private endpoints,
  backup, and capacity planning.
- No public IPs are created for session hosts. Ensure private connectivity to domain controllers,
  profile storage, DNS, and required Microsoft service endpoints.
- VM sizing, host-pool capacity, image selection, FSLogix, Entra ID join, Intune, Defender, backup,
  monitoring alerts, autoscale, and application delivery should be tailored per customer.
- This package uses a local administrator password variable for VM provisioning. Supply it securely.
- Review the Terraform plan and all customer security requirements before applying.

## Teardown

Run `terraform destroy -var-file=clients/<client>.tfvars` only after confirming the customer has
approved removal and data/profile retention requirements have been met. The state backend is not
managed by this configuration and is not destroyed.

## Suggested production enhancements

1. Separate platform/state subscription from customer workload subscriptions.
2. Use workload identity federation or managed identity for CI/CD authentication.
3. Store state in a locked-down Storage Account with versioning and recovery controls.
4. Add FSLogix profile containers, Azure Files/ANF, private endpoints, and backup.
5. Add Azure Monitor diagnostics, Log Analytics, alert rules, and workbook dashboards.
6. Add autoscale schedules and image lifecycle management.
7. Implement customer-specific policy assignments, tagging, and cost budgets.
8. Consider Entra ID-joined session hosts where appropriate; this starter's optional join extension
   is for traditional AD DS domain join, not Entra ID join.
