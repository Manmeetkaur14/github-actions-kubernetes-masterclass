# Project: SkillPulse
# File: monitoring.tf
# Description: Installs Monitoring stack (Prometheus only)

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Prometheus Stack (includes Grafana)
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "61.7.0"

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
  }

  set {
    name  = "grafana.grafana\\.ini.server.serve_from_sub_path"
    value = "true"
  }

  set {
    name  = "grafana.sidecar.dashboards.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "grafana.ingress.path"
    value = "/grafana"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "serverFiles.alerting_rules\\.yml.groups[0].name"
    value = "node-alerts"
  }

  set {
    name  = "serverFiles.alerting_rules\\.yml.groups[0].rules[0].alert"
    value = "HighCPUUsage"
  }

  set {
    name  = "serverFiles.alerting_rules\\.yml.groups[0].rules[0].expr"
    value = var.environment == "prod" ? "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80" : "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 95"
  }
}
