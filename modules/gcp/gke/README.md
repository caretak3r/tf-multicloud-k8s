# Safer Cluster: How to setup a GKE Kubernetes cluster with reduced exposure

This module defines an opinionated setup of GKE
cluster. We outline project configurations, cluster settings, and basic K8s
objects that permit a safer-than-default configuration.

## Module Usage

The module fixes a set of parameters to values suggested in the
[GKE hardening guide](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster),
the CIS framework, and other best practices.

The motivation for each setting, and its relation to hardening guides or other recommendations
is outline in `main.tf` as comments over individual settings. When security-relevant settings
are available for configuration, recommendations on their settings are documented in the `variables.tf` file.

## Project Setup and Cloud IAM policy for GKE

### Applications and Clusters

-   Different applications that access data with different sensitivity and do
    not need to communicate with each other (e.g., dev and prod instances of the
    same application) should be placed in different clusters.

    -   This approach will limit the blast radius of errors. An security problem
        in dev shouldn't impact production data.

-   If applications need to communicate (e.g., a frontend system calling
    a backend), we suggest placing the two applications in the same cluster, in
    different namespaces.

    -   Placing them in the same cluster will provide fast network
        communication, and the different namespaces will be configured to
        provide some administrative isolation. Istio will be used to encrypt and
        control communication between applications.

-   We suggest to store user or business data persistently in managed storage
    services that are inventoried and controlled by centralized teams.
    (e.g., GCP storage services within a GCP organization).

    -   Storing user or business data securely requires satisfying a large set of
        requirements, such as data inventory, which might be harder to satisfy at
        scale when data is stored opaquely within a cluster. Services like Cloud
        Asset Inventory provide centralized teams ability to enumerate data stores.

### Project Setup

We suggest a GKE setup composed of multiple projects to separate responsibilities
between cluster operators, which need to administer the cluster; and product
developers, which mostly just want to deploy and debug applications.

-   *Cluster Projects (`project_id`):* GKE clusters storing sensitive data should have their
    own projects, so that they can be administered independently (e.g., dev cluster;
    production clusters; staging clusters should go in different projects.)

-   *Shared GCR projects (`registry_project_ids`):* all clusters can share the same
    GCR projects.

    -   Easier to share images between environments. The same image could be
        progressively rolled-out in dev, staging, and then production.
    -   Easier to manage service account permissions: GCR requires authorizing
        service accounts to access certain buckets, which are created only after
        images are published. When the only service run by the project is GCR,
        we can safely give project-wide read permissions to all buckets.

-   (optional) *Data Projects:* When the same cluster is shared by different
    applications managed by different teams, we suggest separating the data for
    each application by placing storage resources for each team in different
    projects (e.g., a Spanner instance for application A in one project, GCS
    bucket for application B in a different project).

    -   This permits to control administrative access to the data more tightly,
        as Cloud IAM policies for accessing the data can be managed by each
        application team, rather than the team managing the cluster
        infrastructure.

Exception to such a setup:

-   When not using Shared VPCs, resources that require direct network connectivity
    (e.g., a Cloud SQL instance), need to be placed in the same VPC (hence, project)
    as the clusters from which connections are made.

### Google Service Accounts

We use GKE Workload Identity (BETA) to associate a GCP identity to each workload,
and limit the permissions associated with the cluster nodes.

The Safer Cluster setup relies on several service accounts:

-   The module generates a service account to run nodes. Such a service account
    has only permissions of sending logging data, metrics, and downloading containers
    from the given GCR project. The following settings in the module will create
    a service account with the above properties:

```
create_service_account = true
registry_project_ids = [<the project id for your GCR project>]
grant_registry_access = true
```

-   A service account *for each application* running on the cluster (e.g.,
    `myproduct-sa@myproduct-prod.iam.gserviceaccount.com`). These service
    accounts should be associated to the permissions required for running the
    application, such as access to databases.

```
- email: myproduct
  displayName: Google Service Account for containers running in the myproduct k8s namespace
  policy:
    # GKE workload identity authorization. This authorizes the Kubernetes Service Account
    # myproduct/default from this project's identity namespace to impersonate the service account.
    # https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
    bindings:
    - members:
      - serviceAccount:product-prod.svc.id.goog[myproduct/default]
      role: roles/iam.workloadIdentityUser
```

