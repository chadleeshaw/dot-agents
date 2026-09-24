---
name: kubernetes
description: >
  Kubernetes operations and tooling. Use this skill whenever the user asks about
  kubectl, pods, deployments, namespaces, contexts, logs, ArgoCD, helmfile, or anything
  Kubernetes-related. Triggers on: k get, k describe, stern, kn, kx, argocd, argo,
  kubefwd, helmfile, Strimzi, Kafka on k8s, port forwarding services.
---

# Kubernetes Skill

Expert Kubernetes operations with common tooling conventions. Use idiomatic,
production-safe commands.

---

## Environment Conventions

| Tool | Purpose | Notes |
|---|---|---|
| `k` | `kubectl` alias | Always use `k` instead of `kubectl` |
| `kn <namespace>` | Switch namespace | Sets the default namespace for subsequent `k` commands |
| `kx <context>` | Switch context | Switches kubeconfig context |
| `stern` | Log tailing | Multi-pod log streaming; prefer over `k logs` for live tailing |
| `kubefwd` | Service forwarding | Forwards all services in a namespace to localhost by DNS name |

- Always specify `-n <namespace>` explicitly unless namespace was just set with `kn`
- Use `k get` before any destructive operation
- Prefer `k apply -f` over `k create` for idempotency
- Prefer `k diff -f` before `k apply` when reviewing changes

---

## Quick Reference

### Context & Namespace

```bash
# List and switch contexts
kx                        # interactive picker
kx <context-name>         # switch to named context

# List and switch namespaces
kn                        # interactive picker
kn <namespace>            # switch to named namespace
```

### Get / Describe

```bash
k get pods -n <ns>
k get pods -n <ns> -o wide
k get pods -n <ns> -l app=<name>
k get deploy,svc,ing -n <ns>
k get all -n <ns>

k describe pod <pod> -n <ns>
k describe deploy <name> -n <ns>
k describe node <node>

# Watch
k get pods -n <ns> -w
```

### Logs

```bash
# Single pod
k logs <pod> -n <ns>
k logs <pod> -n <ns> --previous          # crashed container
k logs <pod> -n <ns> -c <container>      # multi-container pod

# Live tailing — prefer stern
stern <app-name> -n <ns>
stern <app-name> -n <ns> --since 1h
stern <app-name> -n <ns> --container <c>
stern . -n <ns>                          # all pods in namespace
stern <app-name> --all-namespaces
stern <app-name> -n <ns> --include "ERROR|WARN"
```

### Exec / Debug

```bash
k exec -it <pod> -n <ns> -- /bin/sh
k exec -it <pod> -n <ns> -c <container> -- /bin/bash

# Ephemeral debug container (k8s 1.23+)
k debug -it <pod> -n <ns> --image=busybox --target=<container>

# DNS check from inside cluster
k run tmp-shell --rm -it --image=busybox -n <ns> -- nslookup <service>

# Network check
k run tmp-shell --rm -it --image=curlimages/curl -n <ns> -- curl http://<service>:<port>/health
```

### Deployments & Rollouts

```bash
k rollout status deploy/<name> -n <ns>
k rollout history deploy/<name> -n <ns>
k rollout undo deploy/<name> -n <ns>
k rollout restart deploy/<name> -n <ns>

k scale deploy/<name> --replicas=3 -n <ns>
k set image deploy/<name> <container>=<image>:<tag> -n <ns>
```

### Config & Secrets

```bash
k get configmap <name> -n <ns> -o yaml
k get secret <name> -n <ns> -o jsonpath='{.data.<key>}' | base64 -d
k edit configmap <name> -n <ns>
```

### Events & Troubleshooting

```bash
k get events -n <ns> --sort-by='.lastTimestamp'
k get events -n <ns> --field-selector reason=BackOff
k top pods -n <ns>
k top nodes
```

---

## kubefwd — Forward Services to Laptop

`kubefwd` forwards all services in a namespace to your laptop by DNS name, so you can
`curl http://my-service/` directly without per-service `k port-forward` commands.

**Requires `sudo`** — it writes entries to `/etc/hosts`.

```bash
# Forward all services in a namespace
sudo kubefwd -n <namespace>

# Multiple namespaces at once
sudo kubefwd -n <ns1> -n <ns2>

# Filter to specific services by label
sudo kubefwd -n <ns> -l app=<name>

# Filter by service name
sudo kubefwd -n <ns> -f metadata.name=<service-name>

# Use a specific context (overrides current kx context)
sudo kubefwd -n <ns> -x <context>

# With TUI for interactive monitoring
sudo kubefwd -n <ns> --tui

# Auto-reconnect if forwards drop
sudo kubefwd -n <ns> -a
```

