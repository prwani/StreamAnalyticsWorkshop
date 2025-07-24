# Troubleshooting Guide

## 🔧 Common Issues and Solutions

This guide covers the most common issues encountered during the Azure Stream Analytics Workshop and their solutions.

## 🚨 Stream Analytics Job Issues

### Issue: Job Won't Start

**Symptoms:**
- Job remains in "Starting" state for more than 5 minutes
- Error message: "Job failed to start"

**Solutions:**
1. **Check Input Connections:**
   ```powershell
   # Test Event Hub connection
   az eventhubs eventhub show --resource-group rg-streamanalytics-workshop --namespace-name YOUR_NAMESPACE --name telemetry-data
   ```

2. **Verify Output Connections:**
   - Test blob storage access permissions
   - Check SQL Database firewall rules
   - Verify Power BI authentication

3. **Review Query Syntax:**
   - Use Query Test feature to validate syntax
   - Check for missing TIMESTAMP BY clause
   - Verify input/output aliases match

### Issue: No Data Processing

**Symptoms:**
- Input events showing 0
- No output data being generated

**Solutions:**
1. **Check Data Source:**
   ```powershell
   # Verify Event Hub has data
   az monitor metrics list --resource YOUR_EVENTHUB_RESOURCE_ID --metric IncomingMessages --interval PT1M
   ```

2. **Verify Input Configuration:**
   - Consumer group not conflicting with other consumers
   - Correct Event Hub name and namespace
   - Valid connection string

3. **Check Event Hub Data:**
   - Navigate to Event Hub in portal
   - Use "Process Data" → "Explore" to see sample events
   - Verify JSON format is correct

### Issue: High Streaming Unit (SU) Usage

**Symptoms:**
- SU% consistently above 80%
- Job performance degraded

**Solutions:**
1. **Optimize Query:**
   ```sql
   -- ❌ Avoid high cardinality grouping
   GROUP BY deviceId, DATEPART(second, timestamp)
   
   -- ✅ Use lower cardinality grouping
   GROUP BY SUBSTRING(deviceId, 1, 6), TumblingWindow(minute, 5)
   ```

2. **Reduce Window Overlap:**
   ```sql
   -- ❌ High overlap causing performance issues
   GROUP BY HoppingWindow(minute, 10, 1)  -- 90% overlap
   
   -- ✅ Reasonable overlap
   GROUP BY HoppingWindow(minute, 10, 5)  -- 50% overlap
   ```

3. **Scale Up:**
   - Increase Streaming Units in job settings
   - Monitor performance after scaling

## 📊 Data Quality Issues

### Issue: Missing or NULL Values

**Symptoms:**
- Aggregations returning unexpected results
- NULL values in output

**Solutions:**
1. **Handle NULLs in Queries:**
   ```sql
   -- ❌ NULLs will affect aggregations
   SELECT AVG(temperature) FROM [input]
   
   -- ✅ Explicitly handle NULLs
   SELECT 
       AVG(CASE WHEN temperature IS NOT NULL THEN temperature END) AS AvgTemp,
       COUNT(temperature) AS ValidReadings,
       COUNT(*) - COUNT(temperature) AS MissingReadings
   FROM [input]
   ```

2. **Data Validation Query:**
   ```sql
   SELECT 
       deviceId,
       COUNT(*) AS TotalEvents,
       COUNT(temperature) AS ValidTemp,
       COUNT(humidity) AS ValidHumidity,
       COUNT(pressure) AS ValidPressure,
       (COUNT(temperature) * 100.0) / COUNT(*) AS TempCompleteness
   FROM [telemetry-input] TIMESTAMP BY timestamp
   GROUP BY deviceId, TumblingWindow(minute, 15)
   ```

### Issue: Incorrect Data Types

**Symptoms:**
- Type conversion errors
- Unexpected query results

**Solutions:**
1. **Safe Type Conversions:**
   ```sql
   -- ❌ Unsafe conversion
   SELECT CAST(deviceId AS bigint) FROM [input]
   
   -- ✅ Safe conversion
   SELECT TRY_CAST(RIGHT(deviceId, 3) AS bigint) AS DeviceNumber
   FROM [input]
   WHERE deviceId LIKE 'device-___'
   ```

