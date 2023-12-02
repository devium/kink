resource "wikijs_group" "admin" {
  name        = "admin"
  page_rules  = []
  permissions = ["manage:system"]
}

resource "wikijs_group" "default" {
  name = "default"
  page_rules = [
    {
      deny  = false
      match = "START"
      roles = [
        "read:pages",
        "write:pages",
        "manage:pages",
        "delete:pages",
        "write:styles",
        "read:source",
        "read:history",
        "read:assets",
        "read:comments",
        "write:comments"
      ]
      path    = ""
      locales = []
    }
  ]
  permissions = [
    "read:pages",
    "write:pages",
    "manage:pages",
    "delete:pages",
    "write:styles",
    "read:source",
    "read:history",
    "read:assets",
    "read:comments",
    "write:comments"
  ]
}
