# Step 1: Setup

**1. clone the repo:**

```
git clone https://github.com/Anran0716/DE-Project-Bikeshare.git
```

**2. Set up a Google Cloud Platform project:**

Set up a Google Cloud Platform project and service account following the instructions [here](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/1_terraform_gcp/2_gcp_overview.md). Give the service account the following roles:

- BigQuery Admin
- BigQuery Data Editor
- BigQuery Data Owner
- BigQuery Job User
- BigQuery User
- Compute Admin
- Storage Admin

**3. Deploy Terraform:**
1. Make sure you have installed:

- terraform
- gcloud CLI

2. Replace the value of the project name and region in the [main.tf](https://github.com/Anran0716/DE-Project-Bikeshare/blob/main/Terraform/main.tf)

3. Execute the following commands under this folder:

```
terraform init
terraform plan
terraform apply
```

Once successully running, you should see a new dataset `Indego_project` created in your project. 