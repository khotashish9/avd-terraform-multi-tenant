# Customer onboarding checklist

## Before deployment
- [ ] Confirm customer tenant, subscription ID, region, and billing ownership.
- [ ] Agree resource naming, tags, environment, and cost center.
- [ ] Confirm user identity model: AD DS or Entra ID join. This package's join extension supports AD DS.
- [ ] Confirm VNet address space does not overlap with on-premises/customer networks.
- [ ] Confirm DNS, routing, firewall, and private connectivity to domain controllers and profile storage.
- [ ] Confirm Windows multi-session image availability and licensing.
- [ ] Size session hosts using concurrency, workload, and performance requirements.
- [ ] Design FSLogix profile storage, identity integration, permissions, private connectivity, backup, and DR.
- [ ] Confirm required applications, image customization, patching, and endpoint protection.
- [ ] Create a unique backend state key and secure deployment identity.

## Deployment
- [ ] Create client `.tfvars` and backend `.hcl`.
- [ ] Supply VM and (if applicable) domain-join credentials from a secret store.
- [ ] Review Terraform plan with customer.
- [ ] Apply and verify VM extensions and AVD registration.
- [ ] Assign users/groups to the desktop application group (not automated by this starter).
- [ ] Configure FSLogix and test profile creation, sign-in, reconnect, and sign-out.
- [ ] Validate monitoring, backup, security baseline, and cost reporting.

## Handover
- [ ] Document host pool, workspace, app group, VM sizing, subnet, DNS, and support contacts.
- [ ] Document image update and rollback process.
- [ ] Document credential rotation and state access.
- [ ] Provide customer with operational runbook and escalation path.