Once running, services are reachable by their Kubernetes service name:

```bash
curl http://<service-name>/health
curl http://<service-name>:8080/api/v1/status
```

Stop with `Ctrl-C` — kubefwd cleans up `/etc/hosts` entries on exit.

### Tips

- Run `kx <context>` before `sudo kubefwd` to target the right cluster
- Use `--tui` for a live view of all forwarded services and their status
- Use `-p` to purge stale entries from a previous run: `sudo kubefwd -n <ns> -p`
- Port mapping for local conflicts: `sudo kubefwd -n <ns> -m 8080:80`

---

## ArgoCD Deployments

Deploys happen through ArgoCD via a GitOps deployment repository.

### apps.yaml format

```yaml
apps:
  - name: <app-name>
    chart: https://<registry>/<chart>-<version>.tgz
    envs:
      - kind: dev
      - kind: staging
        namespace: <namespace>
      - kind: production
        namespace: <namespace>
```

### Manifest rendering — deploy a new image or chart version

Use the local manifest rendering CLI for your deployment repo.
Always run it from the app directory (the one containing the app manifest/config file).
See the manifest-rendering tool page under `_ai/<company>/tools/` in your Obsidian vault for the exact commands.

```bash
cd <deployments-repo>/<team>/<app-name>

# Render current manifests (no changes)
<manifest-cli> template

# Render with a new image tag
<manifest-cli> template --set-image <app-name>:<new-tag>

# Render with a new chart version
<manifest-cli> template --set-chart <app-name>:<new-version>

# Render with both image tag and chart version updated
<manifest-cli> template --set-image <app>:<tag> --set-chart <app>:<version>
```

### Workflow: deploy a new image or chart version

1. `cd` into the app directory
2. Run the manifest CLI with `--set-image` or `--set-chart` flags
3. Review with `git diff`
4. Commit and push — ArgoCD picks up the change via GitOps sync

### Check ArgoCD sync status

```bash
argocd app get <app-name>
argocd app sync <app-name>
argocd app diff <app-name>

# Or via k
k get application <app-name> -n argocd
k describe application <app-name> -n argocd
```

---

## Kafka on Kubernetes (Strimzi)

```bash
# List Kafka resources
k get kafka -n <ns>
k get kafkatopic -n <ns>
k get kafkauser -n <ns>
k get kafkaconnect -n <ns>

# Describe a topic
k describe kafkatopic <topic> -n <ns>

# Strimzi operator logs
stern strimzi-cluster-operator -n <ns>

# Kafka broker logs
stern <cluster-name>-kafka -n <ns>
```

---

## Helmfile

```bash
helmfile diff
helmfile apply
helmfile sync
helmfile --selector name=<release> diff
helmfile --environment <env> apply
```

---

## Debugging Workflow

Follow this order — don't jump to restarts before reading events and logs.

```
1. k get pods -n <ns>                    # Running / Pending / CrashLoopBackOff?
2. k describe pod <pod> -n <ns>          # Events section
3. stern <app> -n <ns> --since 15m       # application logs
4. k logs <pod> -n <ns> --previous       # if container crashed
5. k get events -n <ns> --sort-by='.lastTimestamp'
6. k top pods -n <ns>                    # resource pressure?
7. k exec -it <pod> -n <ns> -- /bin/sh   # in-container investigation
```

### Common failure patterns

| Symptom | Likely cause | First check |
|---|---|---|
| `CrashLoopBackOff` | App error or bad config | `k logs --previous` |
| `Pending` | No schedulable node | `k describe pod` → Events |
| `ImagePullBackOff` | Wrong image tag or registry auth | `k describe pod` → Events |
| `OOMKilled` | Memory limit too low | `k top pods`, check limits in deploy |
| `Terminating` stuck | Finalizer not cleared | `k get pod -o yaml` → check finalizers |
| ArgoCD `OutOfSync` | Manifest drift | `argocd app diff <name>` |

---

## Useful One-liners

```bash
# All pods not Running
k get pods -A --field-selector=status.phase!=Running

# Pods by node
k get pods -o wide -A | grep <node-name>

# Force delete stuck terminating pod
k delete pod <pod> -n <ns> --grace-period=0 --force

# Copy file from pod
k cp <ns>/<pod>:/path/to/file ./local-file

# Port forward a single service
k port-forward svc/<service> 8080:80 -n <ns>

# Decode all secrets in a namespace
k get secrets -n <ns> -o json | \
  python3 -c "import json,sys,base64; \
  [print(s['metadata']['name'], {k: base64.b64decode(v).decode() \
  for k,v in s.get('data',{}).items()}) \
  for s in json.load(sys.stdin)['items']]"
```
