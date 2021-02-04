#!/bin/bash
# sudo yum install -y httpd
# sudo service httpd start
# sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
# cd /home/ec2-user
# wget https://wordpress.org/latest.tar.gz
# tar -xzf latest.tar.gz
# sudo cp -r wordpress/* /var/www/html/
# sudo cp /tmp/wp-config.php /var/www/html/wp-config.php
# chown -R apache:apache /var/www/html
# sudo service httpd restart

#!/bin/bash
sudo yum install -y httpd
sudo service httpd start
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
cd /home/ec2-user
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo cp -r wordpress/* /var/www/html/
curl CAMINHO_BUCKET/wp-config.php --output /var/www/html/wp-config.php #NECESSARIO COLOCAR O URL DO ARQUIVO NO BUCKET
chown -R apache:apache /var/www/html
sudo service httpd restart