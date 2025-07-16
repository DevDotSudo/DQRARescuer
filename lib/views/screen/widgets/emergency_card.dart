import 'package:flutter/material.dart';
import 'package:rescuer/constants/app_colors.dart';
import 'package:rescuer/model/emergency_model.dart';

class EmergencyCard extends StatelessWidget {
  final Emergency emergency;
  final VoidCallback? onPressed;
  final VoidCallback? mapOnPressed;

  const EmergencyCard({
    Key? key,
    required this.emergency,
    this.onPressed,
    this.mapOnPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Status configuration
    StatusConfig statusConfig = _getStatusConfig(emergency.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar with colored border
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusConfig.color.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.black54,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergency.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              emergency.userContact,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusConfig.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusConfig.icon,
                          size: 16,
                          color: statusConfig.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusConfig.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusConfig.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Emergency type
              _buildDetailRow(
                Icons.warning_rounded,
                emergency.emergencyType,
                "Emergency Type",
              ),
              
              // Emergency description if available
              if (emergency.emergencyDescription.isNotEmpty)
                _buildDetailRow(
                  Icons.description_rounded,
                  emergency.emergencyDescription,
                  "Description",
                ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey.withOpacity(0.15),
              ),
              
              const SizedBox(height: 16),
              
              // Emergency details
              _buildDetailRow(
                Icons.home_rounded,
                emergency.userAddress,
                "Address",
              ),
              
              _buildDetailRow(
                Icons.access_time_rounded,
                '${emergency.createdAt.hour}:${emergency.createdAt.minute.toString().padLeft(2, '0')} - '
                '${emergency.createdAt.day}/${emergency.createdAt.month}/${emergency.createdAt.year}',
                "Date & Time",
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons - Only show when appropriate
              if (onPressed != null || (mapOnPressed != null && emergency.status != 'completed'))
                Row(
                  children: [
                    if (onPressed != null)
                      Expanded(
                        flex: 3,
                        child: _buildActionButton(
                          onPressed: onPressed!,
                          text: _getActionButtonText(emergency.status),
                          backgroundColor: statusConfig.actionColor,
                          icon: _getActionIcon(emergency.status),
                        ),
                      ),
                    if (onPressed != null && mapOnPressed != null && emergency.status != 'completed')
                      const SizedBox(width: 12),
                    if (mapOnPressed != null && emergency.status != 'completed')
                      Expanded(
                        flex: 2,
                        child: _buildActionButton(
                          onPressed: mapOnPressed!,
                          text: "View Map",
                          backgroundColor: Colors.blueAccent,
                          icon: Icons.map_rounded,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String text,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'ongoing':
        return StatusConfig(
          color: Colors.orange,
          text: 'Ongoing',
          icon: Icons.directions_run_rounded,
          actionColor: Colors.green.shade600,
        );
      case 'completed':
        return StatusConfig(
          color: Colors.green,
          text: 'Completed',
          icon: Icons.check_circle_rounded,
          actionColor: Colors.grey,
        );
      default:
        return StatusConfig(
          color: Colors.blue,
          text: 'Pending',
          icon: Icons.access_time_rounded,
          actionColor: Colors.green.shade600,
        );
    }
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case 'pending':
        return 'Accept';
      case 'ongoing':
        return 'Complete';
      default:
        return 'View Details';
    }
  }

  IconData _getActionIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.check_rounded;
      case 'ongoing':
        return Icons.done_all_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class StatusConfig {
  final Color color;
  final String text;
  final IconData icon;
  final Color actionColor;

  StatusConfig({
    required this.color,
    required this.text,
    required this.icon,
    required this.actionColor,
  });
}