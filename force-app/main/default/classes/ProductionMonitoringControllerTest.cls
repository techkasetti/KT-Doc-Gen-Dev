@IsTest
public class ProductionMonitoringControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test monitoring configurations
        List<Monitoring_Configuration__c> configs = new List<Monitoring_Configuration__c>();
        configs.add(new Monitoring_Configuration__c(
            Service_Name__c = 'Document Generation',
            Monitor_Type__c = 'Performance',
            Enable_Real_Time_Monitoring__c = true,
            Alert_Threshold_Value__c = 5.0,
            Monitoring_Frequency_Minutes__c = 5
        ));
        configs.add(new Monitoring_Configuration__c(
            Service_Name__c = 'E-Signature Service',
            Monitor_Type__c = 'Health Check',
            Enable_Real_Time_Monitoring__c = true,
            Alert_Threshold_Value__c = 95.0,
            Monitoring_Frequency_Minutes__c = 10
        ));
        insert configs;
        
        // Create test health logs
        List<System_Health_Log__c> healthLogs = new List<System_Health_Log__c>();
        healthLogs.add(new System_Health_Log__c(
            Component_Name__c = 'Document Generator',
            Health_Status__c = 'Healthy',
            Health_Score__c = 98.5,
            Response_Time_MS__c = 150,
            Monitoring_Configuration__c = configs[0].Id,
            Check_Timestamp__c = System.now()
        ));
        healthLogs.add(new System_Health_Log__c(
            Component_Name__c = 'E-Signature API',
            Health_Status__c = 'Warning',
            Health_Score__c = 85.2,
            Response_Time_MS__c = 250,
            Monitoring_Configuration__c = configs[1].Id,
            Check_Timestamp__c = System.now()
        ));
        insert healthLogs;
// Create test performance metrics
List<Performance_Metric__c> metrics = new List<Performance_Metric__c>();

metrics.add(new Performance_Metric__c(
    Metric_Type__c        = 'Processing Time',
    Metric_Value__c       = 2.5,
    Unit_of_Measure__c    = 'seconds',
    Component_Name__c     = 'Document Generation',
    Recorded_At__c        = System.now(),
    Baseline_Value__c     = 3.0,
    Threshold_Warning__c  = 5.0,
    Threshold_Critical__c = 10.0,
    Alert_Status__c       = 'Normal'
));

metrics.add(new Performance_Metric__c(
    Metric_Type__c        = 'Success Rate',
    Metric_Value__c       = 97.8,
    Unit_of_Measure__c    = 'percentage',
    Component_Name__c     = 'E-Signature Service',
    Recorded_At__c        = System.now(),
    Baseline_Value__c     = 95.0,
    Threshold_Warning__c  = 90.0,
    Threshold_Critical__c = 85.0,
    Alert_Status__c       = 'Normal'
));

metrics.add(new Performance_Metric__c(
    Metric_Type__c        = 'Throughput',
    Metric_Value__c       = 150.0,
    Unit_of_Measure__c    = 'requests/minute',
    Component_Name__c     = 'Document Processing',
    Recorded_At__c        = System.now(),
    Baseline_Value__c     = 120.0,
    Threshold_Warning__c  = 200.0,
    Threshold_Critical__c = 250.0,
    Alert_Status__c       = 'Normal'
));

insert metrics;

// Create test workflow instances for monitoring
List<Workflow_Instance__c> workflows = new List<Workflow_Instance__c>();

workflows.add(new Workflow_Instance__c(
    Status__c                = 'Completed',
    Processing_Time_Minutes__c = 3.2,
    Start_Time__c            = System.now().addHours(-1),
    End_Time__c              = System.now().addMinutes(-45)
));

workflows.add(new Workflow_Instance__c(
    Status__c                = 'In Progress',
    Processing_Time_Minutes__c = null,
    Start_Time__c            = System.now().addMinutes(-15),
    End_Time__c              = null
));

insert workflows;
    }
