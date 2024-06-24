# Wordpress on Ubuntu

WordPress instance on Ubuntu, along with:
- monitoring services 
- production tweaks
- security best practices
- infra-as-code

# Steps

## Point domain name 
- Point domain name to server

## Install Docker and docker-compose
```
vim install.sh
sh install.sh
```

## Setup Wordpress, MySQL and SWAG
```
su ubuntu 
cd 
vim docker-compose.yml
docker compose up
wget https://wordpress.org/latest.tar.gz
tar xvf latest.tar.gz -C /home/ubuntu/appdata/swag/www/
rm latest.tar.gz
vim appdata/swag/nginx/site-confs/default.conf
```

Change `root /config/www/wordpress`

`docker compose up -d`

Go to install Wordpress install

## Backup
- create script
- edit S3 bucket name
```
vim backup.sh
```
- create crontab
```
crontab -e
0 3 * * * sh /home/ubuntu/backup.sh >> /home/ubuntu/backup_$(date +\%Y\%m\%d).log 2>&1
```

## Create CloudWatch Alarms
- Install Terraform
- Check Terraform values aws_route53_health_check (fqdn)
- Check Terraform values aws_cloudwatch_metric_alarm (dimensions)
- Manually create alarm for healthcheck 
- Check EC2 role has CloudWatchAgentServerPolicy
- amazon-cloudwatch-agent should already be install on ubuntu 22.04 if not `sudo apt install amazon-cloudwatch-agent` or `wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb`
- Run the wizard
- sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
- Basic config
- Manually create the action for the alarm

## Reboots
- Docker automatically starts on reboot if install with package distro
- Supervisord to start docker compose
- sudo vim /etc/supervisor/conf.d/docker.conf
- sudo supervisorctl reread
- sudo supervisorctl update
- sudo supervisorctl

# Notes

## Do later

Docker secrets [x]
- Docker secrets may be different for each container 
- https://hub.docker.com/_/wordpress
- https://nginxproxymanager.com/advanced-config/#docker-file-secrets

Revise AWS CLI profile config without aws-vault

Plan ALB Terraform

Clean up MI AWS default security group port 80, 81

Clean up route 53

What happens if no session manager?

## Plan ALB 

Create SSL Cert with ACM
- root url 
- www subdomain

Create target group

Create ALB
- attach SSL
- point domain to target group

```
resource "aws_vpc" "singlei_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "singlei_subnet" {
  vpc_id            = aws_vpc.singlei_vpc.id
  cidr_block        = "10.0.0.0/24"
}

resource "aws_network_interface" "singlei_network" {
  subnet_id   = aws_subnet.singlei_subnet.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.singlei_vpc.id
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.singlei_vpc.id
}

resource "aws_route" "internet_gateway" {
  route_table_id         = aws_route_table.route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.singlei_subnet.id
  route_table_id = aws_route_table.route.id
}

resource "aws_acm_certificate" "singlei_cert" {
  domain_name       = "my-domain.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.my-domain.com"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "singlei_tg" {
  name     = "singlei-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.singlei_vpc.id
}

resource "aws_lb" "singlei_lb" {
  name               = "singlei-lb"
  internal           = false
  load_balancer_type = "application"
  subnets = [aws_subnet.singlei_subnet.id,aws_subnet.singlei_subnet_two.id]
}


resource "aws_instance" "singlei_instance" {
  ami = "ami-0fa377108253bf620"
  instance_type = "t2.micro"
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"
  associate_public_ip_address = "true"

  network_interface {
    network_interface_id = aws_network_interface.singlei_network.id
    device_index = 0
  }
}

```

## References

https://hub.docker.com/_/wordpress

https://api.wordpress.org/secret-key/1.1/salt/

https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes

https://stackoverflow.com/search?q=mysql+container+volume+back+up

https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file-wizard.html

https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps

https://gist.github.com/dahlsailrunner/679e6dec5fd769f30bce90447ae80081

https://docs.linuxserver.io/general/swag/#hosting-a-wordpress-site

https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
