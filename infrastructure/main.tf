module "blog_static_site" {
  source = "git@github.com:jk563/terraform-static-website"
  providers = {
    aws.us-east-1 = aws.us-east-1
  }

  fqdn           = var.fqdn
  force_destroy = true
}
