- Terraform state file kept locally for quick test
- This Terraform code create 4 subnets ( one for apps, one for DBs, and two for ALB as it needs two availability zones)
- Default VPC was used to take benefits of already created resources like internet gateway 
- Apps: running with autoscaling group, allowing access on port 80 for a specific ips and for the subnets of the ALB
  Egress of the apps allowed to everything for now ( just to insatll httpd server for testing )
  User-data is being used to install httpd server with html running on port 80
  User-data script containt comments explain how temp access can be provided to example.com during startup time only.

- Mysql EC2 instance use user-data to install mysql, and security groups allow ingress to 3066 port for the app subnet only

- ALB are accepting access on 443, and forward it to 80 on app target group
  ALB not working with SSL certificate in the code, but diagram can show how to be implemented.

**Note**: The current terraform doesn't implement any proxy/firewall for inspections, which is need as per the problem statment, were accessed domains/content need to be inspected ( so egress access from our subnet should be always going for proxy in the middle for inspections)


![alt text](<Screenshot 2024-09-07 at 15.16.30.png>)











After running the terraform and accessing the ALB domain on 443
![alt text](<Screenshot 2024-09-07 at 14.52.53.png>)