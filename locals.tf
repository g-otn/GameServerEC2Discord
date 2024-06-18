locals {
  title            = title(var.name)
  title_PascalCase = replace(local.title, "/\\W|_|\\s/", "")

  myipv4 = "${chomp(data.http.myipv4.response_body)}/32"
}
