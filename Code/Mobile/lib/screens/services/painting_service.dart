import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'service_detail_page.dart';


class PaintingServicePage extends StatelessWidget {
  const PaintingServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': 'Complete Car Painting',
        'description': 'Comprehensive exterior painting with high quality and various colors',
      },
      {
        'title': 'Partial Painting',
        'description': 'Painting specific parts of the car to renew its appearance',
      },
      {
        'title': 'Scratch Repair',
        'description': 'Fixing scratches and small marks on the car',
      },
      {
        'title': 'Paint Protection',
        'description': 'Applying a protective layer to maintain shine and paint quality for longer',
      },
      {
        'title': 'Polishing and Treatment',
        'description': 'Polishing the paint and removing dirt and oxidation to restore original shine',
      },
    ];

    final packages = [
      {
        'name': 'Polishing and Protection Package',
        'price': 399,
        'features': [
          'Deep car cleaning',
          'Paint polishing',
          'Surface scratch removal',
          'Paint protection layer application',
          'Glass and tire polishing',
        ],
      },
      {
        'name': 'Partial Painting Package',
        'price': 799,
        'features': [
          'Painting one part of the car',
          'Scratch and mark repair',
          'Polishing and cleaning the painted part',
          'One year warranty on paint',
          'Ability to choose appropriate color',
        ],
      },
      {
        'name': 'Comprehensive Painting Package',
        'price': 2499,
        'features': [
          'Complete exterior car painting',
          'Old paint removal',
          'Minor body damage repair',
          'Base and protection layer application',
          'Two-year warranty on paint',
          'Free polishing service after 6 months',
          'Ability to choose custom colors',
        ],
      },
    ];

    return Scaffold(
      body: ServiceDetailPage(
        icon: FontAwesomeIcons.paintRoller,
        title: 'Painting Services',
        color: Colors.red,
        features: features,
        packages: packages,
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const MyPackagesScreen(),
      //       ),
      //     );
      //   },
      //   icon: const Icon(Icons.inventory_2),
      //   label: const Text('My Packages'),
      //   backgroundColor: Colors.red,
      // ),
    );
  }
} 