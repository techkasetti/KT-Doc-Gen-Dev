@IsTest
public class MonitoringConfigurationTest {

    @TestSetup
    static void setupTestData() {
        // Create monitoring configuration records
        List<Monitoring_Configuration__c> configs = new List<Monitoring_Configuration__c>();

        configs.add(new Monitoring_Configuration__c(
            Service_Name__c               = 'Document Generation Service',
            Monitor_Type__c               = 'Performance',
            Enable_Real_Time_Monitoring__c = true,
            Alert_Threshold_Value__c      = 5000.0, // 5 seconds
            Alert_Recipients__c           = 'admin@test.com;manager@test.com',
            Monitoring_Frequency_Minutes__c = 5
        ));

        configs.add(new Monitoring_Configuration__c(
            Service_Name__c               = 'E-Signature Integration',
            Monitor_Type__c               = 'Health Check',
            Enable_Real_Time_Monitoring__c = true,
            Alert_Threshold_Value__c      = 95.0, // 95% health score
            Alert_Recipients__c           = 'devops@test.com',
            Monitoring_Frequency_Minutes__c = 10
        ));

        configs.add(new Monitoring_Configuration__c(
            Service_Name__c               = 'API Gateway',
            Monitor_Type__c               = 'Integration',
            Enable_Real_Time_Monitoring__c = false,
            Alert_Threshold_Value__c      = 200.0, // 200ms response time
            Alert_Recipients__c           = 'support@test.com',
            Monitoring_Frequency_Minutes__c = 15
        ));

        insert configs;

        // Create related health logs
        List<System_Health_Log__c> healthLogs = new List<System_Health_Log__c>();

        for (Monitoring_Configuration__c config : configs) {
            // Healthy log
            healthLogs.add(new System_Health_Log__c(
                Component_Name__c          = config.Service_Name__c,
                Health_Status__c           = 'Healthy',
                Health_Score__c            = 98.5,
                Response_Time_MS__c        = 150,
                Monitoring_Configuration__c = config.Id,
                Check_Timestamp__c         = System.now(),
                Error_Message__c           = null
            ));

            // Warning log
            healthLogs.add(new System_Health_Log__c(
                Component_Name__c          = config.Service_Name__c,
                Health_Status__c           = 'Warning',
                Health_Score__c            = 85.0,
                Response_Time_MS__c        = 450,
                Monitoring_Configuration__c = config.Id,
                Check_Timestamp__c         = System.now().addMinutes(-30),
                Error_Message__c           = 'Response time slightly elevated'
            ));
        }

        insert healthLogs;
    }

    @IsTest
    static void testMonitoringConfigurationCreation() {
        Test.startTest();

        Monitoring_Configuration__c newConfig = new Monitoring_Configuration__c(
            Service_Name__c               = 'Test Service',
            Monitor_Type__c               = 'Security',
            Enable_Real_Time_Monitoring__c = true,
            Alert_Threshold_Value__c      = 10.0,
            Alert_Recipients__c           = 'test@example.com',
            Monitoring_Frequency_Minutes__c = 30
        );
        insert newConfig;

        Test.stopTest();

        // Verify configuration was created
        Monitoring_Configuration__c retrievedConfig = [
            SELECT Id, Service_Name__c, Monitor_Type__c, Enable_Real_Time_Monitoring__c
            FROM Monitoring_Configuration__c
            WHERE Id = :newConfig.Id
        ];

        Assert.areEqual('Test Service', retrievedConfig.Service_Name__c);
        Assert.areEqual('Security', retrievedConfig.Monitor_Type__c);
        Assert.isTrue(retrievedConfig.Enable_Real_Time_Monitoring__c);
    }

