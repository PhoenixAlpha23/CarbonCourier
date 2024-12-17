import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class StatsPage extends StatelessWidget {
  final double totalDistance; // Total distance traveled
  final double totalEmissions; // Emissions in g/km
  final double carbonRank; // Rank between 0.0 and 5.0

  const StatsPage({
    super.key,
    required this.totalDistance,
    required this.totalEmissions,
    required this.carbonRank,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Stats'),
        backgroundColor: const Color(0xFF2D5A27), // Forest Green
      ),
      backgroundColor: const Color(0xFFF5F5F0), // Natural White
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Total Distance: ${totalDistance.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF2C2C2C), // Charcoal
              ),
            ),
            _buildSpeedometer(),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedometer() {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 500, // Example max 
          ranges: [
            GaugeRange(startValue: 0, endValue: 150, color: Colors.green),
            GaugeRange(startValue: 150, endValue: 300, color: Colors.yellow),
            GaugeRange(startValue: 300, endValue: 500, color: Colors.red),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(value: totalEmissions),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Text(
                '${totalEmissions.toStringAsFixed(1)} g/km',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge() {
    String badgeImage = _getBadgeImage();
    return Column(
      children: [
        Image.asset(
          badgeImage,
          height: 100,
          width: 100,
        ),
        Text(
          'Carbon Rank: ${carbonRank.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5A27), // Forest Green
          ),
        ),
      ],
    );
  }

  String _getBadgeImage() {
    if (carbonRank < 1.0) return 'assets/tree_1.png';
    if (carbonRank < 2.0) return 'assets/tree_2.png';
    if (carbonRank < 3.0) return 'assets/tree_3.png';
    if (carbonRank < 4.0) return 'assets/tree_4.png';
    return 'assets/tree_5.png';
  }
}
