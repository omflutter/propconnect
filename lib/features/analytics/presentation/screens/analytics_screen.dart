import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProperties = ref.watch(propertyProvider);
    final allDeals = ref.watch(dealProvider);
    final analytics = ref.watch(analyticsProvider);

    // Filter to Current Agency
    final userData = AuthStorageService.getUserData();
    final userAgencyMap = userData?['agency'] as Map<String, dynamic>?;
    final userAgencyId = userData?['agencyId'] ?? userAgencyMap?['id'];
    final currentAgency = (userAgencyMap?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? '';
    
    // 1. Calculate Property Metrics for Agency
    final agencyProperties = allProperties.where((p) {
      if (userAgencyId != null && p.agencyId != null && p.agencyId.toString() == userAgencyId.toString()) return true;
      if (currentAgency.isNotEmpty && p.agencyName.toLowerCase().trim() == currentAgency.toLowerCase().trim()) return true;
      return false;
    }).toList();
    final agencyPropertyIds = agencyProperties.map((p) => p.id).toSet();
    
    final activeProperties = agencyProperties.where((p) => p.status == 'Available').length;
    final publicProperties = agencyProperties.where((p) => p.isPublic).length;
    final privateProperties = agencyProperties.where((p) => !p.isPublic).length;

    // 2. Calculate Deal Metrics for Agency
    // We filter deals that involve properties owned by this agency
    final agencyDeals = allDeals.where((d) => agencyPropertyIds.contains(d.propertyId)).toList();
    
    final activeDeals = agencyDeals.where((d) => !d.isRequest && d.status != 'Closed').length;
    final closedDeals = agencyDeals.where((d) => !d.isRequest && d.status == 'Closed').length;
    final collabRequests = agencyDeals.where((d) => d.isRequest).length;

    // Mock Commission (Based on closed deals involving agency properties)
    final commissionGenerated = closedDeals * 100000;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agency Analytics', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Level Agency Metrics
            _buildSectionTitle('Agency Overview'),
            const Gap(16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Active Brokers', analytics.activeBrokers.toString(), Icons.people_outline, Colors.blue)),
                const Gap(16),
                Expanded(child: _buildMetricCard('Total Listings', agencyProperties.length.toString(), Icons.home_work_outlined, Colors.orange)),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total Commission', '₹${(commissionGenerated / 100000).toStringAsFixed(1)} L', Icons.monetization_on_outlined, Colors.green)),
              ],
            ),
            const Gap(32),

            // Deal Funnel
            _buildSectionTitle('Deal Funnel (Your Properties)'),
            const Gap(16),
            Row(
              children: [
                Expanded(child: _buildStatSquare('Requests', collabRequests.toString(), Colors.purple)),
                const Gap(12),
                Expanded(child: _buildStatSquare('Active', activeDeals.toString(), Colors.orange)),
                const Gap(12),
                Expanded(child: _buildStatSquare('Closed', closedDeals.toString(), Colors.green)),
              ],
            ),
            const Gap(32),

            // Property Breakdown
            _buildSectionTitle('Listing Breakdown'),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Available', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      Text(activeProperties.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Gap(16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: publicProperties == 0 && privateProperties == 0 ? 1 : publicProperties,
                          child: Container(height: 12, color: Colors.blue),
                        ),
                        Expanded(
                          flex: publicProperties == 0 && privateProperties == 0 ? 1 : privateProperties,
                          child: Container(height: 12, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      _buildLegendItem('Public', publicProperties, Colors.blue),
                      const Gap(24),
                      _buildLegendItem('Private', privateProperties, Colors.indigo),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(32),

            // Revenue Trends
            _buildSectionTitle('Performance Trends (Last 6 Months)'),
            const Gap(16),
            Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Monthly Commission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(24),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(months[value.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  );
                                }
                                return const Text('');
                              },
                              interval: 1,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${(value / 1000).toInt()}k', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
                              },
                              reservedSize: 40,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 400000,
                        lineBarsData: [
                          LineChartBarData(
                            spots: analytics.monthlyCommission.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                            isCurved: true,
                            color: AppColors.primaryBlue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Leads Generated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(24),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(months[value.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
                              },
                              reservedSize: 40,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: analytics.monthlyLeads.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value,
                                color: Colors.indigo,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Gap(4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatSquare(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const Gap(4),
          Text(title, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, int count, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(8),
        Text('$title ($count)', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}
