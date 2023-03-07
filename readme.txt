Problem:
![alt text](https://github.com/PRATEEKVERMA-036/dbre_assignment/blob/main/Screenshot_20230307_223607_Samsung%20Internet.jpg?raw=true)



How to run the provision------------------>

1. Install Terraform: To use Terraform, you must first install it on your local machine. You can download the latest version of Terraform from the official website (https://www.terraform.io/downloads.html).

2. Set up a GCP project: If you don't already have a GCP project, you can create a new one in the GCP Console. Make sure to enable the necessary APIs for the resources you plan to create in Terraform.

3. Set up a Google Cloud Storage (GCS) bucket: Terraform state files should be stored remotely, for example in a Google Cloud Storage bucket. You can create a new bucket in the GCP Console.

4. Downloading and configuring Google Cloud SDK
Now that we have Terraform installed, we need to set up the command line utility to interact with our services on Google Cloud Platform. This will allow us to authenticate to our account on Google Cloud Platform and subsequently use Terraform to manage infrastructure.


Download and install Google Cloud SDK:

$ curl https://sdk.cloud.google.com | bash

Initialize the gcloud environment:

$ gcloud init

You’ll be able to connect your Google account with the gcloud environment by following the on-screen instructions in your browser. If you’re stuck, try checking out the official documentation (https://cloud.google.com/sdk/docs/install).



5. Write your Terraform script: Terraform scripts are written in the HashiCorp Configuration Language (HCL). You can use Terraform modules and providers to define the desired state of your infrastructure in GCP.

6. Initialize Terraform: Before you can use Terraform, you need to initialize it by running the following command:

 terraform init

7. Plan your Terraform script: Before you apply the Terraform script, you can preview what changes Terraform will make by running the following command:
 terraform plan

8. Apply your Terraform script: To apply the Terraform script and create the desired infrastructure in GCP, run the following commandS
 terraform apply

9. Manage your Terraform state: As you make changes to your infrastructure in GCP, Terraform will keep track of the state of your infrastructure. You should periodically run terraform plan and terraform apply to make sure Terraform is aware of any changes you make in GCP.




Here are the detailed steps to authenticate Terraform with your GCP account------------------>

1. Create a service account: In GCP, navigate to the "IAM & Admin" section of the Cloud Console. Then, click on the "Service Accounts" tab and create a new service account.

2. Assign the appropriate role: Assign the role of "Editor" to the service account you just created. This will give Terraform the necessary permissions to create and manage resources in your GCP project.

3. Generate a private key: After you've created the service account and assigned it the necessary role, you can generate a private key for the service account. In the Cloud Console, click on the three dots next to the service account you just created, and then click on "Create key." Choose the JSON key format and download the private key to your local machine.

4. Set the environment variable: Terraform needs to know where the private key file is located. You can set an variable named CREDENTIALs that points to the location of the private key file. For example, if the file is located at /path/to/keyfile.json, you would run the following command:
 credentials = file("/path/to/keyfile.json")

 I have placed it inside provider.

5. Test authentication: To test that Terraform can authenticate with your GCP account, you can run the following command:
  gcloud auth application-default login

This should display a message indicating that you are authenticated.




Explaning all part of terraform scripts------------------>


Credentials File Path: 
Before proceeding to code any further, you need to insert the location of the GCP Service Account key file. This needs to be declared in the credentials variable inside the provider block.

Google API Version: 
You will also need to specify which version of the Google Cloud Platform you are using in the config. To do this, you can declare a variable called “version”.

Project: 
In order to work with the cloud project, you will need to create a project name that is unique. You need to specify the details of the project within the project variable inside the provider block.

Region: 
You also have to set the region where you would like the GCP resources to be created. The details of these are to be specified in the region variable.

VPC Network: 
To ensure that all the resources on the cloud platform remain secure, it is highly encouraged to create a VPC network. You can then use this as an interface to create other resources within your cloud project. You can set the name of the VPC network inside the name variable within the google_compute_network block.

VPC Subnetwork: 
Once you have created the VPC network, you can create a subnet for it. This will help in segregating resources from each other and also allow you to specify an IP address range for it. You can configure the details of this subnet in the google_compute_subnetwork block by setting the name and IP address range inside the name and ip_cidr_range variables respectively. Ensure that you also specify the resource link of the parent VPC Network in the network variable of the google_compute_subnetwork block, so that Terraform understands which subnet to create.

Primary DB: 
With the initialization of the subnet and the requirements set up, you can now create your main database on the GCP platform. To do this, in the google_compute_instance block, you can specify the name, machine_type and image that you would like to use. Then set the resource link of the VPC Subnetwork in the subnetwork variable and configure access controls in the access_config block. 
    Also, the code include the set of commands or script for setting up and using PostgreSQL on an Ubuntu server. The script first updates the system's package manager (apt) so that it has the latest packages and installs postgresql-12 and its associated client program, postgresql-client-12.

    Next, it creates a database called "pgbench" within PostgreSQL, which can then be used to practice PostgreSQL commands. Following this, it uses the pgbench command to create tables in the database and to carry out operations like Insert, Update, Delete etc. Although these type of operation are not necessary, but I have mentioned it, so that if there is a need to perform some action beforehand, then this can be the way to implement it.

    This is translation of the code -

        sudo apt update: This updates the package manager with the latest packages.
        
        sudo apt install -y postgresql-12 postgresql-client-12: This installs PostgreSQL version 12, along with its associated client program, into the system.
        
        sudo -u postgres createdb pgbench: This command creates the PostgreSQL database called “pgbench”.
        
        sudo -u postgres pgbench -i pgbench: This command initializes the pgbench table in the newly created database.
        
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “select * from tablename”: This command retrieves all the records from the tablename table that is inside the pgbench database.
       
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “create unlogged table tablename (data varchar)”: This command creates an unlogged table in the pgbench database. Here, data is a data type ‘varchar’.
        
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “insert into tablename values('TestData')”: This command adds the value “TestData” to the tablename table.
        
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “update tablename set data='UpdatedData' where condition=true”: This command updates the existing value in the tablename table with new data, i.e., it changes “TestData” to “UpdatedData” only if the specified “condition” is true.
        
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “select * from tablename”: This command retrieves all the records from the tablename table that is inside the pgbench database.
        
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “delete from tablename where condition=false”: This command deletes a record from the tablename table if the specified “condition” is false.
       
        sudo -u postgres psql -h primary_db -U postgres -d pgbench -c “drop table tablename” : This command drops the entire tablename table from the pgbench database.
    
Storage Bucket: 
You will also need to setup a storage bucket. This will help you store a backup of the data stored in your main database in case something unexpected happens. The details regarding the bucket's lifetime rule can be seen in the google_storage_bucket block, in which you can define the action type and a condition which defines when it needs to be applied.

Standby DB: 
The standby-db Compute Instance is created to serve as a passive replica of the primary-db. It is receiving regular backups from the “standby-db-backups” Google Storage Bucket, which has a lifecycle rule that ensures existing backups are deleted if they are more than 15 days old. It also receives continuous changesets from the primary-db.
    The gsutil command copies any files located in the backup_bucket to /var/lib/postgresql/data1 directory on the standby server. The psql command creates a database named pg_replica on the standby server. The pg_basebackup command streams a continuous backup of the primary database's transactions to the replica. Lastly, an echo command creates a cron job for automatic backups at regular intervals. All these commands are executed using the sudo -u postgres command which executes commands with elevated privileges.

High CPU Usage Alert: 
As a precaution, you will also need to set up an alert system that informs you when the CPU usage on the primary database goes above 90%. To set up such an alarm, you need to first create a notification channel for the email address to which you want to send the alert. This can be done by making the necessary declarations inside the google_monitoring_notification_channel block. Then create a google_monitoring_alert_policy block, wherein you can define the name, combiner, notification_channels, along with the details for the condition_threshold. This will help you create the CP usage alert notification.

High Disk Usage Alert: 
Similarly, you also need to set up another alert for when the disk usage on the primary database goes above 85%. To establish this alarm, again you need to create a notification channel that can be done by using the google_monitoring_notification_channel block. Then set the details of the alert in the google_monitoring_alert_policy block, in order to notify the user when the threshold has been reached.