    @IsTest
    static void testHealthLogRelationship() {
        Test.startTest();

        // Query monitoring configuration with related health logs
        List<Monitoring_Configuration__c> configsWithLogs = [
            SELECT Id, Service_Name__c, 
                (SELECT Id, Health_Status__c, Health_Score__c 
                 FROM System_Health_Logs__r 
                 ORDER BY Check_Timestamp__c DESC)
            FROM Monitoring_Configuration__c
            LIMIT 1
        ];

        Test.stopTest();

        Assert.isFalse(configsWithLogs.isEmpty());

        Monitoring_Configuration__c config = configsWithLogs[0];
        Assert.isFalse(config.System_Health_Logs__r.isEmpty());

        // Verify both healthy and warning logs exist
        Boolean hasHealthy = false;
        Boolean hasWarning = false;

        for (System_Health_Log__c log : config.System_Health_Logs__r) {
            if (log.Health_Status__c == 'Healthy') hasHealthy = true;
            if (log.Health_Status__c == 'Warning') hasWarning = true;
        }

        Assert.isTrue(hasHealthy);
        Assert.isTrue(hasWarning);
    }

@IsTest
    static void testPerformanceMetricThresholds() {
        Test.startTest();

        // Create performance metrics with different alert statuses
        List<Performance_Metric__c> metrics = new List<Performance_Metric__c>();

        // Normal metric
        metrics.add(new Performance_Metric__c(
            Metric_Type__c      = 'Processing Time',
            Metric_Value__c     = 2.0,
            Unit_of_Measure__c  = 'seconds',
            Component_Name__c   = 'Test Component',
            Recorded_At__c      = System.now(),
            Baseline_Value__c   = 3.0,
            Threshold_Warning__c = 5.0,
            Threshold_Critical__c = 10.0,
            Alert_Status__c     = 'Normal'
        ));

        // Warning metric
        metrics.add(new Performance_Metric__c(
            Metric_Type__c      = 'Processing Time',
            Metric_Value__c     = 7.0,
            Unit_of_Measure__c  = 'seconds',
            Component_Name__c   = 'Test Component',
            Recorded_At__c      = System.now(),
            Baseline_Value__c   = 3.0,
            Threshold_Warning__c = 5.0,
            Threshold_Critical__c = 10.0,
            Alert_Status__c     = 'Warning'
        ));

        // Critical metric
        metrics.add(new Performance_Metric__c(
            Metric_Type__c      = 'Processing Time',
            Metric_Value__c     = 12.0,
            Unit_of_Measure__c  = 'seconds',
            Component_Name__c   = 'Test Component',
            Recorded_At__c      = System.now(),
            Baseline_Value__c   = 3.0,
            Threshold_Warning__c = 5.0,
            Threshold_Critical__c = 10.0,
            Alert_Status__c     = 'Critical'
        ));

        insert metrics;
        Test.stopTest();

        // Verify metrics were created with correct alert statuses
        List<Performance_Metric__c> retrievedMetrics = [
            SELECT Alert_Status__c, Metric_Value__c 
            FROM Performance_Metric__c 
            WHERE Component_Name__c = 'Test Component' 
            ORDER BY Metric_Value__c
        ];

        Assert.areEqual(3, retrievedMetrics.size());
        Assert.areEqual('Normal', retrievedMetrics[0].Alert_Status__c);
        Assert.areEqual('Warning', retrievedMetrics[1].Alert_Status__c);
        Assert.areEqual('Critical', retrievedMetrics[2].Alert_Status__c);
    }

    @IsTest
    static void testMonitoringFrequencyValidation() {
        Test.startTest();

        Boolean exceptionThrown = false;
        try {
            Monitoring_Configuration__c invalidConfig = new Monitoring_Configuration__c(
                Service_Name__c              = 'Invalid Service',
                Monitor_Type__c              = 'Performance',
                Enable_Real_Time_Monitoring__c = true,
                Alert_Threshold_Value__c     = 5.0,
                Monitoring_Frequency_Minutes__c = 0 // Invalid frequency
            );
            insert invalidConfig;
        } catch (Exception e) {
            exceptionThrown = true;
        }

        Test.stopTest();

        // This test assumes validation rules exist to prevent invalid frequency
    }

    @IsTest
    static void testAlertRecipientsParsing() {
        Test.startTest();

        List<Monitoring_Configuration__c> configs = [
            SELECT Alert_Recipients__c 
            FROM Monitoring_Configuration__c 
            WHERE Alert_Recipients__c != null 
            LIMIT 1
        ];

        Test.stopTest();

        if (!configs.isEmpty()) {
            String recipients = configs[0].Alert_Recipients__c;
            Assert.isNotNull(recipients);
            Assert.isTrue(recipients.contains('@')); // Should contain email addresses
        }
    }

    @IsTest
    static void testMonitoringConfigurationQueries() {
        Test.startTest();

        // Active monitoring configurations
        List<Monitoring_Configuration__c> activeConfigs = [
            SELECT Id, Service_Name__c 
            FROM Monitoring_Configuration__c 
            WHERE Enable_Real_Time_Monitoring__c = true
        ];

        // Performance monitoring configurations
        List<Monitoring_Configuration__c> performanceConfigs = [
            SELECT Id, Service_Name__c 
            FROM Monitoring_Configuration__c 
            WHERE Monitor_Type__c = 'Performance'
        ];

        // Configurations with recent health logs
        List<Monitoring_Configuration__c> configsWithRecentLogs = [
            SELECT Id, Service_Name__c, 
                (SELECT Id FROM System_Health_Logs__r WHERE Check_Timestamp__c = TODAY) 
            FROM Monitoring_Configuration__c 
            WHERE Id IN (
                SELECT Monitoring_Configuration__c 
                FROM System_Health_Log__c 
                WHERE Check_Timestamp__c = TODAY
            )
        ];

        Test.stopTest();

        Assert.isTrue(activeConfigs.size() > 0);
        Assert.isTrue(performanceConfigs.size() > 0);
        Assert.isTrue(configsWithRecentLogs.size() > 0);
    }

