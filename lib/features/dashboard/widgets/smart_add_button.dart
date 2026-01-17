import 'package:flutter/material.dart';

class SmartAddButton extends StatelessWidget {
  final VoidCallback onScanSms;
  final VoidCallback onVoiceEntry;
  final VoidCallback onManualEntry;

  const SmartAddButton({
    super.key,
    required this.onScanSms,
    required this.onVoiceEntry,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (c) => Container(
            padding: const EdgeInsets.all(20),
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add Expense", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionItem(
                      icon: Icons.sms,
                      label: "Scan SMS",
                      onTap: () { Navigator.pop(c); onScanSms(); },
                    ),
                    _ActionItem(
                      icon: Icons.mic,
                      label: "Voice",
                      onTap: () { Navigator.pop(c); onVoiceEntry(); },
                    ),
                    _ActionItem(
                      icon: Icons.edit,
                      label: "Manual",
                      onTap: () { Navigator.pop(c); onManualEntry(); },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text("Add"),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            child: Icon(icon, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
