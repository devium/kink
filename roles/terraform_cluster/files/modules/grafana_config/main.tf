data "http" "jitsi_system_json" {
  url = "https://raw.githubusercontent.com/systemli/prometheus-jitsi-meet-exporter/${var.versions.jitsi_prometheus_exporter}/dashboards/jitsi-meet-system.json"
}

data "http" "jitsi_json" {
  url = "https://raw.githubusercontent.com/systemli/prometheus-jitsi-meet-exporter/${var.versions.jitsi_prometheus_exporter}/dashboards/jitsi-meet.json"
}

data "http" "nginx_json" {
  url = "https://raw.githubusercontent.com/nginxinc/nginx-prometheus-exporter/v${var.versions.nginx_prometheus_exporter}/grafana/dashboard.json"
}

resource "grafana_dashboard" "jitsi_system" {
  config_json = replace(data.http.jitsi_system_json.response_body, "\"$${DS_PROMETHEUS}\"", "\"prometheus\"")
  overwrite   = true
}

resource "grafana_dashboard" "jitsi" {
  config_json = replace(data.http.jitsi_json.response_body, "\"$${DS_PROMETHEUS}\"", "\"prometheus\"")
  overwrite   = true
}

resource "grafana_dashboard" "nginx" {
  config_json = replace(data.http.nginx_json.response_body, "\"$${DS_PROMETHEUS}\"", "\"prometheus\"")
  overwrite   = true
}
