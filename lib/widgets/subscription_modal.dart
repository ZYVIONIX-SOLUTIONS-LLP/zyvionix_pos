import 'package:flutter/material.dart';

class SubscriptionModal extends StatefulWidget {
  const SubscriptionModal({super.key});

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  int _selectedPlanIndex = 1; // Default to Professional


  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required Color color,
    bool isSelected = false,
    bool isPopular = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'MOST POPULAR',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0, left: 4.0),
                child: Text('/month'),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? color : Colors.grey.shade100,
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isSelected ? 'Get Started' : 'Select Plan'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: 600,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EA1F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      color: Color(0xFF1EA1F2),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloud Storage Plans',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Choose a plan that scales with your business',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Plan Cards Scroll View
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildPlanCard(
                    context: context,
                    title: 'Starter',
                    price: '\$15',
                    description: 'Perfect for small businesses starting out.',
                    color: Colors.blueGrey,
                    isSelected: _selectedPlanIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedPlanIndex = 0;
                      });
                    },
                    features: [
                      '5GB Cloud Storage',
                      'Sync across 2 devices',
                      'Basic Reports',
                      'Email Support',
                    ],
                  ),
                  _buildPlanCard(
                    context: context,
                    title: 'Professional',
                    price: '\$39',
                    description: 'For growing businesses with more needs.',
                    color: const Color(0xFF1EA1F2),
                    isPopular: true,
                    isSelected: _selectedPlanIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedPlanIndex = 1;
                      });
                    },
                    features: [
                      '50GB Cloud Storage',
                      'Sync across unlimited devices',
                      'Advanced Analytics',
                      '24/7 Priority Support',
                      'Custom Invoices',
                    ],
                  ),
                  _buildPlanCard(
                    context: context,
                    title: 'Enterprise',
                    price: '\$99',
                    description: 'Unlimited everything for large operations.',
                    color: Colors.deepPurple,
                    isSelected: _selectedPlanIndex == 2,
                    onTap: () {
                      setState(() {
                        _selectedPlanIndex = 2;
                      });
                    },
                    features: [
                      'Unlimited Cloud Storage',
                      'Dedicated Account Manager',
                      'Custom API Access',
                      'Multi-store Management',
                      'White-label options',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
