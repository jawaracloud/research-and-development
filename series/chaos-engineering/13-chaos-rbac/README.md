# 13 — Chaos RBAC

> **Type:** How-To  
> **Phase:** Foundations

## Overview

LitmusChaos chaos experiments run as Kubernetes Jobs. They need specific RBAC permissions to list, delete, and watch pods, nodes, and other resources. This lesson explains the required roles and how to configure them correctly.

## LitmusChaos Service Accounts

LitmusChaos installs a `litmus-admin` ClusterRoleBinding for broad permissions. For production, you should use **scoped service accounts** per experiment type.

## Scoped RBAC for pod-delete

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-delete-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-delete-role
  namespace: default
rules:
  - apiGroups: [""]
    resources: [pods, pods/log, events, replicationcontrollers]
    verbs: [get, list, watch, delete]
  - apiGroups: [apps]
    resources: [deployments, replicasets, statefulsets, daemonsets]
    verbs: [get, list, watch]
  - apiGroups: [litmuschaos.io]
    resources: [chaosengines, chaosexperiments, chaosresults]
    verbs: [get, list, watch, create, patch, update]
  - apiGroups: [batch]
    resources: [jobs]
    verbs: [get, list, watch, create, delete]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-delete-rb
  namespace: default
subjects:
  - kind: ServiceAccount
    name: pod-delete-sa
roleRef:
  kind: Role
  name: pod-delete-role
  apiGroup: rbac.authorization.k8s.io
```

Apply and reference in the ChaosEngine:

```bash
kubectl apply -f chaos-rbac.yaml
```

```yaml
# In ChaosEngine:
spec:
  chaosServiceAccount: pod-delete-sa
```

## Scoped RBAC for node-level experiments

Node experiments require ClusterRole:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-chaos-role
rules:
  - apiGroups: [""]
    resources: [nodes]
    verbs: [get, list, watch, patch]
  - apiGroups: [""]
    resources: [pods]
    verbs: [get, list, watch, delete, create]
```

## Principle of Least Privilege

| Experiment | Scope | Resource Verbs Needed |
|------------|-------|----------------------|
| pod-delete | Namespaced | pods: delete |
| node-drain | Cluster | nodes: patch; pods: evict |
| network chaos | Namespaced | pods: exec |
| cpu-hog | Namespaced | pods: exec |

## Verifying RBAC

```bash
kubectl auth can-i delete pods \
  --as=system:serviceaccount:default:pod-delete-sa \
  -n default
# yes

kubectl auth can-i patch nodes \
  --as=system:serviceaccount:default:pod-delete-sa
# no  (correct — not needed for pod-delete)
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
