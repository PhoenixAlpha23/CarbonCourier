import 'package:flutter/material.dart';
import 'dart:math';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  double totalCarbonEmissions = 150.5; // Example value
  double distanceTravelled = 2500; // Example value
  DateTime nextServiceDate =
      DateTime.now().add(const Duration(days: 30)); // Example value

  // Generate sample emission data for the speedometer
  List<double> dailyEmissions =
      List.generate(7, (index) => Random().nextDouble() * 500);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Total Carbon Emissions: $totalCarbonEmissions kg'),
            Text('Distance Travelled: $distanceTravelled km'),
            Text(
                'Next Recommended Service Date: ${nextServiceDate.toString().substring(0, 10)}'), // Display date only
            SizedBox(height: 20),
            //Speedometer
            CustomPaint(
              size: const Size(200, 200),
              painter: SpeedometerPainter(dailyEmissions),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final List<double> emissionData;

  SpeedometerPainter(this.emissionData);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.8;

    // Draw the speedometer arc
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi,
      false,
      paint,
    );

    // Calculate the needle position based on the average daily emission
    final averageEmission =
        emissionData.reduce((a, b) => a + b) / emissionData.length;
    final needleAngle = -pi / 2 + (averageEmission / 500) * pi;

    // Draw the needle
    final needlePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5;

    canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(needleAngle),
            center.dy + radius * sin(needleAngle)),
        needlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
