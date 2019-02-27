resource "aws_security_group" "redis" {
  count       = "${var.create_elasticache ? 1 : 0}"
  name        = "${var.customer}-${var.project}-${var.elasticache_engine}-${lookup(var.short_region, var.aws_region)}-${var.env}"
  description = "${var.elasticache_engine} ${var.env} for ${var.project}"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = "${var.elasticache_port}"
    to_port   = "${var.elasticache_port}"
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.front.id}",
    ]
  }

  tags {
    Name       = "${var.customer}-${var.project}-${var.elasticache_engine}-${lookup(var.short_region, var.aws_region)}-${var.env}"
    client     = "${var.customer}"
    env        = "${var.env}"
    project    = "${var.project}"
    role       = "redis"
    cycloid.io = "true"
  }
}

resource "aws_elasticache_cluster" "redis" {
  count                = "${var.create_elasticache ? 1 : 0}"
  cluster_id           = "${var.project}${count.index}-${var.env}"
  engine               = "${var.elasticache_engine}"
  engine_version       = "${var.elasticache_engine_version}"
  node_type            = "${var.elasticache_type}"
  port                 = "${var.elasticache_port}"
  num_cache_nodes      = "${var.elasticache_nodes}"
  parameter_group_name = "${var.elasticache_parameter_group_name}"
  security_group_ids   = ["${aws_security_group.redis.id}"]
  subnet_group_name    = "${var.cache_subnet_group != "" ? var.cache_subnet_group : aws_elasticache_subnet_group.cache-subnet.id}"
  apply_immediately    = true
  maintenance_window   = "tue:06:00-tue:07:00"

  tags {
    Name       = "${var.customer}-${var.project}-${var.elasticache_engine}-${lookup(var.short_region, var.aws_region)}-${var.env}"
    client     = "${var.customer}"
    env        = "${var.env}"
    project    = "${var.project}"
    cycloid.io = "true"
  }
}

resource "aws_elasticache_subnet_group" "cache-subnet" {
  name        = "cycloid-sub-cache-${var.vpc_id}-${var.env}"
  count       = "${var.cache_subnet_group == "" && var.create_elasticache ? 1 : 0}"
  description = "redis cache subnet for ${var.vpc_id}"
  subnet_ids  = ["${var.private_subnets_ids}"]
}

output "elasticache_address" {
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
}
