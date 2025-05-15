locals {
  topics = {
    "market-feeling"  = ["decision-making", "alerts"],
    "users"           = ["portfolio", "alerts"],
    "decision-making" = ["alerts"],
    "alerts"          = [],
    "portfolio"       = ["alerts"],
    "core"            = ["market-feeling", "decision-making", "alerts"],
    "news-scraper"    = ["market-feeling"],
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
  depends_on = [google_project_service.active_api]

  for_each = local.topics

  name = each.key
}

resource "google_pubsub_topic" "dlq_topic" { # Como este topic no tiene subscribers el mensaje simplemente desaparece
  depends_on = [google_project_service.active_api]

  name = "dead-letter-topic"
}

# Subscribers

resource "google_pubsub_subscription" "subscription" {
  for_each = local.subscriptions

  name  = each.key
  topic = google_pubsub_topic.topic[each.value].id

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq_topic.id
    max_delivery_attempts = 5
  }

  ack_deadline_seconds       = 60
  message_retention_duration = "86400s"
}