2. **Validate Input Data:**
   ```sql
   SELECT 
       deviceId,
       timestamp,
       temperature,
       CASE 
           WHEN TRY_CAST(temperature AS decimal) IS NULL THEN 'Invalid'
           ELSE 'Valid'
       END AS TemperatureValidation
   FROM [telemetry-input] TIMESTAMP BY timestamp
   ```

## 🔗 Connectivity Issues

### Issue: SQL Database Connection Failures

**Symptoms:**
- "Login failed" errors
- Connection timeout errors

**Solutions:**
1. **Check Firewall Rules:**
   ```powershell
   # Add current IP to firewall
   az sql server firewall-rule create \
     --resource-group rg-streamanalytics-workshop \
     --server YOUR_SQL_SERVER \
     --name AllowMyIP \
     --start-ip-address YOUR_IP \
     --end-ip-address YOUR_IP
   ```

2. **Verify Credentials:**
   - Double-check username and password
   - Ensure SQL Authentication is enabled
   - Test connection with SQL Server Management Studio

3. **Connection String Format:**
   ```
   Server=your-server.database.windows.net,1433;Database=StreamAnalyticsDB;User ID=sqladmin;Password=your-password;Encrypt=true;Connection Timeout=30;
   ```

### Issue: Event Hub Authentication Errors

**Symptoms:**
- "Unauthorized" errors
- "Access denied" messages

**Solutions:**
1. **Verify Connection String:**
   ```powershell
   # Get correct connection string
   az eventhubs namespace authorization-rule keys list \
     --resource-group rg-streamanalytics-workshop \
     --namespace-name YOUR_NAMESPACE \
     --name RootManageSharedAccessKey
   ```

2. **Check Permissions:**
   - Ensure connection string has Send/Listen permissions
   - Verify namespace and Event Hub names are correct

## 📈 Performance Issues

### Issue: Slow Query Performance

**Symptoms:**
- High latency between input and output
- Backlog of unprocessed events

**Solutions:**
1. **Optimize Joins:**
   ```sql
   -- ❌ Avoid unnecessary joins
   SELECT * FROM input1 JOIN input2 ON input1.id = input2.id
   
   -- ✅ Use specific columns and appropriate join conditions
   SELECT input1.deviceId, input1.temperature, input2.metadata
   FROM input1 TIMESTAMP BY timestamp1
   JOIN input2 TIMESTAMP BY timestamp2
   ON input1.deviceId = input2.deviceId
   AND DATEDIFF(second, input1, input2) BETWEEN 0 AND 60
   ```

2. **Reduce Output Volume:**
   ```sql
   -- Add HAVING clauses to filter small groups
   SELECT deviceId, COUNT(*), AVG(temperature)
   FROM [telemetry-input] TIMESTAMP BY timestamp
   GROUP BY deviceId, TumblingWindow(minute, 5)
   HAVING COUNT(*) >= 3  -- Only output groups with sufficient data
   ```

### Issue: Power BI Not Updating

**Symptoms:**
- Dashboard shows old data
- Tiles not refreshing

**Solutions:**
1. **Check Stream Analytics Output:**
   - Verify Power BI output is configured correctly
   - Check output events metric in Stream Analytics

2. **Power BI Dataset Limits:**
   - Each streaming dataset limited to 200,000 rows
   - Implement data retention strategy:
   ```sql
   -- Add row limit in Stream Analytics query
   SELECT TOP 1000 
       deviceId,
       timestamp,
       temperature
   INTO [powerbi-output]
   FROM [telemetry-input] TIMESTAMP BY timestamp
   ORDER BY timestamp DESC
   ```

3. **Refresh Power BI Authentication:**
   - Re-authenticate Power BI connection in Stream Analytics
   - Check dataset permissions in Power BI

## 🔍 Debugging Techniques

### Debug Query Issues

1. **Use Query Test Feature:**
   ```sql
   -- Start with simple query
   SELECT * FROM [telemetry-input] TIMESTAMP BY timestamp
   
   -- Gradually add complexity
   SELECT deviceId, temperature FROM [telemetry-input] TIMESTAMP BY timestamp
   WHERE temperature IS NOT NULL
   ```

