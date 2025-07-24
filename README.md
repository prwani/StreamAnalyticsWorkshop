# Azure Stream Analytics Workshop

Welcome to the Azure Stream Analytics Workshop! This hands-on training will guide you through the fundamentals of real-time data processing using Azure Stream Analytics and related Azure services.

> 🌐 **Live Workshop**: This workshop is available online at [https://yourusername.github.io/StreamAnalyticsWorkshop](https://yourusername.github.io/StreamAnalyticsWorkshop)

## 🎯 Workshop Objectives

By the end of this workshop, you will be able to:
- Create and configure Azure Stream Analytics jobs
- Write Stream Analytics Query Language (SAQL) queries
- Implement real-time data processing pipelines
- Visualize real-time data in Power BI
- Build end-to-end IoT and streaming solutions

## 📋 Prerequisites

### Azure Resources Required
- Azure Subscription with Contributor access
- Event Hub Namespace
- IoT Hub
- Stream Analytics Job
- Azure SQL Database
- Power BI Account
- Azure Blob Storage Account

### Tools and Knowledge
- Basic understanding of SQL
- Familiarity with Azure Portal
- Basic knowledge of JSON data format

## 🏗️ Workshop Structure

### Module 1: Azure Stream Analytics Fundamentals
- **[Lab 1: Stream Analytics Job 101](./labs/lab-01-sa-job-101.md)** - Event Hub → Stream Analytics → Blob Storage
- **[Lab 2: Stream Analytics Query Language Overview](./labs/lab-02-saql-overview.md)** - Introduction to SAQL syntax and basics

### Module 2: Data Processing and Functions
- **[Lab 3: Data Manipulation Functions](./labs/lab-03-data-manipulation.md)** - DateTime, Mathematical, String, and Time Management functions
- **[Lab 4: Aggregate Functions](./labs/lab-04-aggregate-functions.md)** - SUM, COUNT, AVG, MIN, MAX, and more
- **[Lab 5: Windowing Functions](./labs/lab-05-windowing-functions.md)** - Tumbling, Hopping, Sliding, and Session windows

### Module 3: Advanced Analytics
- **[Lab 6: Analytics Functions](./labs/lab-06-analytics-functions.md)** - Anomaly detection and pattern recognition
- **[Lab 7: Real-time Visualization in Power BI](./labs/lab-07-powerbi-visualization.md)** - Connect Stream Analytics to Power BI

### Module 4: End-to-End Pipeline
- **[Lab 8: Complete IoT Pipeline](./labs/lab-08-end-to-end-pipeline.md)** - Client → IoT Hub/Event Hub → Stream Analytics → SQL DB → Power BI

### Module 5: Microsoft Fabric Real-Time Intelligence
- **[Lab 9: Fabric RTI Overview](./labs/lab-09-fabric-rti-overview.md)** - Overview of Real-time Intelligence components in Fabric

### Bonus Module (Time Permitting)
- **[Lab 10: IoT Edge Overview](./labs/lab-10-iot-edge-overview.md)** - Introduction to IoT Edge concepts

## 🚀 Getting Started

1. **Setup Prerequisites**: Follow the [Prerequisites Setup Guide](./setup/prerequisites-setup.md) to create required Azure resources
2. **Start with Lab 1**: Begin with the Stream Analytics Job 101 lab
3. **Follow Sequential Order**: Complete labs in order as they build upon each other
4. **Use Sample Data**: Each lab includes sample data and scripts for testing

## 📁 Repository Structure

```
StreamAnalyticsWorkshop/
├── README.md                          # This file
├── setup/
│   ├── prerequisites-setup.md         # Azure resources setup guide
│   ├── bicep/                         # Infrastructure as Code templates
│   └── scripts/                       # Setup automation scripts
├── labs/
│   ├── lab-01-sa-job-101.md
│   ├── lab-02-saql-overview.md
│   ├── lab-03-data-manipulation.md
│   ├── lab-04-aggregate-functions.md
│   ├── lab-05-windowing-functions.md
│   ├── lab-06-analytics-functions.md
│   ├── lab-07-powerbi-visualization.md
│   ├── lab-08-end-to-end-pipeline.md
│   ├── lab-09-fabric-rti-overview.md
│   └── lab-10-iot-edge-overview.md
├── sample-data/                       # Sample datasets for labs
├── queries/                           # Sample SAQL queries
└── assets/                           # Images and diagrams
```

## 🔧 Troubleshooting

Common issues and solutions are documented in each lab. For additional help:
- Check the [Azure Stream Analytics documentation](https://docs.microsoft.com/azure/stream-analytics/)
- Review the [troubleshooting guide](./troubleshooting.md)
- Use Azure Monitor for job diagnostics

## 🤝 Contributing

This workshop is designed to be continuously improved. Feel free to contribute:
- Report issues or suggest improvements
- Add new lab scenarios
- Update existing content for latest Azure features

## 📞 Support

For workshop-related questions:
- Check individual lab README files for specific guidance
- Review Azure documentation links provided in each lab
- Use Azure Support for Azure service-related issues

---

**Happy Learning!** 🎉

Let's dive into the world of real-time data processing with Azure Stream Analytics!
