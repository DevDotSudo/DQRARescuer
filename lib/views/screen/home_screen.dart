import 'package:flutter/material.dart';
import 'package:rescuer/controller/home_controller.dart';
import 'package:rescuer/model/emergency_model.dart';
import 'package:rescuer/model/rescuer_model.dart';
import 'package:rescuer/services/emergency_services.dart';
import 'package:rescuer/utils/login_pref.dart';
import 'package:rescuer/views/screen/login_screen.dart';
import 'package:rescuer/views/screen/map_dialog.dart';
import 'package:rescuer/views/screen/widgets/app_bar.dart';
import 'package:rescuer/views/screen/widgets/confirmation_dialog.dart';
import 'package:rescuer/views/screen/widgets/custom_dialog.dart';
import 'package:rescuer/views/screen/widgets/emergency_card.dart';

class HomeScreen extends StatefulWidget {
  final Rescuer currentRescuer;

  const HomeScreen({Key? key, required this.currentRescuer}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);


    _controller = HomeController(
      emergencyService: EmergencyService(),
      currentRescuer: widget.currentRescuer,
    );

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Cases'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.access_time)),
            Tab(text: 'Ongoing', icon: Icon(Icons.directions_run)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
          ],
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: AppDrawer(
        rescuerName: widget.currentRescuer.fullName,
        rescuerMunicipality: widget.currentRescuer.municipality,
        onLogout: _confirmLogout,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmergencyList(_controller.getPendingEmergencies(), true),
          _buildEmergencyList(_controller.getOngoingEmergencies(), false),
          _buildEmergencyList(_controller.getCompletedEmergencies(), false),
        ],
      ),
    );
  }

  Widget _buildEmergencyList(Stream<List<Emergency>> emergencies, bool isPending) {
    return StreamBuilder<List<Emergency>>(
      stream: emergencies,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final emergencies = snapshot.data ?? [];

        if (emergencies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${isPending ? 'pending' : 'ongoing'} emergencies',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emergencies.length,
          itemBuilder: (context, index) {
            final emergency = emergencies[index];
            return EmergencyCard(
              emergency: emergency,
              onPressed: isPending
                  ? () => _showAcceptDialog(emergency)
                  : emergency.status == 'ongoing'
                      ? () => _showCompleteDialog(emergency)
                      : null,
              mapOnPressed: () => _showLocationDialog(context, emergency),
            );
          },
        );
      },
    );
  }

  void _showLocationDialog(BuildContext context, Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => MapDialog(emergency: emergency),
    );
  }

  void _showAcceptDialog(Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Accept Emergency?',
        message: "Do you want to accept this emergency?",
        confirmText: 'Accept',
        cancelText: 'Cancel',
        primaryColor: Colors.green,
        onConfirm: () async {
          Navigator.pop(context);
          await _controller.acceptEmergency(emergency.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Accepted emergency from ${emergency.userName}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showCompleteDialog(Emergency emergency) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Mark as Completed?',
        message: "Do you want to mark this as completed?",
        confirmText: 'Complete',
        cancelText: 'Cancel',
        primaryColor: Colors.blue,
        onConfirm: () async {
          Navigator.pop(context);
          await _controller.completeEmergency(emergency.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Completed emergency from ${emergency.userName}'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      await LoginPreferences.clearLoginState();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          message: 'Logout failed: ${e.toString()}',
          isSuccess: false,
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        confirmText: 'Logout',
        cancelText: 'Cancel',
        primaryColor: Colors.red,
        onConfirm: () {
          Navigator.of(context).pop();
          _performLogout();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}