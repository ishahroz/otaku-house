<h1 align=center>Otaku House - Anime Merchandise and Cosplay Shop</h1>
<h2 align=center>E-Commerce Website with Django + React & Redux + AWS</h2>

## ✨ [Live Link - Otaku House](http://otaku-house-frontend.s3.amazonaws.com/index.html)

## Services Used 🚀

- **VPC**: Networking and Content Delivery 🌐
- **EC2 (Bastion, Private Django, ALB)**: Compute 💻
- **CodeDeploy**: Developer Tools 🛠️
- **S3**: Storage 📦
- **RDS**: Database 🗄️
- **AWS Secrets Manager**: Security, Identity, and Compliance 🔒
- **CloudWatch**: Management and Governance 📈

## Django Admin Credentials 🔑

- **Email**: admin@test.com
- **Username**: admin
- **Password**: admin

## Whole Project Setup 🛠️

### Part 1: VPC Setup 🌐

1. **Create VPC**:

   - Go to the VPC Dashboard.
   - Click on **Create VPC**.
   - VPC only.
   - Name: `otaku-house-vpc`.
   - Choose the VPC and select a CIDR block (e.g., `10.0.0.0/24`).

   ```text
   ○	A total of 256 addresses
   ○	Network Address: 10.0.0.0
   ○	First Usable Address: 10.0.0.1
   ○	Last Usable Address: 10.0.0.254
   ○	Broadcast Address: 10.0.0.255
   ```

2. **Create Subnets**:

   - Choose `otaku-house-vpc`.
   - Create a public subnet in `us-east-1a` with CIDR block `10.0.0.0/25` => `otaku-house-public-subnet`.
   - Create a private subnet in `us-east-1b` with CIDR block `10.0.0.128/25` => `otaku-house-private-subnet`.

3. **Create Internet Gateway**:

   - Name: `otaku-house-igw`.
   - Attach the Internet Gateway to our VPC.

     **Create NAT Gateway**:

   - Name: `otaku-house-ngw`.
   - Subnet: `otaku-house-public-subnet`.
   - Allocate Elastic IP.

4. **Update Route Tables**:
   - Choose `otaku-house-vpc`.
   - Create a route table for the public subnet => `otaku-house-public-rt`.
   - Add a route to the Internet Gateway (`0.0.0.0/0 -> Internet Gateway`).
   - Subnet association with the public subnet.
   - Create a route table for the private subnet => `otaku-house-private-rt`.
   - Add a route to the NAT Gateway (`0.0.0.0/0 -> NAT Gateway`).
   - Associate the route table with the private subnet.

### Part 2: Set Up Bastion Host in the Public Subnet 🏠

1. **Launch EC2 Instance (Bastion Host)**:

   - Name: `otaku-house-django-bastion-host`.
   - KeyPair: `otaku-house-django-bastion`.
   - VPC: `otaku-house-vpc`.
   - Public Subnet.
   - Auto-assign public IP: Enable.
   - Security Group: `otaku-house-django-bastion-sg`.
   - Configure the security group to allow SSH access from your IP.
   - IAM Role: `LabInstanceProfile`.

   **User Data**:

   ```bash
   # Update the package repository
   sudo dnf update -y
   # Install MariaDB for later connection with RDS
   sudo dnf install mariadb105
   ```

2. **SSH into Bastion Host**:

   ```bash
   # Give reads permissions and remove all others
   chmod 400 otaku-house-django-bastion.pem

   # SSH Template to Bastion Host
   ssh -i your-key.pem ec2-user@<Bastion-Host-Public-IP>

   # Example Usage
   ssh -i otaku-house-django-bastion.pem ec2-user@18.209.230.117
   ```

### Part 3: Set Up Private EC2 Instance for Django in the Private Subnet 🖥️

1. **Launch EC2 Instance (Django Server)**:

   - Name: `otaku-house-django`.
   - KeyPair: `otaku-house-django-ec2`.
   - VPC: `otaku-house-vpc`.
   - Ensure Auto-assign Public IP is disabled.
   - Subnet: `otaku-house-private-subnet`.
   - Security Group: `otaku-house-django-sg`.
   - Source for Inbound Bastion: `otaku-house-django-bastion-sg`.
   - IAM Instance Profile: `LabInstanceProfile`.

   **User Data**:

   ```bash
   #!/usr/bin/env bash

   # Update the package repository
   sudo yum -y update

   # Install Ruby
   sudo yum -y install ruby

   # Install wget
   sudo yum -y install wget

   # Install MariaDB
   sudo dnf install mariadb105

   # Navigate to the home directory
   cd /home/ec2-user

   # Download the CodeDeploy agent installer
   wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install

   # Make the installer executable
   sudo chmod +x ./install

   # Run the installer
   sudo ./install auto

   # Start the CodeDeploy agent
   sudo service codedeploy-agent start
   ```