We suggest running different applications in different namespaces within the cluster. Each namespace
should be assigned to its own GCP service account to better define the Cloud IAM permissions required
for the application.

If you are using more than 2 projects in your setup, you can consider creating
the service account in a different project to keep application and
infrastructure separate. For example, service accounts could be created in each team's project,
while the cluster runs in a centrally controlled project.

<section class="zippy">
*Why?*

Separating the permissions associated with the infrastructure GKE nodes and the
application provides a simpler way to scale up the cluster: multiple applications
could be run in the same cluster, and each of them can run with tailored permissions
that limit the impact of compromises.

Such a separation of identities is enabled by a GKE feature called Workload
Identity. The feature provides additional advantages such as a better protection
of the node's metadata server against attackers.

</section>

### Cloud IAM Permissions for the GKE Cluster

We suggest to mainly rely on Kubernetes RBAC to manage access control, and use
Cloud IAM to give users only the ability of configuring `kubectl` credentials.

Engineers operating applications on the cluster should only be assigned the
Cloud IAM permission `roles/container.clusterViewer`. This role allows them to
obtain credentials for the cluster, but provides no further access to the
cluster objects. All cluster objects are protected by RBAC configurations,
defined below.

<section class="zippy">
*Why?*

Both Cloud IAM and RBAC can be used to control access to GKE clusters. Those two
systems are combined as a "OR": an action is authorized if the necessary
permissions are provided by either RBAC _OR_ Cloud IAM

However, Cloud IAM permissions are defined for a project: user get assigned the
same permissions over all clusters and all namespaces within each cluster. Such
a setup makes it hard to separate responsibilities between teams in charge of
managing clusters, and teams in charge of products.

By relying on RBAC instead of Cloud IAM, we have a finer-grained control of the
permissions provided to engineers, and permits to restrict permissions to only
certain namespaces.

</section>

You can add the following binding to the `myproduct-prod` project.

```
- members:
  role: roles/container.clusterViewer`
  - group:<produdct team group>
  - group:<cluster team group>
```

The permissions won't allow engineers to SSH into nodes as part of the regular
development workflow. Such permissions should be granted only to the cluster
team, and used only in case of emergency.

While RBAC permissions should be sufficient for most cases, we also suggest to
create an emergency superuser role that can be used, given a proper
justification, for resolving cases where regular permissions are insufficient.
For simplicity, we suggest using `roles/container.admin` and
`roles/compute.admin`, until more narrow roles can be defined given your usage.

```
- members:
  role: roles/container.admin
  - group:<oncall for cluster tean>
