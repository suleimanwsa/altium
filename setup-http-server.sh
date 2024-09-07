#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hey Altium" > /var/www/html/index.html



# attach security group which allow access to example.com to the instance 

# download package from example.com
# check if package downloaded
# if yes, continue then revoke the rule that allowed access to example.com "so access allowed on startup only"
# if no, aws cli to terminate the instance or restart/re-try to download  " as it's mentioned, app won't work without it"