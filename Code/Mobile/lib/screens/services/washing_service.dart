import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'service_detail_page.dart';

class WashingServicePage extends StatelessWidget {
  const WashingServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Exterior Washing',
        'description': 'Complete washing of the car exterior with polishing',
      },
      {
        'title': 'Interior Cleaning',
        'description': 'Comprehensive cleaning of the car interior',
      },
      {
        'title': 'Engine Cleaning',
        'description': 'Cleaning the engine bay and removing dirt and grease',
      },
      {
        'title': 'Polishing',
        'description': 'Polishing the exterior to restore shine and luster',
      },
      {
        'title': 'Fragrancing',
        'description': 'Interior fragrancing with refreshing and lasting scents',
      },
    ];

    final packages = [
      {
        'name': 'Basic Wash',
        'price': 49,
        'features': [
          'Exterior washing',
          'Body polishing',
          'Tire cleaning',
          'Glass cleaning',
        ],
      },
      {
        'name': 'Comprehensive Wash',
        'price': 149,
        'features': [
          'Exterior washing',
          'Interior cleaning',
          'Body polishing',
          'Tire cleaning',
          'Glass cleaning',
          'Interior fragrancing',
          'Vent cleaning',
        ],
      },
      {
        'name': 'VIP Premium Wash',
        'price': 299,
        'features': [
          'Advanced exterior washing',
          'Comprehensive interior cleaning',
          'Engine cleaning',
          'Body polishing',
          'Tire and rim cleaning',
          'Glass cleaning',
          'Interior fragrancing',
          'Vent cleaning',
          'Sunroof cleaning',
          'Wax protection',
        ],
      },
    ];

    return Scaffold(
      body: ServiceDetailPage(
        icon: FontAwesomeIcons.car,
        title: 'Car Washing Service',
        color: Colors.blue,
        features: features,
        packages: packages,
      ),
    );
  }
  
} 