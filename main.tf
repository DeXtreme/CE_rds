terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.15.0"
    }
  }
}

resource "aws_db_subnet_group" "db" {
  name        = "db_subnet_group"
  description = "Public subnets group"
  subnet_ids  = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_db_instance" "db" {
  db_name                = local.db_name
  allocated_storage      = 20
  apply_immediately      = true
  identifier             = local.db_name
  db_subnet_group_name   = aws_db_subnet_group.db.name
  engine                 = "postgres"
  instance_class         = var.db_instance_type
  storage_type           = "gp2"
  multi_az               = true
  username               = var.rds_username
  password               = var.rds_password
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db.id]
}


resource "aws_security_group" "db" {
  vpc_id      = aws_vpc.vpc.id
  name        = "db_sg"
  description = "DB security group"

  ingress {
    to_port     = 5432
    from_port   = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_dms_endpoint" "db" {
  endpoint_id = "rds-db-endpoint"
  endpoint_type = "target"
  engine_name = "postgres"
  server_name = split(":",aws_db_instance.db.endpoint)[0]
  database_name = local.db_name
  ssl_mode = "require"
  port = 5432
  username               = var.rds_username
  password               = var.rds_password
}

resource "aws_dms_endpoint" "bastion" {
  endpoint_id = "ldb-endpoint"
  endpoint_type = "source"
  engine_name = "postgres"
  server_name = aws_instance.bastion.private_dns
  database_name = local.db_name
  port = 5432
  username               = var.ldb_username
  password               = var.ldb_password
}

resource "aws_dms_replication_subnet_group" "dm" {
  replication_subnet_group_id = "dm-subnet-group"
  replication_subnet_group_description = "Replication subnet group"
  subnet_ids = [ for subnet in aws_subnet.public: subnet.id ]
}

resource "aws_dms_replication_instance" "dm" {
  allocated_storage            = 20
  apply_immediately            = true
  multi_az                     = false
  publicly_accessible          = true
  replication_instance_class   = "dms.t2.micro"
  replication_instance_id      = "dm-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dm.id

  tags = {
    Name = "dms-instance"
  }
}

resource "aws_dms_replication_task" "dm" {
  replication_task_id = "dm-task"
  replication_instance_arn = aws_dms_replication_instance.dm.replication_instance_arn
  migration_type = "full-load"
  source_endpoint_arn = aws_dms_endpoint.bastion.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.db.endpoint_arn
  table_mappings = jsonencode({
    rules = [
        {
            rule-type = "selection"
            rule-id = "1"
            rule-name = "1"
            object-locator = {
                schema-name = "%"
                table-name = "%"
            }
            rule-action = "include"
        }
    ]
  })
}


data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-access-for-endpoint" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-access-for-endpoint"
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}