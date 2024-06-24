#/bin/bash
tar cvf appdata_$(date +\%Y\%m\%d).tar 2>&1 /home/ubuntu/appdata
aws s3 cp appdata_$(date +\%Y\%m\%d).tar 2>&1 s3://bucket-name/appdata_$(date +\%Y\%m\%d).tar 2>&1
tar cvf uploads_$(date +\%Y\%m\%d).tar 2>&1 /home/ubuntu/appdata/swag/www/wordpress/wp-content/uploads
aws s3 cp uploads_$(date +\%Y\%m\%d).tar 2>&1 s3://bucket-name/uploads_$(date +\%Y\%m\%d).tar 2>&1
