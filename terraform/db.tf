/*
This terraform file creates a basic postgresql RDS instance, 
which is public facing (only because app runner cann't access it otherwise)
*/

resource "aws_security_group" "allow_postgres_public" {
  name        = "allow_postgres_public"
  description = "Allow postgres inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress = [
    {
      description      = "postgres from public..  "
      from_port        = 5432
      to_port          = 5432
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self = true
      security_groups = []
      prefix_list_ids = []
    }
  ]

  egress = [
      {
      description      = "postgres to public..  "
      from_port        = 5432
      to_port          = 5432
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self = true
      security_groups = []
      prefix_list_ids = []
    }
  ]

  tags = {
    Name = "allow_postgres_public"
  }

  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_db_subnet_group" "alula_db_subnet" {
  name       = "alula_db_subnet"
  subnet_ids = [
    aws_subnet.public.id,
    aws_subnet.public2.id
  ]
  tags = {
    Name = "My DB subnet group"
  }
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_db_instance" "alula_db" {
  allocated_storage    = 10
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  name                 = "mtapp"
  username             = "mtapp"
  password             = "test123_abcd"
  publicly_accessible = true
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.alula_db_subnet.name
  vpc_security_group_ids = [aws_security_group.allow_postgres_public.id]
  depends_on = [
    aws_security_group.allow_postgres_public,
    aws_db_subnet_group.alula_db_subnet,
    aws_internet_gateway.gw
  ]
}

output "alula_db_endpoint" {
    value = aws_db_instance.alula_db.endpoint
}