- members:
  role: roles/compute.admin
  - group:<oncall for cluster tean>
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 7.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_container_cluster.gke_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_container_node_pool.default_node_pool](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_project_iam_member.gke_nodes_logging](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.gke_nodes_metrics](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.gke_nodes_monitoring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.gke_nodes_registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.gke_nodes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_cluster_firewall_rules"></a> [add\_cluster\_firewall\_rules](#input\_add\_cluster\_firewall\_rules) | Create additional firewall rules | `bool` | `false` | no |
| <a name="input_authenticator_security_group"></a> [authenticator\_security\_group](#input\_authenticator\_security\_group) | The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format gke-security-groups@yourdomain.com | `string` | `null` | no |
| <a name="input_cloudrun"></a> [cloudrun](#input\_cloudrun) | (Beta) Enable CloudRun addon | `bool` | `false` | no |
| <a name="input_cluster_autoscaling"></a> [cluster\_autoscaling](#input\_cluster\_autoscaling) | Cluster autoscaling configuration. See [more details](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters#clusterautoscaling) | <pre>object({<br/>    enabled             = bool<br/>    autoscaling_profile = string<br/>    min_cpu_cores       = number<br/>    max_cpu_cores       = number<br/>    min_memory_gb       = number<br/>    max_memory_gb       = number<br/>    gpu_resources       = list(object({ resource_type = string, minimum = number, maximum = number }))<br/>    auto_repair         = bool<br/>    auto_upgrade        = bool<br/>  })</pre> | <pre>{<br/>  "auto_repair": true,<br/>  "auto_upgrade": true,<br/>  "autoscaling_profile": "BALANCED",<br/>  "enabled": false,<br/>  "gpu_resources": [],<br/>  "max_cpu_cores": 0,<br/>  "max_memory_gb": 0,<br/>  "min_cpu_cores": 0,<br/>  "min_memory_gb": 0<br/>}</pre> | no |
| <a name="input_cluster_dns_domain"></a> [cluster\_dns\_domain](#input\_cluster\_dns\_domain) | The suffix used for all cluster service records. | `string` | `""` | no |
| <a name="input_cluster_dns_provider"></a> [cluster\_dns\_provider](#input\_cluster\_dns\_provider) | Which in-cluster DNS provider should be used. PROVIDER\_UNSPECIFIED (default) or PLATFORM\_DEFAULT or CLOUD\_DNS. | `string` | `"PROVIDER_UNSPECIFIED"` | no |
| <a name="input_cluster_dns_scope"></a> [cluster\_dns\_scope](#input\_cluster\_dns\_scope) | The scope of access to cluster DNS records. DNS\_SCOPE\_UNSPECIFIED (default) or CLUSTER\_SCOPE or VPC\_SCOPE. | `string` | `"DNS_SCOPE_UNSPECIFIED"` | no |
| <a name="input_cluster_resource_labels"></a> [cluster\_resource\_labels](#input\_cluster\_resource\_labels) | The GCE resource labels (a map of key/value pairs) to be applied to the cluster | `map(string)` | `{}` | no |
| <a name="input_compute_engine_service_account"></a> [compute\_engine\_service\_account](#input\_compute\_engine\_service\_account) | Use the given service account for nodes rather than creating a new dedicated service account. If set then also set var.create\_service\_account to false to avoid 'value depends on resource attributes that cannot be determined until apply' errors. | `string` | `""` | no |
| <a name="input_config_connector"></a> [config\_connector](#input\_config\_connector) | Whether ConfigConnector is enabled for this cluster. | `bool` | `false` | no |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Defines if service account specified to run nodes should be created. Explicitly set to false if var.compute\_engine\_service\_account is set to avoid 'value depends on resource attributes that cannot be determined until apply' errors. | `bool` | `true` | no |
| <a name="input_database_encryption"></a> [database\_encryption](#input\_database\_encryption) | Application-layer Secrets Encryption settings. The object format is {state = string, key\_name = string}. Valid values of state are: "ENCRYPTED"; "DECRYPTED". key\_name is the name of a CloudKMS key. | `list(object({ state = string, key_name = string }))` | <pre>[<br/>  {<br/>    "key_name": "",<br/>    "state": "DECRYPTED"<br/>  }<br/>]</pre> | no |
| <a name="input_datapath_provider"></a> [datapath\_provider](#input\_datapath\_provider) | The desired datapath provider for this cluster. By default, `ADVANCED_DATAPATH` enables Dataplane-V2 feature. `DATAPATH_PROVIDER_UNSPECIFIED` enables the IPTables-based kube-proxy implementation as a fallback since upgrading to V2 requires a cluster re-creation. | `string` | `"ADVANCED_DATAPATH"` | no |
| <a name="input_default_max_pods_per_node"></a> [default\_max\_pods\_per\_node](#input\_default\_max\_pods\_per\_node) | The maximum number of pods to schedule per node | `number` | `110` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether or not to allow Terraform to destroy the cluster. | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | The description of the cluster | `string` | `""` | no |
| <a name="input_disable_default_snat"></a> [disable\_default\_snat](#input\_disable\_default\_snat) | Whether to disable the default SNAT to support the private use of public IP addresses | `bool` | `false` | no |
| <a name="input_dns_cache"></a> [dns\_cache](#input\_dns\_cache) | (Beta) The status of the NodeLocal DNSCache addon. | `bool` | `false` | no |
| <a name="input_enable_confidential_nodes"></a> [enable\_confidential\_nodes](#input\_enable\_confidential\_nodes) | An optional flag to enable confidential node config. | `bool` | `false` | no |
| <a name="input_enable_cost_allocation"></a> [enable\_cost\_allocation](#input\_enable\_cost\_allocation) | Enables Cost Allocation Feature and the cluster name and namespace of your GKE workloads appear in the labels field of the billing export to BigQuery | `bool` | `false` | no |
| <a name="input_enable_gcfs"></a> [enable\_gcfs](#input\_enable\_gcfs) | Enable image streaming on cluster level. | `bool` | `false` | no |
| <a name="input_enable_intranode_visibility"></a> [enable\_intranode\_visibility](#input\_enable\_intranode\_visibility) | Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network | `bool` | `false` | no |
| <a name="input_enable_l4_ilb_subsetting"></a> [enable\_l4\_ilb\_subsetting](#input\_enable\_l4\_ilb\_subsetting) | Enable L4 ILB Subsetting on the cluster | `bool` | `false` | no |
| <a name="input_enable_mesh_certificates"></a> [enable\_mesh\_certificates](#input\_enable\_mesh\_certificates) | Controls the issuance of workload mTLS certificates. When enabled the GKE Workload Identity Certificates controller and node agent will be deployed in the cluster. Requires Workload Identity. | `bool` | `false` | no |
| <a name="input_enable_pod_security_policy"></a> [enable\_pod\_security\_policy](#input\_enable\_pod\_security\_policy) | enabled - Enable the PodSecurityPolicy controller for this cluster. If enabled, pods must be valid under a PodSecurityPolicy to be created. | `bool` | `false` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | When true, the cluster's private endpoint is used as the cluster endpoint and access through the public endpoint is disabled. When false, either endpoint can be used. This field only applies to private clusters, when enable\_private\_nodes is true | `bool` | `true` | no |
| <a name="input_enable_shielded_nodes"></a> [enable\_shielded\_nodes](#input\_enable\_shielded\_nodes) | Enable Shielded Nodes features on all nodes in this cluster. | `bool` | `true` | no |
| <a name="input_enable_vertical_pod_autoscaling"></a> [enable\_vertical\_pod\_autoscaling](#input\_enable\_vertical\_pod\_autoscaling) | Vertical Pod Autoscaling automatically adjusts the resources of pods controlled by it | `bool` | `false` | no |
| <a name="input_filestore_csi_driver"></a> [filestore\_csi\_driver](#input\_filestore\_csi\_driver) | The status of the Filestore CSI driver addon, which allows the usage of filestore instance as volumes | `bool` | `false` | no |
| <a name="input_firewall_inbound_ports"></a> [firewall\_inbound\_ports](#input\_firewall\_inbound\_ports) | List of TCP ports for admission/webhook controllers | `list(string)` | <pre>[<br/>  "8443",<br/>  "9443",<br/>  "15017"<br/>]</pre> | no |
| <a name="input_firewall_priority"></a> [firewall\_priority](#input\_firewall\_priority) | Priority rule for firewall rules | `number` | `1000` | no |
| <a name="input_gateway_api_channel"></a> [gateway\_api\_channel](#input\_gateway\_api\_channel) | The gateway api channel of this cluster. Accepted values are `CHANNEL_STANDARD` and `CHANNEL_DISABLED`. | `string` | `null` | no |
| <a name="input_gce_pd_csi_driver"></a> [gce\_pd\_csi\_driver](#input\_gce\_pd\_csi\_driver) | (Beta) Whether this cluster should enable the Google Compute Engine Persistent Disk Container Storage Interface (CSI) Driver. | `bool` | `true` | no |
| <a name="input_gcs_fuse_csi_driver"></a> [gcs\_fuse\_csi\_driver](#input\_gcs\_fuse\_csi\_driver) | Whether GCE FUSE CSI driver is enabled for this cluster. | `bool` | `false` | no |
| <a name="input_gke_backup_agent_config"></a> [gke\_backup\_agent\_config](#input\_gke\_backup\_agent\_config) | (Beta) Whether Backup for GKE agent is enabled for this cluster. | `bool` | `false` | no |
| <a name="input_grant_registry_access"></a> [grant\_registry\_access](#input\_grant\_registry\_access) | Grants created cluster-specific service account storage.objectViewer role. | `bool` | `true` | no |
| <a name="input_horizontal_pod_autoscaling"></a> [horizontal\_pod\_autoscaling](#input\_horizontal\_pod\_autoscaling) | Enable horizontal pod autoscaling addon | `bool` | `true` | no |
| <a name="input_http_load_balancing"></a> [http\_load\_balancing](#input\_http\_load\_balancing) | Enable httpload balancer addon. The addon allows whoever can create Ingress objects to expose an application to a public IP. Network policies or Gatekeeper policies should be used to verify that only authorized applications are exposed. | `bool` | `true` | no |
| <a name="input_initial_node_count"></a> [initial\_node\_count](#input\_initial\_node\_count) | The number of nodes to create in this cluster's default node pool. | `number` | `0` | no |
| <a name="input_ip_range_pods"></a> [ip\_range\_pods](#input\_ip\_range\_pods) | The _name_ of the secondary subnet ip range to use for pods | `string` | n/a | yes |
| <a name="input_ip_range_services"></a> [ip\_range\_services](#input\_ip\_range\_services) | The _name_ of the secondary subnet range to use for services. If not provided, the default `34.118.224.0/20` range will be used. | `string` | `null` | no |
| <a name="input_istio"></a> [istio](#input\_istio) | (Beta) Enable Istio addon | `bool` | `false` | no |
| <a name="input_istio_auth"></a> [istio\_auth](#input\_istio\_auth) | (Beta) The authentication type between services in Istio. | `string` | `"AUTH_MUTUAL_TLS"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region. The module enforces certain minimum versions to ensure that specific features are available. | `string` | `null` | no |
| <a name="input_logging_service"></a> [logging\_service](#input\_logging\_service) | The logging service that the cluster should write logs to. Available options include logging.googleapis.com, logging.googleapis.com/kubernetes (beta), and none | `string` | `"logging.googleapis.com/kubernetes"` | no |
| <a name="input_maintenance_end_time"></a> [maintenance\_end\_time](#input\_maintenance\_end\_time) | Time window specified for recurring maintenance operations in RFC3339 format | `string` | `""` | no |
| <a name="input_maintenance_exclusions"></a> [maintenance\_exclusions](#input\_maintenance\_exclusions) | List of maintenance exclusions. A cluster can have up to three | `list(object({ name = string, start_time = string, end_time = string, exclusion_scope = string }))` | `[]` | no |
| <a name="input_maintenance_recurrence"></a> [maintenance\_recurrence](#input\_maintenance\_recurrence) | Frequency of the recurring maintenance window in RFC5545 format. | `string` | `""` | no |
| <a name="input_maintenance_start_time"></a> [maintenance\_start\_time](#input\_maintenance\_start\_time) | Time window specified for daily maintenance operations in RFC3339 format | `string` | `"05:00"` | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists). | `list(object({ cidr_block = string, display_name = string }))` | `[]` | no |
| <a name="input_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#input\_master\_ipv4\_cidr\_block) | The IP range in CIDR notation to use for the hosted master network | `string` | `"10.0.0.0/28"` | no |
| <a name="input_monitoring_enable_managed_prometheus"></a> [monitoring\_enable\_managed\_prometheus](#input\_monitoring\_enable\_managed\_prometheus) | (Beta) Configuration for Managed Service for Prometheus. Whether or not the managed collection is enabled. | `bool` | `false` | no |
| <a name="input_monitoring_enable_observability_metrics"></a> [monitoring\_enable\_observability\_metrics](#input\_monitoring\_enable\_observability\_metrics) | Whether or not the advanced datapath metrics are enabled. | `bool` | `false` | no |
| <a name="input_monitoring_enable_observability_relay"></a> [monitoring\_enable\_observability\_relay](#input\_monitoring\_enable\_observability\_relay) | Whether or not the advanced datapath relay is enabled. | `bool` | `false` | no |
| <a name="input_monitoring_enabled_components"></a> [monitoring\_enabled\_components](#input\_monitoring\_enabled\_components) | List of services to monitor: SYSTEM\_COMPONENTS, WORKLOADS. Empty list is default GKE configuration. | `list(string)` | `[]` | no |
| <a name="input_monitoring_service"></a> [monitoring\_service](#input\_monitoring\_service) | The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting Available options include monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none | `string` | `"monitoring.googleapis.com/kubernetes"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the cluster | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | The VPC network to host the cluster in | `string` | n/a | yes |
| <a name="input_network_project_id"></a> [network\_project\_id](#input\_network\_project\_id) | The project ID of the shared VPC's host (for shared vpc support) | `string` | `""` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | List of maps containing node pools | `list(map(string))` | <pre>[<br/>  {<br/>    "name": "default-node-pool"<br/>  }<br/>]</pre> | no |
| <a name="input_node_pools_labels"></a> [node\_pools\_labels](#input\_node\_pools\_labels) | Map of maps containing node labels by node-pool name | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_metadata"></a> [node\_pools\_metadata](#input\_node\_pools\_metadata) | Map of maps containing node metadata by node-pool name | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_oauth_scopes"></a> [node\_pools\_oauth\_scopes](#input\_node\_pools\_oauth\_scopes) | Map of lists containing node oauth scopes by node-pool name | `map(list(string))` | <pre>{<br/>  "all": [<br/>    "https://www.googleapis.com/auth/cloud-platform"<br/>  ],<br/>  "default-node-pool": []<br/>}</pre> | no |
| <a name="input_node_pools_resource_labels"></a> [node\_pools\_resource\_labels](#input\_node\_pools\_resource\_labels) | Map of maps containing resource labels by node-pool name | `map(map(string))` | <pre>{<br/>  "all": {},<br/>  "default-node-pool": {}<br/>}</pre> | no |
| <a name="input_node_pools_tags"></a> [node\_pools\_tags](#input\_node\_pools\_tags) | Map of lists containing node network tags by node-pool name | `map(list(string))` | <pre>{<br/>  "all": [],<br/>  "default-node-pool": []<br/>}</pre> | no |
| <a name="input_node_pools_taints"></a> [node\_pools\_taints](#input\_node\_pools\_taints) | Map of lists containing node taints by node-pool name | `map(list(object({ key = string, value = string, effect = string })))` | <pre>{<br/>  "all": [],<br/>  "default-node-pool": []<br/>}</pre> | no |
| <a name="input_notification_config_topic"></a> [notification\_config\_topic](#input\_notification\_config\_topic) | The desired Pub/Sub topic to which notifications will be sent by GKE. Format is projects/{project}/topics/{topic}. | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID to host the cluster in | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to host the cluster in | `string` | n/a | yes |
| <a name="input_regional"></a> [regional](#input\_regional) | Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!) | `bool` | `true` | no |
| <a name="input_registry_project_ids"></a> [registry\_project\_ids](#input\_registry\_project\_ids) | Projects holding Google Container Registries. If empty, we use the cluster project. If a service account is created and the `grant_registry_access` variable is set to `true`, the `storage.objectViewer` role is assigned on these projects. | `list(string)` | `[]` | no |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `REGULAR`. | `string` | `"REGULAR"` | no |
| <a name="input_resource_usage_export_dataset_id"></a> [resource\_usage\_export\_dataset\_id](#input\_resource\_usage\_export\_dataset\_id) | The dataset id for which network egress metering for this cluster will be enabled. If enabled, a daemonset will be created in the cluster to meter network egress traffic. | `string` | `""` | no |
| <a name="input_sandbox_enabled"></a> [sandbox\_enabled](#input\_sandbox\_enabled) | (Beta) Enable GKE Sandbox (Do not forget to set `image_type` = `COS_CONTAINERD` to use it). | `bool` | `false` | no |
| <a name="input_security_posture_mode"></a> [security\_posture\_mode](#input\_security\_posture\_mode) | Security posture mode.  Accepted values are `DISABLED` and `BASIC`. Defaults to `DISABLED`. | `string` | `"DISABLED"` | no |
| <a name="input_security_posture_vulnerability_mode"></a> [security\_posture\_vulnerability\_mode](#input\_security\_posture\_vulnerability\_mode) | Security posture vulnerability mode.  Accepted values are `VULNERABILITY_DISABLED`, `VULNERABILITY_BASIC`, and `VULNERABILITY_ENTERPRISE` | `string` | `null` | no |
| <a name="input_stub_domains"></a> [stub\_domains](#input\_stub\_domains) | Map of stub domains and their resolvers to forward DNS queries for a certain domain to an external DNS server | `map(list(string))` | `{}` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | The subnetwork to host the cluster in | `string` | n/a | yes |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeout for cluster operations. | `map(string)` | `{}` | no |
| <a name="input_upstream_nameservers"></a> [upstream\_nameservers](#input\_upstream\_nameservers) | If specified, the values replace the nameservers taken by default from the node’s /etc/resolv.conf | `list(string)` | `[]` | no |
| <a name="input_windows_node_pools"></a> [windows\_node\_pools](#input\_windows\_node\_pools) | List of maps containing node pools | `list(map(string))` | `[]` | no |
| <a name="input_workload_config_audit_mode"></a> [workload\_config\_audit\_mode](#input\_workload\_config\_audit\_mode) | (beta) Workload config audit mode. | `string` | `"DISABLED"` | no |
| <a name="input_workload_vulnerability_mode"></a> [workload\_vulnerability\_mode](#input\_workload\_vulnerability\_mode) | (beta) Vulnerability mode. | `string` | `""` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | The zones to host the cluster in | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ca_certificate"></a> [ca\_certificate](#output\_ca\_certificate) | Cluster ca certificate (base64 encoded) |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Cluster ID |
| <a name="output_enable_mesh_certificates"></a> [enable\_mesh\_certificates](#output\_enable\_mesh\_certificates) | Mesh certificate configuration value |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Cluster endpoint |
| <a name="output_endpoint_dns"></a> [endpoint\_dns](#output\_endpoint\_dns) | Cluster endpoint DNS |
| <a name="output_horizontal_pod_autoscaling_enabled"></a> [horizontal\_pod\_autoscaling\_enabled](#output\_horizontal\_pod\_autoscaling\_enabled) | Whether horizontal pod autoscaling enabled |
| <a name="output_http_load_balancing_enabled"></a> [http\_load\_balancing\_enabled](#output\_http\_load\_balancing\_enabled) | Whether http load balancing enabled |
| <a name="output_location"></a> [location](#output\_location) | Cluster location (region if regional cluster, zone if zonal cluster) |
| <a name="output_logging_service"></a> [logging\_service](#output\_logging\_service) | Logging service used |
| <a name="output_master_authorized_networks_config"></a> [master\_authorized\_networks\_config](#output\_master\_authorized\_networks\_config) | Networks from which access to master is permitted |
| <a name="output_master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#output\_master\_ipv4\_cidr\_block) | The IP range in CIDR notation used for the hosted master network |
| <a name="output_master_version"></a> [master\_version](#output\_master\_version) | Current master kubernetes version |
| <a name="output_min_master_version"></a> [min\_master\_version](#output\_min\_master\_version) | Minimum master kubernetes version |
| <a name="output_monitoring_service"></a> [monitoring\_service](#output\_monitoring\_service) | Monitoring service used |
| <a name="output_name"></a> [name](#output\_name) | Cluster name |
| <a name="output_network_policy_enabled"></a> [network\_policy\_enabled](#output\_network\_policy\_enabled) | Whether network policy enabled |
| <a name="output_node_pools_names"></a> [node\_pools\_names](#output\_node\_pools\_names) | List of node pools names |
| <a name="output_node_pools_versions"></a> [node\_pools\_versions](#output\_node\_pools\_versions) | Node pool versions by node pool name |
| <a name="output_peering_name"></a> [peering\_name](#output\_peering\_name) | The name of the peering between this cluster and the Google owned VPC. |
| <a name="output_region"></a> [region](#output\_region) | Cluster region |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account to default running nodes as if not overridden in `node_pools`. |
| <a name="output_type"></a> [type](#output\_type) | Cluster type (regional / zonal) |
| <a name="output_zones"></a> [zones](#output\_zones) | List of zones in which the cluster resides |
<!-- END_TF_DOCS -->

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure
