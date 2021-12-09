let AnalyticsQuery =
let 
NullToBlank = (input) => if (input = null) then "" else input,
// Kustos result set limit is 500000 rows
Limit = (input) => if (input = null) then "500000" else input,
Source = Json.Document(Web.Contents("https://api.applicationinsights.io/v1/apps/" & #"App id" & "/query", 
// here you can see how PowerBI parameters can be passed on to the KQL query
[Query=[#"query"="pageViews
| where 1==1 
    and ('" & NullToBlank( #"AAD Tenant Id" ) & "'=='' or customDimensions.aadTenantId == '" & NullToBlank( #"AAD Tenant Id" ) & "')
    and ('" & NullToBlank( #"Environment Name" ) & "'=='' or customDimensions.environmentName == '" & NullToBlank( #"Environment Name" ) & "')
    and timestamp >= todatetime('" & Date.ToText( #"Start Date", "yyyy-MM-dd" ) & "')
    and timestamp <= todatetime('"& Date.ToText( #"End Date", "yyyy-MM-dd" ) &"') + totimespan(24h) - totimespan(1ms)
| where customDimensions.eventID == 'CL0001'
| limit " & Limit( #"Top" ) & "
| extend 
  aadTenantId = tostring( customDimensions.aadTenantId )
, environmentName = tostring( customDimensions.environmentName )
, environmentType = tostring( customDimensions.environmentType )
, platformVersion = tostring( customDimensions.componentVersion )
, clientType = tostring( customDimensions.clientType )
, alObjectId = tostring( customDimensions.alObjectId )
, alObjectName = tostring( customDimensions.alObjectName )
, alObjectType = tostring( customDimensions.alObjectType )
, pageType = customDimensions.pageType
, duration
| project 
  timestamp
, AadTenantId=aadTenantId
, EnvironmentName=environmentName
, EnvironmentType=environmentType
, PlatformVersion = platformVersion
, ClientType = clientType
, ObjectId = alObjectId
, PageName = alObjectName
, ObjectType = alObjectType
, DurationInMs = duration
, ClientBrowser = client_Browser
, ClientOS = client_OS
| summarize Count=count()
, SumDurationinMs=sum(DurationInMs)
by bin(timestamp, 1h)
, AadTenantId, EnvironmentName, EnvironmentType, PlatformVersion, ClientType
, ClientBrowser, ClientOS
, ObjectId, PageName
",#"x-ms-app"="AAPBI",#"prefer"="ai.response-thinning=true"],Timeout=#duration(0,0,4,0)])),
TypeMap = #table(
{ "AnalyticsTypes", "Type" }, 
{ 
{ "string",   Text.Type },
{ "int",      Int32.Type },
{ "long",     Int64.Type },
{ "real",     Double.Type },
{ "timespan", Duration.Type },
{ "datetime", DateTimeZone.Type },
{ "bool",     Logical.Type },
{ "guid",     Text.Type },
{ "dynamic",  Text.Type }
}),
DataTable = Source[tables]{0},
Columns = Table.FromRecords(DataTable[columns]),
ColumnsWithType = Table.Join(Columns, {"type"}, TypeMap , {"AnalyticsTypes"}),
Rows = Table.FromRows(DataTable[rows], Columns[name]), 
Table = Table.TransformColumnTypes(Rows, Table.ToList(ColumnsWithType, (c) => { c{0}, c{3}}))
in
Table
in 
AnalyticsQuery