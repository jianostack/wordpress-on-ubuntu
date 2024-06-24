resource "aws_s3_bucket" "s3" {
  bucket = "jjj-temp-test-bucket"
}

resource "aws_route53_health_check" "healthcheck" {
  fqdn              = "james.massiveinfinity.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name                = "jjj-alarm-disk-used"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  threshold                 = 80
  alarm_description         = "This metric monitors ec2 disk used percent"
  insufficient_data_actions = []

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "disk_used_percent"
      namespace   = "CWAgent"
      period      = 300
      stat        = "Average"

      dimensions = {
        InstanceId = "i-0d2e2bc8216feba47"
        path = "/"
        ImageId = "ami-0fa377108253bf620"
        fstype = "ext4"
        device = "xvda1"
        InstanceType = "t2.small"
      }
    }
  }

}

/*

resource "aws_instance" "instance" {
  ami = "ami-0fa377108253bf620"
  instance_type = "t2.small"
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"
  associate_public_ip_address = "true"
}

*/

