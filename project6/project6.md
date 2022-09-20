## WEB Solution with WordPress
---
<br>

> ### **Step 1 - Launch an EC2 instance that will serve as “Web Server”.**
1. Launch an EC2 instance that will serve as "Web Server". Create 3 volumes in the same AZ as your Web Server EC2, each of 10 GiB.
![EC2 and EBS volume creation](images/EBS-volume.png)

2. Attach all three volumes one by one to your Web Server EC2 instance
![EBS attach](images/EBS-attach.png)

3. SSH into the EC2 instance
4. Use lsblk command to inspect what block devices are attached to the server. Notice names of your newly created devices. All devices in Linux reside in /dev/ directory. Inspect it with ls /dev/ and make sure you see all 3 newly created block devices there – their names will likely be xvdf, xvdh, xvdg.
```
$ lsblk
```
![View EBS devices](images/View-attached-devices.png)

5. Use df -h command to see all mounts and free space on your server
```
$ df -h
```

6. Use gdisk utility to create a single partition on each of the 3 disks
```
$ lsblk
$ sudo gdisk /dev/xvdf
```
![Create partition using gdisk utility](images/Create-partitions.png)

7. Repeat step 6 above for /dev/xvdg and /dev/xvdh. Run lsblk
```
$ lsblk
```
![All partitions created](images/All-partitions-created.png)

8. Install lvm2 package using sudo yum install lvm2. Run sudo lvmdiskscan command to check for available partitions.

9. Use pvcreate utility to mark each of 3 disks as physical volumes (PVs) to be used by LVM

```
$ sudo pvcreate /dev/xvdf1 /dev/xvdg1 /dev/xvdh1
```

10. Verify that your Physical volume has been created successfully by running sudo pvs

![pvs creeated](images/pvs-created.png)

11. Use vgcreate utility to add all 3 PVs to a volume group (VG). Name the VG webdata-vg
```
$ sudo vgcreate webdata-vg /dev/xvdh1 /dev/xvdg1 /dev/xvdf1
```
12. Verify that your VG has been created successfully by running sudo vgs

![vg created](images/vg-created.png)

13. Use lvcreate utility to create 2 logical volumes. apps-lv (Use half of the PV size), and logs-lv Use the remaining space of the PV size. NOTE: apps-lv will be used to store data for the Website while, logs-lv will be used to store data for logs.

```
$ sudo lvcreate -n apps-lv -L 14G webdata-vg
$ sudo lvcreate -n logs-lv -L 14G webdata-vg
```
14. Verify that your Logical Volume has been created successfully by running sudo lvs

![lvs created](images/lvs-created.png)

15. Verify the entire setup
```
$ sudo vgdisplay -v #view complete setup - VG, PV, and LV
$ sudo lsblk 
```
![Complete setup](images/complete-setup.png)

16. Use mkfs.ext4 to format the logical volumes with ext4 filesystem
```
sudo mkfs -t ext4 /dev/webdata-vg/apps-lv
sudo mkfs -t ext4 /dev/webdata-vg/logs-lv
```

17. 

Create /var/www/html directory to store website files
```
sudo mkdir -p /var/www/html
```
18. Create /home/recovery/logs to store backup of log data
```
sudo mkdir -p /home/recovery/logs
```

19. Mount /var/www/html on apps-lv logical volume. NB: This will format /var/www/html therefore copy the needed contents to another directory before mounting.
```
ls -l /var/www/html

sudo mount /dev/webdata-vg/apps-lv /var/www/html/
```

20. Use **rsync** utility to backup all the files in the log directory /var/log into /home/recovery/logs (This is required before mounting the file system)
```
sudo rsync -av /var/log/. /home/recovery/logs/
```

21. Mount /var/log on logs-lv logical volume. (Note that all the existing data on /var/log will be deleted. That is why step 15 above is very important)
```
sudo mount /dev/webdata-vg/logs-lv /var/log
```
22. Restore log files back into /var/log directory
```
sudo rsync -av /home/recovery/logs/. /var/log
```

23. Update /etc/fstab file so that the mount configuration will persist after restart of the server.
<br>
Use below command to check the UUID of the devices. (Copy it out)
```
$ sudo blkid
```
![Device UUID](images/blockID.png)

```
$ sudo vim /etc/fstab
```
Update /etc/fstab and rememeber to remove the leading and ending quotes on the UUID.

![fstab file](images/fstab-file.png)

24. Test the configuration and reload the daemon
```
 sudo mount -a
 sudo systemctl daemon-reload
```

25. Verify your setup by running df -h

![Working Setup](images/working-setup.png)

<br>

> ### **Step 2 — Prepare the Database Server**

1. Launch a second RedHat EC2 instance that will have a role – ‘DB Server’
Repeat the same steps as for the Web Server, but instead of apps-lv create db-lv and mount it to /db directory instead of /var/www/html/.

> ### **Step 3 — Install WordPress on your Web Server EC2**
<br>

1. Update the repository
```
sudo yum -y update
```

2. Install wget, Apache and it’s dependencies
```
sudo yum -y install wget httpd php php-mysqlnd php-fpm php-json
```
3. Start Apache
```
sudo systemctl enable httpd
sudo systemctl start httpd
```

4. To install PHP and it’s depemdencies
```
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum install yum-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module list php
sudo yum module reset php
sudo yum module enable php:remi-7.4
sudo yum install php php-opcache php-gd php-curl php-mysqlnd
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
setsebool -P httpd_execmem 1
```

5. Restart Apache
```
sudo systemctl restart httpd
```

6. Download wordpress and copy wordpress to var/www/html
```
  mkdir wordpress
  cd   wordpress
  sudo wget http://wordpress.org/latest.tar.gz
  sudo tar xzvf latest.tar.gz
  sudo rm -rf latest.tar.gz
  cp wordpress/wp-config-sample.php wordpress/wp-config.php
  cp -R wordpress /var/www/html/
```

7. Configure SELinux Policies
```
  sudo chown -R apache:apache /var/www/html/wordpress
  sudo chcon -t httpd_sys_rw_content_t /var/www/html/wordpress -R
  sudo setsebool -P httpd_can_network_connect=1
```

> ### **Step 4 — Install MySQL on your DB Server EC2**
1. Install mysql-server
```
sudo yum update
sudo yum install mysql-server
```

2. Verify that the service is up and running by using sudo systemctl status mysqld, if it is not running, restart the service and enable it so it will be running even after reboot:
```
sudo systemctl restart mysqld
sudo systemctl enable mysqld
```

> ### **Step 5 — Configure DB to work with WordPress**
```
sudo mysql
CREATE DATABASE wordpress;
CREATE USER `myuser`@`<Web-Server-Private-IP-Address>` IDENTIFIED BY 'mypass';
GRANT ALL ON wordpress.* TO 'myuser'@'<Web-Server-Private-IP-Address>';
FLUSH PRIVILEGES;
SHOW DATABASES;
exit
```

> ### **Step 6 — Configure WordPress to connect to remote database.**

Hint: Do not forget to open MySQL port 3306 on DB Server EC2. For extra security, you shall allow access to the DB server ONLY from your Web Server’s IP address, so in the Inbound Rule configuration specify source as /32

![Activate MYSQL Port 3306](images/activate-mysql-port.png)


1. Install MySQL client and test that you can connect from your Web Server to your DB server by using mysql-client
```
sudo yum install mysql
sudo mysql -u admin -p -h <DB-Server-Private-IP-address>
```
2. Verify if you can successfully execute SHOW DATABASES; command and see a list of existing databases.
![Show DB](images/show-db.png)

3. Change permissions and configuration so Apache could use WordPress:
```
sudo chown -R apache:apache /var/www/html/wordpress
```

4. Enable TCP port 80 in Inbound Rules configuration for your Web Server EC2 (enable from everywhere 0.0.0.0/0 or from your workstation’s IP)

5. Try to access from your browser the link to your WordPress <br> 
http://<Web-Server-Public-IP-Address>/wordpress/

![WordPress Select Language](images/wordpress-select-lang.png)

![WordPress HomePage 1](images/wordpress-home-1.png)

![WordPress Setup 1](images/Wordpress-setup.png)

![WordPress Setup 2](images/Wordpress-setup-2.png)

![HomePage](images/myapp-homepage.png)