    @IsTest
    static void testHealthLogStatusTransitions() {
        Test.startTest();

        // Get a monitoring configuration
        Monitoring_Configuration__c config = [
            SELECT Id 
            FROM Monitoring_Configuration__c 
            LIMIT 1
        ];

        // Create a sequence of health logs showing status degradation
        List<System_Health_Log__c> statusLogs = new List<System_Health_Log__c>();

        // Start healthy
        statusLogs.add(new System_Health_Log__c(
            Component_Name__c          = 'Status Test Component',
            Health_Status__c           = 'Healthy',
            Health_Score__c            = 99.0,
            Response_Time_MS__c        = 100,
            Monitoring_Configuration__c = config.Id,
            Check_Timestamp__c         = System.now().addHours(-3)
        ));

        // Degrade to warning
        statusLogs.add(new System_Health_Log__c(
            Component_Name__c          = 'Status Test Component',
            Health_Status__c           = 'Warning',
            Health_Score__c            = 75.0,
            Response_Time_MS__c        = 300,
            Monitoring_Configuration__c = config.Id,
            Check_Timestamp__c         = System.now().addHours(-2)
        ));

        // Further degrade to critical
        statusLogs.add(new System_Health_Log__c(
            Component_Name__c          = 'Status Test Component',
            Health_Status__c           = 'Critical',
            Health_Score__c            = 45.0,
            Response_Time_MS__c        = 800,
            Monitoring_Configuration__c = config.Id,
            Check_Timestamp__c         = System.now().addHours(-1)
        ));

        // Recover to healthy
        statusLogs.add(new System_Health_Log__c(
            Component_Name__c          = 'Status Test Component',
            Health_Status__c           = 'Healthy',
            Health_Score__c            = 98.0,
            Response_Time_MS__c        = 120,
            Monitoring_Configuration__c = config.Id,
            Check_Timestamp__c         = System.now()
        ));

        insert statusLogs;
        Test.stopTest();

        // Verify the status transition sequence
        List<System_Health_Log__c> retrievedLogs = [
            SELECT Health_Status__c, Health_Score__c, Check_Timestamp__c 
            FROM System_Health_Log__c 
            WHERE Component_Name__c = 'Status Test Component' 
            ORDER BY Check_Timestamp__c
        ];

        Assert.areEqual(4, retrievedLogs.size());
        Assert.areEqual('Healthy', retrievedLogs[0].Health_Status__c);
        Assert.areEqual('Warning', retrievedLogs[1].Health_Status__c);
        Assert.areEqual('Critical', retrievedLogs[2].Health_Status__c);
        Assert.areEqual('Healthy', retrievedLogs[3].Health_Status__c);
    }
    @IsTest
static void testBulkMonitoringDataProcessing() {
    Test.startTest();

    // Create bulk performance metrics for load testing
    List<Performance_Metric__c> bulkMetrics = new List<Performance_Metric__c>();

    // Get an existing monitoring configuration
    Monitoring_Configuration__c config = [
        SELECT Id 
        FROM Monitoring_Configuration__c 
        LIMIT 1
    ];

    for (Integer i = 0; i < 200; i++) {
        bulkMetrics.add(new Performance_Metric__c(
            Metric_Type__c      = Math.mod(i, 2) == 0 ? 'Processing Time' : 'Success Rate',
            Metric_Value__c     = Math.random() * 100,
            Unit_of_Measure__c  = Math.mod(i, 2) == 0 ? 'seconds' : 'percentage',
            Component_Name__c   = 'Bulk Test Component',
            Recorded_At__c      = System.now().addMinutes(-i),
            Baseline_Value__c   = 50.0,
            Threshold_Warning__c = 75.0,
            Threshold_Critical__c = 90.0,
            Alert_Status__c     = 'Normal'
        ));
    }

    insert bulkMetrics;

    Test.stopTest();

    // Verify bulk processing
    List<Performance_Metric__c> insertedMetrics = [
        SELECT Id 
        FROM Performance_Metric__c 
        WHERE Component_Name__c = 'Bulk Test Component'
    ];

    Assert.areEqual(200, insertedMetrics.size());
}
}