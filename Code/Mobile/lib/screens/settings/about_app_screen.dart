import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'About App',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            _buildAppInfoSection(),
            _buildFeaturesSection(),
            _buildTeamSection(),
            _buildSocialSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.car_repair,
              color: AppColors.primary,
              size: 80,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Auto Service App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your Complete Car Service Solution',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildInfoCard(
            'Version',
            _packageInfo?.version ?? '1.0.0',
            Icons.info_outline,
          ),
          _buildInfoCard(
            'Build Number',
            _packageInfo?.buildNumber ?? '1',
            Icons.build_outlined,
          ),
          _buildInfoCard(
            'Package Name',
            _packageInfo?.packageName ?? 'com.autoservice.app',
            Icons.apps_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Easy Booking',
        'description': 'Book car services with just a few taps',
        'icon': Icons.calendar_today_outlined,
      },
      {
        'title': 'Service Tracking',
        'description': 'Track your service status in real-time',
        'icon': Icons.track_changes_outlined,
      },
      {
        'title': 'Payment Options',
        'description': 'Multiple secure payment methods',
        'icon': Icons.payment_outlined,
      },
      {
        'title': 'Service History',
        'description': 'Keep track of all your car services',
        'icon': Icons.history_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return _buildFeatureCard(features[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              feature['icon'] as IconData,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature['title'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            feature['description'] as String,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    final List<Map<String, dynamic>> team = [
      {
        'name': 'John Doe',
        'role': 'Lead Developer',
        'image': 'assets/image/7309681.jpg',
      },
      {
        'name': 'Jane Smith',
        'role': 'UI/UX Designer',
        'image': 'assets/image/7309681.jpg',
      },
      {
        'name': 'Mike Johnson',
        'role': 'Product Manager',
        'image': 'assets/image/7309681.jpg',
      }, {
        'name': 'John Doe',
        'role': 'Lead Developer',
        'image': 'assets/image/7309681.jpg',
      },
      {
        'name': 'Jane Smith',
        'role': 'UI/UX Designer',
        'image': 'assets/image/7309681.jpg',
      },
      {
        'name': 'Mike Johnson',
        'role': 'Product Manager',
        'image': 'assets/image/7309681.jpg',
      },{
        'name': 'Jane Smith',
        'role': 'UI/UX Designer',
        'image': 'assets/image/7309681.jpg',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Team',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: team.length,
              itemBuilder: (context, index) {
                return _buildTeamMemberCard(team[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(member['image'] as String),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              member['name'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              member['role'] as String,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect With Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                FontAwesomeIcons.facebook,
                'Facebook',
                () => _launchUrl('https://facebook.com/autoservice'),
              ),
              _buildSocialButton(
                FontAwesomeIcons.twitter,
                'Twitter',
                () => _launchUrl('https://twitter.com/autoservice'),
              ),
              _buildSocialButton(
                FontAwesomeIcons.instagram,
                'Instagram',
                () => _launchUrl('https://instagram.com/autoservice'),
              ),
              _buildSocialButton(
                FontAwesomeIcons.linkedin,
                'LinkedIn',
                () => _launchUrl('https://linkedin.com/company/autoservice'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: FaIcon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
} 