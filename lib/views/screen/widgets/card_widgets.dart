// widgets/emergency_card.dart
import 'package:flutter/material.dart';
import 'package:rescuer/constants/app_colors.dart';
import 'package:rescuer/model/emergency_model.dart';

class EmergencyCard extends StatelessWidget {
  final Emergency emergency;
  final VoidCallback? onPressed;

  const EmergencyCard({
    Key? key,
    required this.emergency,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (emergency.status) {
      case 'ongoing':
        statusColor = Colors.orange;
        statusText = 'Ongoing';
        statusIcon = Icons.directions_run;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Pending';
        statusIcon = Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Information
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergency.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          emergency.userContact,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Emergency Details
              // _buildDetailRow(Icons.location_on, emergency.location),
              _buildDetailRow(Icons.home, emergency.userAddress),
              _buildDetailRow(Icons.access_time, 
                '${emergency.createdAt.hour}:${emergency.createdAt.minute.toString().padLeft(2, '0')} - '
                '${emergency.createdAt.day}/${emergency.createdAt.month}/${emergency.createdAt.year}'),
              
              const SizedBox(height: 12),
              
              // Action Button
              if (onPressed != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emergency.status == 'pending'
                          ? Colors.green
                          : emergency.status == 'ongoing'
                              ? Colors.blue
                              : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onPressed,
                    child: Text(
                      emergency.status == 'pending'
                          ? 'Accept Emergency'
                          : emergency.status == 'ongoing'
                              ? 'Mark as Completed'
                              : 'View Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}