@IsTest
static void testGetDashboardData() {
    Test.startTest();
    Map<String, Object> dashboardData = ProductionMonitoringController.getDashboardData();
    Test.stopTest();

    // Verify dashboard data structure
    Assert.isNotNull(dashboardData);
    Assert.isTrue(dashboardData.containsKey('systemHealth'));
    Assert.isTrue(dashboardData.containsKey('performanceMetrics'));
    Assert.isTrue(dashboardData.containsKey('alertSummary'));
    Assert.isTrue(dashboardData.containsKey('usageStatistics'));
    Assert.isTrue(dashboardData.containsKey('integrationHealth'));

    // Verify system health data
    Map<String, Object> systemHealth = (Map<String, Object>)dashboardData.get('systemHealth');
    Assert.isNotNull(systemHealth.get('overallHealthScore'));
    Assert.isNotNull(systemHealth.get('componentStatus'));
}

@IsTest
static void testGetHealthCheckData() {
    Test.startTest();
    Map<String, Object> healthData = ProductionMonitoringController.getHealthCheckData();
    Test.stopTest();

    // Verify health check data
    Assert.isNotNull(healthData);
    Assert.isTrue(healthData.containsKey('healthScore'));
    Assert.isTrue(healthData.containsKey('overallStatus'));
    Assert.isTrue(healthData.containsKey('componentStatus'));
    Assert.isTrue(healthData.containsKey('checkTimestamp'));

    Decimal healthScore = (Decimal)healthData.get('healthScore');
    Assert.isTrue(healthScore >= 0 && healthScore <= 100);
}

@IsTest
static void testGetPerformanceTrends() {
    Test.startTest();
    Map<String, Object> trendData = ProductionMonitoringController.getPerformanceTrends(7);
    Test.stopTest();

    // Verify trend data structure
    Assert.isNotNull(trendData);
    Assert.isTrue(trendData.containsKey('processingTimeData'));
    Assert.isTrue(trendData.containsKey('successRateData'));
    Assert.isTrue(trendData.containsKey('throughputData'));
    Assert.isTrue(trendData.containsKey('currentAverage'));
    Assert.isTrue(trendData.containsKey('overallTrend'));
}

@IsTest
static void testGetOperationalReport() {
    Test.startTest();
    Map<String, Object> reportData = ProductionMonitoringController.getOperationalReport('monthly');
    Test.stopTest();

    // Verify report structure
    Assert.isNotNull(reportData);
    Assert.isTrue(reportData.containsKey('reportStatus'));
    Assert.isTrue(reportData.containsKey('reportPeriod'));
    Assert.isTrue(reportData.containsKey('utilizationMetrics'));
    Assert.isTrue(reportData.containsKey('costAnalysis'));
    Assert.isTrue(reportData.containsKey('userActivity'));
    Assert.isTrue(reportData.containsKey('complianceSummary'));
}

@IsTest
static void testRunSystemHealthCheck() {
    Test.startTest();
    Map<String, Object> healthCheckResult = ProductionMonitoringController.runSystemHealthCheck();
    Test.stopTest();

    // Verify health check execution
    Assert.isNotNull(healthCheckResult);
    Assert.isTrue(healthCheckResult.containsKey('success'));
    Assert.isTrue(healthCheckResult.containsKey('healthScore'));
    Assert.isTrue(healthCheckResult.containsKey('componentResults'));

    Boolean success = (Boolean)healthCheckResult.get('success');
    Assert.isTrue(success);
}

