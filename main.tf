provider "google" {
  # Credentials file path 
  credentials = file("/home/prateek/Downloads/toggl-377711-9ca7256e7085.json") //Here, you have to insert the location of you GCP service account key file

  # Google API version
  version = "2.9.0" 

  # The project from which the resources are created
  project = "my-gcp-project"

  # The region the resources will be created
  region  = "us-central1"
}


resource "google_compute_network" "vpc_network" {
  # Name of VPC network
  name = "my-vpc-network"
}


resource "google_compute_subnetwork" "vpc_subnetwork" {
  # Name of the subnetwork
  name          = "my-vpc-subnetwork"

  # IP range of the subnetwork
  ip_cidr_range = "10.0.0.0/16"

  # Resource link of the parent VPC Network
  network       = google_compute_network.vpc_network.self_link

  # Region in which the subnetwork will be created
  region        = "us-central1"
}


resource "google_compute_instance" "primary_db" {
  # Name of the compute instance
  name         = "primary-db"

  # Machine type 
  machine_type = "n1-standard-1"

  # Boot disk 
  boot_disk {
    initialize_params {
      # Image of the compute instance
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  # Network interface
  network_interface {
    # Resource link of the VPC Subnetwork
    subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link


    # Configuring access control
    access_config {
      // Ephemeral external IP
    }
  }

  # Provisioning instances
  provisioner "remote-exec" {
    # List of commands to execute
    inline = [
      "sudo apt update",
      "sudo apt install -y postgresql-12 postgresql-client-12",
      "sudo -u postgres createdb pgbench",
      "sudo -u postgres pgbench -i pgbench",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"select * from tablename\"",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"create unlogged table tablename (data varchar)\"",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"insert into tablename values('TestData')\"",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"update tablename set data='UpdatedData' where condition=true\"",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"select * from tablename\"",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"delete from tablename where condition=false\"",
      "sudo -u postgres psql -h primary_db -U postgres -d pgbench -c \"drop table tablename\"",
    ]
  }
}




resource "google_storage_bucket" "backup_bucket" {
  # Name of the storage bucket
  name = "standby-db-backups"

  # Defining a lifetime rule
  lifecycle_rule {
    action {
      # Type of action
      type = "Delete"
    }

    # Condition in which the rule applies
    condition {
      age = 15
    }
}
}



resource "google_compute_instance" "standby_db" { // Creating a google compute instance to be used as a standby db
  name         = "standby-db"  // Set the instance name
  machine_type = "n1-standard-1" // Set the instance type

  boot_disk {// Configure the instance's boot disk
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts" // Set the Linux image for the instance
    }
  }

  network_interface {// Configure the instance's network interface
    subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link

    access_config {
      // Ephemeral external IP
    }
  }

  provisioner "remote-exec" { // Provision remote execution script
    inline = [
    "gsutil cp -p gs://backup_bucket/. /var/lib/postgresql/data1", // Copy contents from backup bucket to data1 directory
    "sudo -u postgres psql -h standby_db -U postgres -d pgbench -c 'create database pg_replica'", // Create replica database
    "sudo -u postgres pg_basebackup -h primary_db -D /var/lib/postgresql/pg_replica -U replicator --xlog-method=stream -v -P", // Stream transactions from primary db to replica
    "echo '0 0 * * * pg_dumpall | gzip > /var/lib/postgresql/backups/$(date +%Y-%m-%d).sql.gz && gsutil cp -r /var/lib/postgresql/backups/* gs://backup_bucket/ | sudo tee /var/spool/cron/crontabs/postgres'", // Auto backup of database

    #  This code creates a replica of the primary database being backed up. 
    #  The psql command creates a database called pg_replica on the standby server. 
    #  The pg_basebackup command streams a continuous backup of the primary database's transactions to the replica. 
    #  Finally, the echo command creates a cron job for automatic backups at regular intervals.

    ]
  }
}




#Sending notification of high cpu usage to the specified email
resource "google_monitoring_notification_channel" "high_cpu_usage_email" {
  display_name = "High CPU Usage Alert - Email Notification Channel"
  type         = "email"
  labels = {
    category = "notifications",
    email_address = "example@example.com"
  }
  description = "Notify about high CPU usage via email."
  
}


#Google Cloud Monitoring alert when CPU Usage > 90% on Primary Database
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name       = "High CPU Alert"
  combiner           = "OR"

  notification_channels = [google_monitoring_notification_channel.high_cpu_usage_email.id]

  conditions {
      display_name        = "CPU Usage Too High"
    condition_threshold {
      # display_name        = "CPU Usage Too High"
      filter              = "metric.type=\"compute.googleapis.com/instance/cpu/usage_time\"resource.type=\"gce_instance\"ANDresource.labels.instance_name=\"${google_compute_instance.primary_db.name}\"ANDmetric.label.cpu=\"0\""
      comparison          = "COMPARISON_GT"
      threshold_value     = 0.9
      duration            = "30s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
      trigger {
        count              = 1
      }
    }
  }
} 


#Sending notification of high disk usage to the specified email
resource "google_monitoring_notification_channel" "high_disk_usage_email" {
  display_name = "High Disk Usage Alert - Email Notification Channel"
  type         = "email"
  labels = {
    category = "notifications",
    email_address = "example@example.com"
  }
  description = "Notify about high disk usage via email."
  
}


#Google Cloud Monitoring alert when Disk Usage > 85% on Primary Database
resource "google_monitoring_alert_policy" "high_disk" {
  display_name       = "High Disk Usage Alert"
  combiner           = "OR"

  notification_channels = [google_monitoring_notification_channel.high_disk_usage_email.id]

  conditions {
       display_name        = "Disk Usage Too High"
    condition_threshold {
      # display_name        = "Disk Usage Too High"
      filter              = "metric.type=\"compute.googleapis.com/instance/disk/usage_active\"resource.type=\"gce_instance\"ANDresource.labels.instance_name=\"${google_compute_instance.primary_db.name}\"ANDmetric.label.device_name=\"sdb\""
      comparison          = "COMPARISON_GT"
      threshold_value     = 0.85
      duration            = "30s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
      trigger {
        count              = 1
      }
    }
  }
} 






