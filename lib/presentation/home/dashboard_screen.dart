import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/enrollment_provider.dart';
import '../auth/details_profile_screen.dart';
import 'subjects_screen.dart';
import 'progress_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<EnrollmentProvider>(context, listen: false).fetchDashboardData(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, EnrollmentProvider>(
      builder: (context, authProvider, enrollmentProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Dashboard',
              style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          ),
          drawer: _buildDrawer(context, authProvider),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: user?.student?.photoUrl != null
                              ? NetworkImage(user!.student!.photoUrl!)
                              : null,
                          child: user?.student?.photoUrl == null
                              ? const Icon(Icons.person, size: 32, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat Datang,',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              Text(
                                user?.name ?? 'Siswa',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Statistics Section
                  const Text(
                    'Ringkasan Belajar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        label: 'Mapel',
                        value: '${enrollmentProvider.totalSubjects}',
                        icon: Icons.book_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        label: 'Selesai',
                        value: '${enrollmentProvider.totalCompletedMaterials}',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        label: 'Progres',
                        value: '${enrollmentProvider.averageProgress.toStringAsFixed(0)}%',
                        icon: Icons.bar_chart_rounded,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  // Main Menu
                  const Text(
                    'Menu Utama',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          Icons.auto_stories_rounded, 
                          'Mata Pelajaran', 
                          Colors.indigo, 
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SubjectsScreen()),
                            );
                          }
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMenuCard(
                          Icons.insights_rounded, 
                          'Progres Belajar', 
                          Colors.teal, 
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProgressScreen()),
                            );
                          }
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Activities (Improvisasi)
                  if (enrollmentProvider.recentActivities.isNotEmpty) ...[
                    const Text(
                      'Terakhir Dipelajari',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    ...enrollmentProvider.recentActivities.take(3).map((activity) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.materialTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  activity.subjectTitle,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(activity.lastAccessed),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, {required String label, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.only(topRight: Radius.circular(32)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.student?.photoUrl != null
                  ? NetworkImage(user!.student!.photoUrl!)
                  : null,
              child: user?.student?.photoUrl == null
                  ? const Icon(Icons.person, color: Color(0xFF2563EB), size: 40)
                  : null,
            ),
            accountName: Text(
              user?.name ?? 'Siswa',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(user?.email ?? '-'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Mata Pelajaran Saya'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubjectsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: const Text('Progres Belajar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProgressScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Profil Saya'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DetailsProfileScreen()),
              );
            },
          ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              authProvider.logout();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
