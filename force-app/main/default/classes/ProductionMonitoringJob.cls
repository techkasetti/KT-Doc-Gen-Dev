global class ProductionMonitoringJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Monitor system health every hour
        ProductionHealthMonitor.performHealthCheck();
        // Generate daily analytics report
if (System.now().hour() == 9) { // 9 AM daily report
    ProductionAnalytics.generateDailyReport();
}

// Weekly comprehensive report
if (System.now().format('E') == 'Mon' && System.now().hour() == 8) { // 8 AM Monday
    ProductionAnalytics.generateWeeklyReport();
}

// Monthly executive dashboard
if (System.now().day() == 1 && System.now().hour() == 7) { // 7 AM first of month
    ProductionAnalytics.generateMonthlyExecutiveReport();
}
