# valkey-repo-helm

Helm chart that deploys, on OpenShift:

- **Valkey**: `Deployment` + `Service` (`valkey`, port 6379) + `Secret`
  holding a randomly generated password (generated once via Helm's
  `lookup` function, never stored in git, stable across `helm upgrade`).
- **The demo app** (source in [`valkey-app`](https://github.com/dragos1993/valkey-app)):
  an `ImageStream` + `BuildConfig` that does an in-cluster S2I build from
  that repo (so no external container registry is needed), plus a
  `Deployment` (auto-updated via an `image.openshift.io/triggers`
  annotation whenever a new build completes), a `Service`, and an
  edge-TLS `Route`.

Chart-level defaults live in `values.yaml`; environment-specific values
(image tags, git ref, resource sizing, etc.) live in the separate
[`valkey-repo-values`](https://github.com/dragos1993/valkey-repo-values) repo.

## Install

```bash
git clone https://github.com/dragos1993/valkey-repo-values.git
helm upgrade --install valkey-app . \
  -n <your-namespace> \
  -f ../valkey-repo-values/values-dev.yaml
```

Then trigger the first build and roll out the app — see the NOTES printed
after install, or `templates/NOTES.txt`.

## Switching Valkey to registry.redhat.io later

By default `valkey.image` points at the public `docker.io/valkey/valkey:8`
image so this works without any registry login. `registry.redhat.io`
requires authenticated pulls, so switching to
`registry.redhat.io/rhel10/valkey-8:1784784603` needs two things once you
have a registry.redhat.io service account:

1. Create the pull secret directly in-cluster (not via a values file, so
   credentials never touch git):

   ```bash
   oc create secret docker-registry valkey-pull-secret \
     -n <your-namespace> \
     --docker-server=registry.redhat.io \
     --docker-username=<service-account-username> \
     --docker-password=<service-account-token>
   ```

2. Point the Deployment at the new image and secret:

   ```bash
   helm upgrade --install valkey-app . \
     -n <your-namespace> \
     -f ../valkey-repo-values/values-dev.yaml \
     --set valkey.image=registry.redhat.io/rhel10/valkey-8:1784784603 \
     --set valkey.imagePullSecretName=valkey-pull-secret
   ```

   (Add an `imagePullSecrets` entry referencing `valkey.imagePullSecretName`
   to `templates/valkey-deployment.yaml` when you get here — it was
   removed while unused to keep the chart minimal.)

## ArgoCD

This chart plus the values repo are wired together by the `Application`
manifest in [`argocd-repo`](https://github.com/dragos1993/argocd-repo).
ArgoCD isn't installed on this sandbox cluster yet, so for now this chart
is applied directly with `helm install`/`helm upgrade` — see that repo's
README for how to hook it up once GitOps is available.
