import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TAXI CUSTOMER TERMS & CONDITIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'IMPORTANT:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'THESE TERMS AND CONDITIONS ("Conditions") DEFINE THE BASIS UPON '
                      'WHICH GETT WILL PROVIDE YOU WITH ACCESS TO THE GETT MOBILE '
                      'APPLICATION PLATFORM, PURSUANT TO WHICH YOU WILL BE ABLE TO '
                      'REQUEST CERTAIN TRANSPORTATION SERVICES FROM THIRD PARTY DRIVERS '
                      'BY PLACING ORDERS THROUGH GETT\'S MOBILE APPLICATION PLATFORM. '
                      'THESE CONDITIONS (TOGETHER WITH THE DOCUMENTS REFERRED TO HEREIN) '
                      'SET OUT THE TERMS OF USE ON WHICH YOU MAY, AS A CUSTOMER, USE '
                      'THE APP AND REQUEST TRANSPORTATION SERVICES. BY USING THE APP '
                      'AND TICKING THE ACCEPTANCE BOX, YOU INDICATE THAT YOU ACCEPT '
                      'THESE TERMS OF USE WHICH APPLY, AMONG OTHER THINGS, TO ALL '
                      'SERVICES HEREINUNDER TO BE RENDERED TO OR BY YOU VIA THE APP '
                      'WITHIN THE UK AND THAT YOU AGREE TO ABIDE BY THEM. USE THE APP '
                      'AND REQUEST TRANSPORTATION SERVICES. BY USING THE APP AND '
                      'TICKING THE ACCEPTANCE BOX, YOU INDICATE THAT YOU ACCEPT THESE '
                      'TERMS OF USE WHICH APPLY, AMONG OTHER THINGS, TO ALL SERVICES '
                      'HEREINUNDER TO BE RENDERED TO OR BY YOU VIA THE APP WITHIN THE '
                      'UK AND THAT YOU AGREE TO ABIDE BY THEM.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