2. **Add Debug Output:**
   ```sql
   -- Add debug information to output
   SELECT 
       deviceId,
       temperature,
       System.Timestamp() AS ProcessedTime,
       'DEBUG' AS MessageType
   INTO [debug-output]
   FROM [telemetry-input] TIMESTAMP BY timestamp
   ```

### Monitor Resource Usage

1. **Check Streaming Units:**
   - Monitor SU% metric
   - Scale up if consistently above 80%

2. **Monitor Input/Output Rates:**
   - Input Events per second
   - Output Events per second
   - Data Conversion Errors

3. **Set Up Alerts:**
   ```powershell
   # Create alert for high SU usage
   az monitor metrics alert create \
     --name "High SU Usage" \
     --resource-group rg-streamanalytics-workshop \
     --scopes YOUR_STREAM_ANALYTICS_RESOURCE_ID \
     --condition "avg SU% > 80" \
     --description "Stream Analytics job using too many SUs"
   ```

## 📋 Diagnostic Queries

### Check Event Arrival Patterns
```sql
SELECT 
    System.Timestamp() AS WindowEnd,
    COUNT(*) AS EventCount,
    MIN(timestamp) AS EarliestEvent,
    MAX(timestamp) AS LatestEvent,
    DATEDIFF(second, MIN(timestamp), MAX(timestamp)) AS TimeSpanSeconds,
    AVG(DATEDIFF(second, timestamp, System.Timestamp())) AS AvgLatencySeconds
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 5)
```

### Identify Data Quality Issues
```sql
SELECT 
    deviceId,
    COUNT(*) AS TotalEvents,
    SUM(CASE WHEN temperature IS NULL THEN 1 ELSE 0 END) AS MissingTemperature,
    SUM(CASE WHEN temperature < -50 OR temperature > 100 THEN 1 ELSE 0 END) AS OutOfRangeTemperature,
    AVG(CASE WHEN temperature IS NOT NULL THEN temperature END) AS AvgTemperature
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY deviceId, TumblingWindow(hour, 1)
```

### Monitor Output Health
```sql
SELECT 
    'SQL_OUTPUT' AS OutputType,
    System.Timestamp() AS CheckTime,
    COUNT(*) AS RecordCount
INTO [health-check-output]
FROM [telemetry-input] TIMESTAMP BY timestamp
GROUP BY TumblingWindow(minute, 1)
```

## 🆘 Getting Help

### Azure Support Channels

1. **Azure Portal:**
   - Navigate to your Stream Analytics job
   - Click "Help + support" → "New support request"

2. **Azure Documentation:**
   - [Stream Analytics Troubleshooting](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-troubleshoot-query)
   - [Common Query Patterns](https://docs.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns)

3. **Community Forums:**
   - [Microsoft Q&A](https://docs.microsoft.com/answers/topics/azure-stream-analytics.html)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/azure-stream-analytics)

### Workshop-Specific Help

1. **Check Prerequisites:**
   - Verify all Azure resources are created
   - Confirm proper permissions and access

2. **Validate Sample Data:**
   - Use provided sample JSON files
   - Test with known-good data before using simulators

3. **Step-by-Step Verification:**
   - Complete each lab in sequence
   - Verify success criteria before proceeding

## 📞 Emergency Procedures

### If Everything Stops Working

1. **Stop Stream Analytics Job**
2. **Check Resource Health** in Azure Portal
3. **Verify All Connection Strings** and credentials
4. **Test Each Component Individually:**
   - Event Hub → Test with portal
   - Stream Analytics → Test query with sample data
   - SQL Database → Test connection with SSMS
   - Power BI → Verify authentication

5. **Restart in Minimal Configuration:**
   - Simple pass-through query
   - Single output (blob storage)
   - Verify basic functionality

6. **Gradually Add Complexity:**
   - Add SQL output
   - Add aggregations
   - Add Power BI output
   - Add alert logic

## 📊 Health Check Checklist

- [ ] Stream Analytics job is running
- [ ] Input events > 0 in last 5 minutes
- [ ] Output events > 0 in last 5 minutes
- [ ] Data conversion errors = 0
- [ ] SU% < 80%
- [ ] SQL Database has recent data
- [ ] Power BI dashboard updating
- [ ] No failed requests in Activity Log
- [ ] All resource health checks passed

---

**Remember:** Most issues are related to configuration or connectivity. Start with the basics and work your way up to complex scenarios.