@IsTest
static void testCreatePerformanceAlert() {
    Test.startTest();

    // Create a critical metric
    Performance_Metric__c criticalMetric = new Performance_Metric__c(
        Metric_Type__c        = 'Processing Time',
        Metric_Value__c       = 12.0, // Above critical threshold
        Unit_of_Measure__c    = 'seconds',
        Component_Name__c     = 'Document Generation',
        Recorded_At__c        = System.now(),
        Baseline_Value__c     = 3.0,
        Threshold_Warning__c  = 5.0,
        Threshold_Critical__c = 10.0,
        Alert_Status__c       = 'Critical'
    );
    insert criticalMetric;

    String alertResult = ProductionMonitoringController.createPerformanceAlert(
        'Document Generation',
        'Critical performance degradation detected',
        'Critical'
    );

    Test.stopTest();

    // Verify alert creation
    Assert.isNotNull(alertResult);
    Assert.areEqual('Success', alertResult);
}
@IsTest
static void testGetSystemUtilization() {
    Test.startTest();
    Map<String, Object> utilizationData = ProductionMonitoringController.getSystemUtilization();
    Test.stopTest();

    // Verify utilization data
    Assert.isNotNull(utilizationData);
    Assert.isTrue(utilizationData.containsKey('cpuUtilization'));
    Assert.isTrue(utilizationData.containsKey('memoryUtilization'));
    Assert.isTrue(utilizationData.containsKey('storageUtilization'));
    Assert.isTrue(utilizationData.containsKey('apiCallUtilization'));
}

@IsTest
static void testGetIntegrationStatus() {
    Test.startTest();
    Map<String, Object> integrationStatus = ProductionMonitoringController.getIntegrationStatus();
    Test.stopTest();

    // Verify integration status
    Assert.isNotNull(integrationStatus);
    Assert.isTrue(integrationStatus.containsKey('healthScore'));
    Assert.isTrue(integrationStatus.containsKey('activeServices'));
    Assert.isTrue(integrationStatus.containsKey('totalServices'));
    Assert.isTrue(integrationStatus.containsKey('serviceDetails'));
}

@IsTest
static void testErrorHandling() {
    Test.startTest();

    // Test with invalid parameters
    Map<String, Object> invalidTrends = ProductionMonitoringController.getPerformanceTrends(-1);
    Map<String, Object> invalidReport = ProductionMonitoringController.getOperationalReport('invalid_period');

    Test.stopTest();

    // Verify error handling
    Assert.isNotNull(invalidTrends);
    Assert.isNotNull(invalidReport);

    // Should return empty or default data structures rather than throwing exceptions
}

@IsTest
static void testBulkMetricProcessing() {
    List<Performance_Metric__c> bulkMetrics = new List<Performance_Metric__c>();

    // Create 200 test metrics for bulk processing
    for (Integer i = 0; i < 200; i++) {
        bulkMetrics.add(new Performance_Metric__c(
            Metric_Type__c        = 'Processing Time',
            Metric_Value__c       = Math.random() * 10,
            Unit_of_Measure__c    = 'seconds',
            Component_Name__c     = 'Bulk Test Component ' + i,
            Recorded_At__c        = System.now().addMinutes(-i),
            Baseline_Value__c     = 3.0,
            Threshold_Warning__c  = 5.0,
            Threshold_Critical__c = 10.0,
            Alert_Status__c       = 'Normal'
        ));
    }

    Test.startTest();
    insert bulkMetrics;

    Map<String, Object> dashboardData = ProductionMonitoringController.getDashboardData();
    Test.stopTest();

    // Verify bulk processing
    Assert.isNotNull(dashboardData);
}

@IsTest
static void testRealTimeMonitoring() {
    Test.startTest();

    // Simulate real-time monitoring scenario
    Map<String, Object> realTimeData = ProductionMonitoringController.getDashboardData();

    // Wait briefly (simulated)
    System.runAs(new User(Id = UserInfo.getUserId())) {
        // Update a performance metric
        Performance_Metric__c metric = [SELECT Id FROM Performance_Metric__c LIMIT 1];
        metric.Metric_Value__c = 8.5; // Update to warning level
        metric.Alert_Status__c = 'Warning';
        update metric;
    }

    // Get updated dashboard data
    Map<String, Object> updatedData = ProductionMonitoringController.getDashboardData();

    Test.stopTest();

    // Verify real-time updates are reflected
    Assert.isNotNull(realTimeData);
    Assert.isNotNull(updatedData);
}
}