import 'package:flutter/material.dart';

class AdminUploadButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isUploading;
  final VoidCallback onPressed;

  const AdminUploadButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isUploading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isUploading ? null : onPressed,
      ),
    );
  }
}