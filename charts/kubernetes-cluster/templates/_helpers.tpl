{{/*
kcluster.clusterName — the name every Cluster API object is built from.

Deliberately .Values.name (≤32 chars) and not lib.fullname: the release name is
"<tenant>-tenant-<instance>-kubernetes-cluster", and appending a pool name and a
revision hash to that blows past the 63-char limit. Each instance gets its own
namespace, so the short name is still unique.
*/}}
{{- define "kcluster.clusterName" -}}
{{- .Values.name | trunc 32 | trimSuffix "-" -}}
{{- end -}}


{{/*
kcluster.templateID — resolve the Kubernetes version to a Proxmox VM template.
.Values.images is the only place a version is enabled; an unknown one fails the
render with the supported list instead of cloning the wrong image.
*/}}
{{- define "kcluster.templateID" -}}
{{- $img := (index .Values.images .Values.version) | default dict -}}
{{- if not (hasKey $img "templateID") -}}
{{- fail (printf "kubernetes-cluster: unsupported version %q. Supported (charts/kubernetes-cluster/values.yaml .images): %s" .Values.version (keys .Values.images | sortAlpha | join ", ")) -}}
{{- end -}}
{{- $img.templateID -}}
{{- end -}}


{{/*
kcluster.rev — revision hash of a machine template's spec.

This is what turns an edit into a rollout. Cluster API keys rollouts off the
*name* in infrastructureRef, so editing a template in place changes nothing —
the name has to carry a hash of the spec. Go sorts map keys when marshalling, so
the same spec always hashes the same, which also makes rollback work: revert the
form field and the previous template name comes back.
*/}}
{{- define "kcluster.rev" -}}
{{- toJson . | sha256sum | trunc 8 -}}
{{- end -}}


{{/*
kcluster.machineSpec — the ProxmoxMachineTemplate spec shared by the control
plane and every node pool. Built once so the same value is both hashed and
rendered; anything affecting the VM must go through here or changing it would
not trigger a rollout.

Call with (dict "root" $ "sizing" <pool-or-controlPlane> "role" "<name>").
*/}}
{{- define "kcluster.machineSpec" -}}
{{- $root := .root -}}
{{- $s := .sizing -}}
sourceNode: {{ $root.Values.infra.sourceNode }}
description: {{ printf "%s/%s — managed by Cluster API" (include "kcluster.clusterName" $root) .role | quote }}
{{- /*
  Required. CAPMOX only resizes the disk, attaches cloud-init and powers the VM
  on when the clone differs from its template, and the image-builder templates
  are untagged. Without this a VM clones, never starts, and CAPI still reports
  Provisioned=True.
*/}}
tags:
  - capi
templateID: {{ include "kcluster.templateID" $root }}
full: true
format: qcow2
storage: {{ $root.Values.infra.storage }}
numSockets: 1
numCores: {{ $s.numCores | default 2 }}
memoryMiB: {{ $s.memoryMiB | default 4096 }}
disks:
  bootVolume:
    disk: scsi0
    sizeGb: {{ $s.diskGb | default 40 }}
network:
  networkDevices:
    - name: net0
      bridge: {{ $root.Values.infra.bridge }}
      model: virtio
{{- end -}}
