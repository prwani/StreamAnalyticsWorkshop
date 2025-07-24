# Lab 9: Microsoft Fabric Real-Time Intelligence (RTI) Tutorial

## 📖 Official Tutorial Reference

For this lab, we recommend following the official Microsoft Learn tutorial series:

**[Real-Time Intelligence Tutorial: Introduction](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/tutorial-introduction)**

## 📋 Tutorial Overview

The Microsoft Learn tutorial provides a comprehensive, hands-on introduction to Real-Time Intelligence in Microsoft Fabric. It uses a practical scenario with bicycle data to demonstrate key concepts and features.

### 🎯 What You'll Learn

The tutorial covers the complete Real-Time Intelligence workflow:

- **Set up your environment** - Configure your Fabric workspace and RTI resources
- **Get data in the Real-Time hub** - Connect to data sources and understand data ingestion
- **Transform events** - Process and transform streaming data in real-time
- **Publish an eventstream** - Create and manage event streams for data flow
- **Subscribe to Fabric Events** - Set up event-driven architectures
- **Use update policies to transform data in Eventhouse** - Implement automated data transformations
- **Use Copilot to create a KQL query** - Leverage AI assistance for query creation
- **Create a KQL query** - Write custom Kusto Query Language (KQL) queries
- **Create an alert based on a KQL query** - Set up monitoring and alerting
- **Create a Real-Time dashboard** - Build interactive dashboards for data visualization
- **Explore data visually in the Real-Time dashboard** - Use visual exploration tools
- **Create a Power BI report from a KQL query** - Integrate with Power BI for advanced reporting
- **Set an alert on the eventstream** - Configure stream-level monitoring

### 🚲 Sample Scenario

The tutorial uses **bicycle data** as the sample dataset, containing:
- Bike ID information
- Location data (GPS coordinates)
- Timestamp information  
- Additional telemetry metrics

This scenario demonstrates how to extract insights from streaming IoT data, making it highly relevant for real-world applications.

### 🔄 Comparison with Azure Stream Analytics

| Feature | Azure Stream Analytics | Microsoft Fabric RTI |
|---------|----------------------|----------------------|
| **Query Language** | Stream Analytics Query Language (SAQL) | Kusto Query Language (KQL) |
| **Data Storage** | Pass-through processing | Native storage in KQL databases (Eventhouse) |
| **Scalability** | Streaming Units (1-200+) | Automatic scaling with Fabric capacity |
| **Analytics** | Stream processing + basic ML | Advanced analytics + AI/ML + Copilot integration |
| **Visualization** | External (Power BI, custom) | Integrated Real-Time dashboards + Power BI |
| **Cost Model** | Pay per Streaming Unit | Capacity-based pricing model |
| **Development** | Azure Portal/VS Code | Integrated Fabric workspace environment |
| **Data Retention** | Limited (outputs to storage) | Native time-series storage with configurable retention |

## 📋 Prerequisites

To complete the tutorial, you need:
- A Microsoft Fabric workspace with Premium capacity or trial
- Basic understanding of streaming data concepts
- Familiarity with Azure Stream Analytics (from previous labs) will be helpful

## 🏗️ Key Architecture Components

The tutorial demonstrates this data flow:
```
[Data Source] → [Real-Time Hub] → [Event Stream] → [Eventhouse/KQL Database] → [Real-Time Dashboard]
                       ↓                ↓                    ↓                      ↓
                [Data Discovery]  [Transform Events]  [KQL Queries & Alerts]  [Power BI Integration]
```

## 💡 Key Benefits of Following the Official Tutorial

1. **Up-to-date Content**: Always reflects the latest Fabric RTI features and capabilities
2. **Interactive Experience**: Hands-on exercises with real data
3. **Best Practices**: Incorporates Microsoft's recommended approaches
4. **Comprehensive Coverage**: Covers the entire RTI workflow end-to-end
5. **AI Integration**: Demonstrates Copilot features for query assistance
6. **Visual Learning**: Rich screenshots and step-by-step guidance

## 🚀 Getting Started

1. **Access the Tutorial**: Navigate to the [tutorial introduction page](https://learn.microsoft.com/en-us/fabric/real-time-intelligence/tutorial-introduction)
2. **Follow Sequential Parts**: The tutorial is divided into multiple parts - complete them in order
3. **Adapt to Your Data**: After completing the bicycle scenario, apply the concepts to your IoT telemetry data
4. **Explore Advanced Features**: Use the tutorial as a foundation to explore additional RTI capabilities

## 📈 Migration Considerations

If you're migrating from Azure Stream Analytics to Fabric RTI, the tutorial will help you understand:

- **Query Language Differences**: How KQL compares to SAQL
- **Architecture Changes**: Moving from pass-through processing to stored analytics
- **New Capabilities**: Features not available in Stream Analytics
- **Integration Benefits**: Unified analytics platform advantages

## 🔗 Next Steps

Continue to [Lab 10: IoT Edge Overview](./lab-10-iot-edge.md) to learn about edge computing scenarios and bringing analytics closer to your IoT devices.
