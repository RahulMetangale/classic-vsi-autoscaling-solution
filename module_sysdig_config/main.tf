terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.53.0"
    }
    sysdig = {
      source = "sysdiglabs/sysdig"
      version = "1.6.0"
    }
  }
}
resource "sysdig_monitor_alert_metric" "scale_up_alert" {
  count = length(var.scale_up_alerts_config)
  name        =  "${var.scale_up_alert_name}-${count.index}"
  description = "Load balancer alert for scale up"
  severity    = 5
  metric                = "sum(avg(ibm_cloud_load_balancer_active_connections)) > ${var.scale_up_alerts_config[count.index]["upper_threshold"]} and sum(avg(ibm_cloud_load_balancer_active_connections)) <= ${var.scale_up_alerts_config[count.index]["lower_threshold"]}"   
  trigger_after_minutes = 2
  notification_channels = [sysdig_monitor_notification_channel_webhook.cf_webhook_channel[count.index].id]
}

resource "sysdig_monitor_notification_channel_webhook" "cf_webhook_channel" {
  count = length(var.scale_up_alerts_config)
  name                    = "Cloud-Function-Scale-Up-Webhook-${count.index}"
  enabled                 = true
  url                     = "https://us-east.functions.appdomain.cloud/api/v1/web/8d4aff83-9ed7-449d-b888-9e5f92e5de8f/default/autoscaleaction?vmcount=+2"
  notify_when_ok          = false
  notify_when_resolved    = false
  send_test_notification  = false
}

resource "sysdig_monitor_alert_metric" "scale_down_alert" {
  name        =  var.scale_down_alert_name
  description = "Load balancer alert for scale down"
  severity    = 5
  metric                = "sum(avg(ibm_cloud_load_balancer_active_connections)) >= ${var.scaledown_lower_threshold} and sum(avg(ibm_cloud_load_balancer_active_connections)) <= ${var.scaledown_upper_threshold}"
  trigger_after_minutes = 15
  notification_channels = [sysdig_monitor_notification_channel_webhook.cf_webhook_scaledown_channel.id]
}

resource "sysdig_monitor_notification_channel_webhook" "cf_webhook_scaledown_channel" {
    name                    = "Cloud-Function-Scale-Down-Webhook"
    enabled                 = true
    url                     = "https://us-east.functions.appdomain.cloud/api/v1/web/8d4aff83-9ed7-449d-b888-9e5f92e5de8f/default/autoscaleaction?vmcount=-2"
    notify_when_ok          = false
    notify_when_resolved    = false
    send_test_notification  = false
}