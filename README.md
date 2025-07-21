# helm-rest-api

This chart allows you to deploy all resources needed to serve a REST API application accessible over the Internet. 

## Usage

### Simple deployment

This chart comes pre-configured with minimal defaults and requires adjustment for enabling additional integrations described in the [configuration](#configuration) section below.

> **NOTE**: It may be necessary to make adjustments based on specifics of your image - see [this section](#pod-security-standard).

At the **minimum**, you need to provide the image you want to deploy:

```yaml
# values.yaml
image:
  registry: gcr.io/google-samples
  repository: hello-app
  tag: "1.0"
```

This command installs the chart with default configuration and your image:
```bash
helm install rest-api oci://ghcr.io/edgy-noodle/rest-api --values values.yaml
```

See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation.

### Deployment at scale

It is recommended to leverage additional tools, such as GitOps (FluxCD, ArgoCD) and kustomize, for consistent configuration across different environments and production-readiness stages. This provides separation of concerns between the deployment-specific configuration and the general application deployment recipe this chart provides.

## Configuration

### Autoscaling and HA configuration

#### Deployment

This chart provides support for general HA configuration through standard `Deployment` properties such as `affinity`, `topologySpreadConstraints` or `priorityClassName`. In addition, affinity supports `soft` and `hard` presets from the `bitnami/common` chart for ease of use.

#### Horizontal Pod Autoscaler

This chart provides support for autoscaling using the `HorizontalPodAutoscaler` resource. To enable the integration, set `autoscaling.enabled=true`.

You can control the number of desired replicas using `autoscaling.minReplicas` and `autoscaling.MaxReplicas` properties.
To customize scaling thresholds, use `autoscaling.targetCPU` and `autoscaling.targetMemory` and set them to the desired percentage.

You can further customize scaling behavior using advanced options under `autoscaling.behavior` - see [official documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior) for more details.

#### Pod Disruption Budgets

This chart provides support for creating `PodDisruptionBudget` using `pdb.enabled=true`. You can then further customize either `pdb.minAvailable` or `pdb.maxUnavailable` values.

### Serving the application

#### Prerequisites

It is **necessary** to have a working installation of an **ingress controller** or **Gateway API controller** (with a provisioned gateway) for the integration to work.
Additionally, you need a working installation of a **Load Balancer controller** for your infrastructure provider in order to expose the application outside the cluster.

#### Gateway API

This chart provides support for `HTTPRoute` resources. To enable the integration, set `httpRoute.enabled=true`.
Use `.httpRoute.gateway.name` to indicate the gateway to attach this route to. If your gateway resides in a different namespace, you can set that via `httpRoute.gateway.namespace` property.
The `.host` property can be used to set the host name.

#### Ingress

This chart provides support for `Ingress` resources. To enable the integration, set `ingress.enabled=true`. The `.host` property can be used to set the host name. The `ingress.tls` parameter can be used to add the TLS configuration for this host - see [this section](#ingress-tls).

### Security

#### Pod Security Standard

This chart is compliant with the [restricted](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted) Pod Security Standard out of the box.
This may pose an issue for APIs packaged with web servers such as nginx or httpd as they may need access to the underlying filesystem for logging and configuration, or to be run as a specific user.

In order to solve this, you can either:
- Set `app.containerSecurityContext.readOnlyRootFilesystem=false`.
- Attach all necessary volumes through `app.extraVolumes` and `app.extraVolumeMounts` properties. If your image contains configuration files, use `app.initContainers` to copy the necessary configuration from the image into a shared volume and mount that to the application container.

You can then further customize options such as `runAsUser` under the `app.containerSecurityContext`.

#### Network Policy

This chart implements a Network Policy which defaults to **blocking egress** and **allowing ingress**. If the application needs to reach additional endpoints (e.g. `kube-dns` or external endpoints), you can easily enable DNS resolution with `networkPolicy.allowDNS=true` and provide additional rules via `networkPolicy.extraEgress`. When you enable either Gateway API or Ingress and set `allowExternalIngress=false`, the appropriate ingress rules will be added automatically. You can also use `networkPolicy.extraIngress` to provide additional rules.

#### Ingress TLS

This chart facilitates the creation of TLS secrets for use with the ingress controller. There are several common use cases:

- Generate certificate secrets based on chart parameters.
- Enable externally generated certificates.
- Manage application certificates via an external service (like [cert-manager](https://github.com/jetstack/cert-manager/)).
- Create self-signed certificates within the chart (if supported).

In the first two cases, a certificate and a key are needed. Files are expected in `.pem` format.

- If using Helm to manage the certificates based on the parameters, copy the certificate and key into the `certificate` and `key` values for a given `*.ingress.secrets` entry.
- If managing TLS secrets separately, it is necessary to create a TLS secret with name `INGRESS_HOSTNAME-tls` (where `INGRESS_HOSTNAME` is a placeholder to be replaced with the hostname you set using the `*.ingress.hostname` parameter).
- If your cluster has a cert-manager add-on to automate the management and issuance of TLS certificates, add to `*.ingress.annotations` the [corresponding ones](https://cert-manager.io/docs/usage/ingress/#supported-annotations) for cert-manager.
- If using self-signed certificates created by Helm, set both `*.ingress.tls` and `*.ingress.selfSigned` to true.

### Resource requests and limits

The chart uses `resourcesPreset` values, which references ready presets from the `bitnami/common` chart. While using this in production is discouraged, it is a convenient solution for prototyping and development. You can inspect available presets [here](https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15-L44).

### Metrics

#### Prerequisites
It is **necessary** to have a working installation of **Prometheus** or **Prometheus Operator** for the integration to work.

#### Service

This chart can be integrated with Prometheus by setting `metrics.enabled=true`. Depending on your application, you can either expose the metrics port by setting `metrics.containerPorts.metrics` or define a sidecar container with an exporter via `app.sidecars` property.

#### Service Monitor

The chart can deploy `ServiceMonitor` objects for integration with Prometheus Operator installations. To do so, set the value `metrics.serviceMonitor.enabled=true`. Ensure that the Prometheus Operator _CustomResourceDefinitions_ are installed in the cluster or it will fail with the following error:

```
no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
```

## License

This project is licensed under the [MIT license](LICENSE).

This project uses Bitnami common dependency as well as parts of the Bitnami template as boilerplate. See [NOTICE](NOTICE) for original license.
