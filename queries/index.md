---
layout: default
title: Sample Queries
nav_order: 4
---

# Sample Queries

This directory contains reference SQL queries for Azure Stream Analytics. These queries demonstrate various Stream Analytics Query Language (SAQL) patterns and can be used as templates for your own implementations.

## Available Queries

- **01-basic-passthrough.sql** - Simple pass-through query for getting started
- **02-temperature-filter.sql** - Basic filtering operations
- **03-basic-aggregation.sql** - Aggregation functions example
- **06-anomaly-spike-detection.sql** - Spike and dip anomaly detection
- **07-changepoint-detection.sql** - Change point detection for trend analysis
- **08-powerbi-realtime.sql** - Real-time Power BI streaming query
- **09-edge-aggregation.sql** - IoT Edge aggregation patterns

## How to Use

1. Copy the desired query from the SQL files
2. Paste it into your Stream Analytics job query editor
3. Modify input/output aliases to match your configuration
4. Adjust parameters as needed for your use case

## Related Labs

These queries are referenced in various workshop labs:

- [Lab 1: Stream Analytics Job 101](../labs/lab-01-sa-job-101.md) - Uses basic-passthrough.sql
- [Lab 6: Analytics Functions](../labs/lab-06-analytics-functions.md) - Uses anomaly detection queries
- [Lab 7: Power BI Visualization](../labs/lab-07-powerbi-visualization.md) - Uses powerbi-realtime.sql
- [Lab 10: IoT Edge](../labs/lab-10-iot-edge.md) - Uses edge-aggregation.sql
