# Reference architecture

```text
Customer users
     |
     v
Azure Virtual Desktop service
     |
     +---- Workspace
     |       |
     |       +---- Desktop Application Group
     |
     +---- Pooled Host Pool
               |
               +---- Session Host VM 01 (private IP)
               +---- Session Host VM 02 (private IP)
                         |
                         +---- Customer VNet / subnet / NSG
                         +---- AD DS DNS and domain controllers (optional)
                         +---- FSLogix profile storage (not provisioned here)
```

The same Terraform root configuration is deployed independently for each customer. Each deployment
uses its own subscription selection, variables, resource names, and remote state key. For stronger
isolation, use a dedicated subscription and deployment identity per customer.
