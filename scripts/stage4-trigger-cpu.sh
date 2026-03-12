#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

NAMESPACE="${NAMESPACE:-monitoring}"

echo "== Recreate CPU burner workload =="
kubectl delete deployment cpu-burner -n "${NAMESPACE}" --ignore-not-found=true

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-burner
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-burner
  template:
    metadata:
      labels:
        app: cpu-burner
    spec:
      containers:
        - name: burner
          image: busybox:1.36
          command: ["/bin/sh", "-c"]
          args:
            - |
              i=0
              while [ "$i" -lt 4 ]; do
                yes > /dev/null &
                i=$((i+1))
              done
              wait
          resources:
            requests:
              cpu: "500m"
            limits:
              cpu: "2000m"
EOF

kubectl rollout status deployment/cpu-burner -n "${NAMESPACE}" --timeout=180s

echo "CPU burner is running."
echo "Leave it running until the alert fires, then delete it with:"
echo "kubectl delete deployment cpu-burner -n ${NAMESPACE}"