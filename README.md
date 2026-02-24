# CloudFolio
> A simple serverless API built with Azure Functions.

### 📌Overview
This project is a demonstration of a simple serverless API architecture on Azure, where a static website fetches and displays data 
stored in Cosmos DB through an Azure Function, with CI/CD automated by GitHub Actions for infrastructure provisioning and data updates.

### 🎯Use Case
The data used in this project represents a personal resume. Whenever the data is updated, GitHub Actions automatically syncs 
it to Cosmos DB, and the website reflects the changes instantly.
