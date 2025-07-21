import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'service_detail_page.dart';

class MaintenanceServicePage extends StatelessWidget {
  const MaintenanceServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Comprehensive Car Inspection',
        'description': 'Inspect all car systems to ensure their safety and proper operation',
      },
      {
        'title': 'Engine Maintenance',
        'description': 'Check, clean, and repair engine parts for optimal performance',
      },
      {
        'title': 'Brake System Maintenance',
        'description': 'Check, clean, and repair brake system to ensure safety',
      },
      {
        'title': 'Suspension System Maintenance',
        'description': 'Check and repair suspension system to ensure comfort and control',
      },
      {
        'title': 'Cooling System Maintenance',
        'description': 'Check, clean, and repair cooling system to prevent overheating',
      },
    ];

    final packages = [
      {
        'name': 'Basic Package',
        'price': 299,
        'features': [
          'Comprehensive car inspection',
          'Engine oil and filter change',
          'Brake system check',
          'Fluid levels check',
          'Vehicle condition report',
        ],
      },
      {
        'name': 'Standard Package',
        'price': 599,
        'features': [
          'All Basic Package services',
          'Air filter replacement',
          'Spark plugs replacement',
          'Brake adjustment and cleaning',
          'Suspension system check and adjustment',
          'Battery and electrical system check',
        ],
      },
      {
        'name': 'Comprehensive Package',
        'price': 999,
        'features': [
          'All Standard Package services',
          'Fuel filter replacement',
          'Injection system cleaning',
          'Transmission check and adjustment',
          'Cooling system check and cleaning',
          'Wheel alignment check and adjustment',
          'Comprehensive car polishing and cleaning',
        ],
      },
    ];

    return Scaffold(
      body: ServiceDetailPage(
        icon: FontAwesomeIcons.car,
        title: 'Periodic Maintenance',
        color: Colors.orange,
        features: features,
        packages: packages,
      ),
    );
  }
} 