2. **SSH into Django EC2**:

   ```bash
    # Give reads permissions and remove all others
   chmod 400 otaku-house-django-bastion.pem
   chmod 400 otaku-house-django-ec2.pem

    # To start an SSH agent
   eval "$(ssh-agent -s)"


   ssh-add otaku-house-django-bastion.pem
   ssh-add otaku-house-django-ec2.pem

    # To SSH to Bastion
   ssh -A -i otaku-house-django-bastion.pem ec2-user@18.209.230.117

    # To SSH to Django from Bastion
   ssh -A -i . ec2-user@10.0.0.200
   ```

   **Check Code Deploy Agent Status**:

   ```bash
   sudo service codedeploy-agent status
   ```

### Part 4: Set Up CodeDeploy 🚀

1. **Create Application**:

   - Name: `otaku-house-django-dep-app`.
   - Platform: EC2/on-premise.

2. **Create Deployment Group**:

   - Name: `otaku-house-django-dep-group`.
   - Service Role: `LabRole`.
   - Deployment type: In-place.
   - Environment configuration: Amazon EC2 instances.
   - Name: `otaku-house-django`.
   - Deployment settings: All At Once.
   - De-select Load Balancing.

3. **Create Deployment**:

   - Source: GitHub.
   - Token Name: `ishahroz`.
   - Repo Name: `ishahroz/otaku-house`.
   - Commit Hash: [your_commit_hash].

4. **Verify Deployment**:
   - It uses `appspec.yml` and the `scripts` folder in the backend code.

### Part 5: Set Up RDS Instance in VPC (No Public Access) 🗄️

- **Database Engine**: MariaDB (standard create) (due to restrictions on other DB engines).
- **Instance Specifications**:

  - Dev/Test
  - Name: `otaku-house-rds`.
  - Username: `ishahroz`.
  - Password: `<DBPASS>`.
  - Burstable Instance Class: T3.micro.
  - Storage: GP2 SSD, 20 GB.
  - Create a standby instance (recommended for production usage)
  - Multi-AZ Deployment: Yes.
  - Backup Enabled.

- **Network and Security**:
  - VPC: `otaku-house-vpc`.
  - Public Access: No.
  - Security Groups: `otaku-house-django-sg`, `otaku-house-django-bastion-sg`.
  - Port: 3306.
  - Encryption: Enabled.

### Part 6: Configure Security Groups for RDS Instance 🔒

- **Security Groups**:

  - `otaku-house-django-sg`
  - `otaku-house-django-bastion-sg`

- **Inbound Rules**:
  - Type: Custom TCP Rule.
  - Protocol: TCP.
  - Port Range: 3306.
  - Source: Self (allow requests from the same SG, like a loop).

### Part 7: Test RDS Connection

- **SSH to Bastion Host and Django EC2**:

  - Install MariaDB (if not installed already): `sudo dnf install mariadb105`.
  - Connect to RDS:

  ```bash
  # Template
  mysql -h <RDS-endpoint> -u <username> -p

  # Usage
  mysql -h otaku-house-rds.cxyudt4ai3nq.us-east-1.rds.amazonaws.com -u ishahroz -p
  ```

- **Create Database**:

  ```sql
  CREATE DATABASE `otaku-house-db`;
  ```

### Part 8: Build and Upload React App to S3

- **Build React App**:

  ```bash
  npm run build
  ```

- **S3 Setup**:

  - Bucket Name: `otaku-house-frontend`.
  - Uncheck "Block all public access".
  - Enable Bucket Versioning.
  - Upload Build Files.
  - Enable Static Website Hosting.

- **Bucket Policy for Public Access**:

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::otaku-house-frontend/*"
      }
    ]
  }
  ```

  - Test Webpage at: http://otaku-house-frontend.s3.amazonaws.com/index.html

### Part 9: Create an Application Load Balancer For Private Django EC2 ⚖️

- **Create Load Balancer**:

  - Choose "Application Load Balancer".
  - Name: `otaku-house-alb`.
  - Scheme: internet-facing.
  - IP address type: ipv4.
  - Select the VPC where your Django EC2 instance is running.
  - Select the public subnet because we want to place ALB in the public subnet since it is connected to the internet gateway (for receiving traffic from the internet).
  - Create a new security group for ALB (`otaku-house-alb`) with inbound traffic on ports `80` and `443` with source `anywhere`.

- **Create Target Group**:

  - Choose "Instances as the target type.
  - Name: `otaku-house-target-group`.
  - Protocol: HTTP.
  - Port: 8000 (or the port your Django app is running on).
  - VPC: Select the VPC where your EC2 instances are located.
  - Health check protocol: HTTP.
  - Health check path: /api/products (or any valid endpoint on your Django API for health checks).
  - Select the EC2 instances where your Django application is running.
  - Click "Include as pending below."

- **Configure Listeners**:

  - Add a listener for HTTP on port 80 and optionally for HTTPS on port 443.
  - Select the security group associated with your Django EC2 instance.
  - Add inbound rule to allow traffic from the ALB.
  - Set the protocol to TCP and the port range to 8000 (or the port your Django app is running on).
  - Source: Security group of the ALB.

- **Access the Website using ALB DNS**:
  - Make sure the URL starts with HTTP only.
  - Listener to HTTPs was also set in ALB but Django server can’t handle HTTPS requests because it requires SSL certificates and domain CNAME configurations.

### Part 10: Update React Build with ALB DNS 🔄

- **Update `DJANGO_PROD_API_ALB_URL`** with ALB DNS.
- Upload the updated build.
- Also upload the media folder from the Django directory.

- **Test Page**:
  - http://otaku-house-frontend.s3.amazonaws.com/index.html#/

### Part 11: Create an AWS Secrets Manager Secret 🔑

- **Secret Details**:
  ```json
  {
    "DB_NAME": "otaku-house-db",
    "DB_USER": "<DB_USER>",
    "DB_PASSWORD": "<DB_PASSWORD>",
    "DB_HOST": "otaku-house-rds.cxyudt4ai3nq.us-east-1.rds.amazonaws.com",
    "DB_PORT": "3306"
  }
  ```
- Name: `otaku-house-rds-secret`.

### Part 12: Backup SQLite Data 💾

- **Command**:
  ```bash
  python manage.py dumpdata > sqlite_db_data.json
  ```
- Here, Content Types fixture should be removed from the above file since they are created during the migration process itself.

### Part 13: Update Django `settings.py` ⚙️

- Install Boto3 in the virtual environment.
- Update `settings.py` to load secrets.
- Update DB backend (hashmap).

### Part 14: Run Initial Migrations by SSHing to Django EC2 🗄️

- **Commands**:
  ```bash
  cd ../ubuntu/otaku-house
  source venv/bin/activate
  python3 manage.py runserver 0:8000
  python manage.py makemigrations
  python manage.py migrate
  ```

### Part 15: Load Data to RDS 📊

- **Command**:
  ```bash
  python manage.py loaddata sqlite_db_data.json
  ```

### Part 16: Run Django Server and Verify the DB Data ✅

- **Run the Django Server**:

  ```bash
  python manage.py runserver 0.0.0.0:8000
  ```

- **Verify the DB Data**:
  - SSH to RDS through Bastion Host.

### Part 17: Check the Frontend Website 🌐

- **URL**:
  - http://otaku-house-frontend.s3.amazonaws.com/index.html#/

### 📷 Project Screenshots

![ss](./ss/ss1.png)
![ss](./ss/ss2.png)
![ss](./ss/ss3.png)
![ss](./ss/ss4.png)
![ss](./ss/ss5.png)
![ss](./ss/ss6.png)

### 🚀 Project Features

A completely customized eCommerce / shopping cart application using Django, REACT and REDUX with the following functionality:

- Full-featured shopping cart
- Product reviews and Ratings
- Top products carousel
- Product pagination
- Product search feature
- User profile with orders
- Admin product management
- Admin user management
- Admin Order details page
- Mark orders as a delivered option
- Checkout process (shipping, payment method, etc)
- PayPal / credit card integration
