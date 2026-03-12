# Stage 3 Runbook

The assignment asks for two isolated namespaces with simple workloads and NetworkPolicies, plus proof that same-namespace traffic is allowed and cross-namespace traffic is blocked.

## What Terraform does

Terraform uploads these files to the VM after it is created:

- `/opt/k8s-tf-azure/kubernetes/stage3/00-namespaces.yaml`
- `/opt/k8s-tf-azure/kubernetes/stage3/10-app1.yaml`
- `/opt/k8s-tf-azure/kubernetes/stage3/20-app2.yaml`
- `/opt/k8s-tf-azure/kubernetes/stage3/30-network-policies.yaml`
- `/opt/k8s-tf-azure/scripts/stage3-apply.sh`
- `/opt/k8s-tf-azure/scripts/stage3-verify.sh`

It does **not** run them automatically. This keeps Stage 3 explicit and easy to demonstrate.

## What to run on the VM

SSH into the VM:

```bash
ssh -i "<private-key-path>" azureuser@<public-ip>
```

Apply the Stage 3 resources:

```bash
/opt/k8s-tf-azure/scripts/stage3-apply.sh
```

Then run the verification script:

```bash
/opt/k8s-tf-azure/scripts/stage3-verify.sh
```

## Expected proofs

```bash
kubectl get all -n app1 -o wide
kubectl get all -n app2 -o wide
kubectl get networkpolicy -n app1 -o yaml
kubectl get networkpolicy -n app2 -o yaml
```

The verification script also checks:

- same-namespace traffic is allowed
- cross-namespace traffic is blocked

Proof files are written to:

```bash
~/stage3-proof
```

## NetworkPolicies explanation for submission

Each namespace has a NetworkPolicy that selects all pods in that namespace and allows ingress only from pods in the same namespace.

This means:

- traffic inside `app1` is allowed
- traffic inside `app2` is allowed
- traffic from `app1` to `app2` is blocked
- traffic from `app2` to `app1` is blocked
