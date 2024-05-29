output "blog_bucket_name" {
  value = module.blog_static_site.bucket_name
}

output "blog_distribution_id" {
  value = module.blog_static_site.cloudfront_distribution_id
}
