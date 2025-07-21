import 'package:flutter/material.dart';

class RemoveProductDialog extends StatelessWidget {
  const RemoveProductDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        width: 400,
        height: 200,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Are you sure you want to Remove this item?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF6C6C6C),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Save for Later Button
                SizedBox(
                  width: 160,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(
                          color: Color(0xFFEEEEEE),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Save for Later',
                      style: TextStyle(
                        color: Color(0xFF6C6C6C),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Remove Button
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Return true to indicate removal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
