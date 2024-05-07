import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore



class UsageData {
  final DateTime date;
  final int totalUsers;

  UsageData(this.date, this.totalUsers);
}



class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<UsageData> _usageData = [];

  @override
  void initState() {
    super.initState();
    _retrieveAnalyticsData();
  }

  Future<void> _retrieveAnalyticsData() async {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final firestore = FirebaseFirestore.instance;

    // Retrieve user count from Firestore
    final snapshot = await firestore.collection('users').get();

    final int userCount = snapshot.docs.length;

    // Retrieve user engagement data for the last 7 days
    for (int i = 0; i < 7; i++) {
      final DateTime date = DateTime.now().subtract(Duration(days: i));

      _usageData.add(UsageData(date, userCount));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _usageData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : SfCartesianChart(
                title: ChartTitle(text: 'Total Users Over Time'),
                legend: Legend(isVisible: true),
                primaryXAxis: DateTimeAxis(
                  title: AxisTitle(text: 'Date'),
                  dateFormat: DateFormat.yMd(),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Total Users'),
                ),
                series: <CartesianSeries<dynamic, dynamic>>[
                  LineSeries<UsageData, DateTime>(
                    dataSource: _usageData,
                    xValueMapper: (UsageData usage, _) => usage.date,
                    yValueMapper: (UsageData usage, _) =>
                        usage.totalUsers.toDouble(),
                    name: 'Total Users',
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  header: '',
                  canShowMarker: false,
                  format: 'Total Users: point.y',
                ),
              ),
      ),
    );
  }
}