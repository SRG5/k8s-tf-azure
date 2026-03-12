# Stage 4 Runbook

The assignment asks for `kube-prometheus-stack` to be installed with Helm, Grafana to be exposed through NodePort, access to Grafana to be restricted to the operator IP through the VM NSG, and proof that a high CPU alert fired in both Prometheus/Alertmanager and Grafana.

## What Terraform does

Terraform performs two tasks for Stage 4:

- updates the NSG to allow inbound access to Grafana NodePort **only** from the operator IP
- uploads these files to the VM:
  - `/opt/k8s-tf-azure/observability/stage4/values.yaml`
  - `/opt/k8s-tf-azure/observability/stage4/node-high-cpu-alert.yaml`
  - `/opt/k8s-tf-azure/scripts/stage4-apply.sh`
  - `/opt/k8s-tf-azure/scripts/stage4-trigger-cpu.sh`
  - `/opt/k8s-tf-azure/scripts/stage4-verify.sh`

Terraform does **not** run Helm or `kubectl` automatically. This keeps Stage 4 explicit and easy to demonstrate.

## What to run on the VM

SSH into the VM:

```bash
ssh -i "<private-key-path>" azureuser@<public-ip>
```

Install the monitoring stack and apply the custom alert rule:

```bash
/opt/k8s-tf-azure/scripts/stage4-apply.sh
```

Trigger CPU load:

```bash
/opt/k8s-tf-azure/scripts/stage4-trigger-cpu.sh
```

Verify that the alert fired in Prometheus and Alertmanager:

```bash
/opt/k8s-tf-azure/scripts/stage4-verify.sh
```

## Expected proofs

```bash
kubectl get pods -n monitoring -o wide
kubectl get svc -n monitoring -o wide
kubectl get prometheusrule -n monitoring -o yaml
```

The verification script also confirms:

- Prometheus sees `Stage4NodeHighCPU` in `firing` state
- Alertmanager sees `Stage4NodeHighCPU`
- Grafana is exposed on NodePort `32000`

Proof files are written to:

```bash
~/stage4-proof
```

A small Grafana screenshot should also be saved in the repository showing:

- `Stage4NodeHighCPU`
- state = `Firing`

## Grafana / NSG explanation for submission

Grafana is exposed with a Kubernetes `NodePort` service on port `32000`.

Access is restricted at the Azure NSG level with an inbound rule that allows TCP `32000` **only** from the operator public IP CIDR. This keeps Grafana reachable for validation while preventing open access from the internet.
