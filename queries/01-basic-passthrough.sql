-- Basic pass-through query
-- Selects all fields from input and sends to output
SELECT 
    *,
    System.Timestamp() AS ProcessedTime
INTO [blob-output]
FROM [telemetry-input]
