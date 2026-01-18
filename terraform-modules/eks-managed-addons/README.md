# EKS Managed Add-ons Module

Terraform module for installing and managing Amazon EKS managed add-ons.

## Features

- Installs EKS managed add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI Driver)
- Configurable add-on versions
- IRSA support for add-ons that require IAM permissions
- Automatic add-on version selection (most_recent)

## Usage

```hcl
module "eks_addons" {
  source = "./terraform-modules/eks-managed-addons"
  
  create          = true
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version
  
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Kubernetes"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create | Controls if EKS add-ons should be created | bool | true | no |
| cluster_name | Name of the EKS cluster | string | - | yes |
| cluster_version | Kubernetes version of the EKS cluster | string | - | yes |
| cluster_addons | Map of cluster add-on configurations | map(object) | {} | no |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Supported Add-ons

### CoreDNS
- DNS service for the Kubernetes cluster
- Required for service discovery
- No IRSA required

### kube-proxy
- Network proxy for the Kubernetes cluster
- Required for service networking
- No IRSA required

### VPC CNI
- Networking plugin for pod networking in EKS
- Required for pod-to-pod communication
- No IRSA required

### EBS CSI Driver
- Storage driver for EBS volumes
- Required for persistent volumes
- **IRSA required** - must provide `service_account_role_arn`

## Outputs

| Name | Description |
|------|-------------|
| addons | Map of add-on attributes |

## Prerequisites

- EKS cluster must exist and be in an active state
- Node groups should be created before installing add-ons
- For EBS CSI Driver, IRSA role must be created and provided

## Notes

- Add-ons are automatically updated when `most_recent = true`
- EBS CSI Driver requires an IRSA role with `AmazonEBSCSIDriverPolicy`
- Add-ons are installed in the `kube-system` namespace
- Some add-ons may take a few minutes to become ready after installation
- CoreDNS and kube-proxy are essential and should always be installed

