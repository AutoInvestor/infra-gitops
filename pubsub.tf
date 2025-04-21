locals {
  topics = {
    "market-feeling"  = ["decision-making", "alerts"],
    "users"           = ["portfolio", "alerts"],
    "decision-making" = ["alerts"],
    "alerts"          = [],
    "portfolio"       = ["alerts"],
    "core"            = ["market-feeling", "decision-making", "alerts"]
  }

  subscriptions = merge([for item in flatten([
    for topic, subscribers in local.topics : {
      for subscriber in subscribers :
      "${subscriber}-to-${topic}" => topic
    }
  ]) : item]...)
}

# Publishers

resource "google_pubsub_topic" "topic" {
  for_each = local.topics

  name = each.key
}

# Subscribers

resource "google_pubsub_subscription" "subscription" {
  for_each = local.subscriptions

  name  = each.key
  topic = google_pubsub_topic.topic[each.value].id

  ack_deadline_seconds = 60
  message_retention_duration = "86400s"
}
