import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = "";
  String _jobTitle = "";
  String? _urlFoto;
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? "";
      _jobTitle = prefs.getString('jobTitle') ?? "";
      _urlFoto = prefs.getString('urlFoto');
      _employeeId = prefs.getInt('idEmployee');
    });
  }

  Future<void> _saveProfileData(
      String name, String jobTitle, String? urlFoto, int? employeeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('jobTitle', jobTitle);
    if (urlFoto != null) {
      await prefs.setString('urlFoto', urlFoto);
    } else {
      await prefs.remove('urlFoto');
    }
    if (employeeId != null) {
      await prefs.setInt('idEmployee', employeeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = _urlFoto != null && _urlFoto!.isNotEmpty
        ? NetworkImage(_urlFoto!)
        : const AssetImage('assets/images/picture.jpg') as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1572E8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: profileImage,
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name.isNotEmpty ? _name : "Nama Tidak Tersedia",
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 120,
                        ),
                        child: Text(
                          _jobTitle.isNotEmpty
                              ? _jobTitle
                              : "Departemen Tidak Tersedia",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              MenuItem(
                icon: 'assets/icons/account.svg',
                title: 'Info Profil',
                onTap: () async {
                  var updatedData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        name: _name,
                        jobTitle: _jobTitle,
                        urlFoto: _urlFoto,
                        employeeId: _employeeId,
                      ),
                    ),
                  );

                  if (updatedData != null) {
                    setState(() {
                      _name = updatedData['name'] ?? _name;
                      _jobTitle = updatedData['jobTitle'] ?? _jobTitle;
                      _urlFoto = updatedData['urlFoto'];
                      _employeeId = updatedData['employeeId'] ?? _employeeId;
                    });
                    await _saveProfileData(
                        _name, _jobTitle, _urlFoto, _employeeId);
                  }
                },
              ),
              MenuItem(
                icon: 'assets/icons/notification.svg',
                title: 'Notifikasi',
                onTap: () {},
              ),
              MenuItem(
                icon: 'assets/icons/setting.svg',
                title: 'Pengaturan',
                onTap: () {},
              ),
              MenuItem(
                icon: 'assets/icons/faq.svg',
                title: 'FAQ',
                onTap: () {},
              ),
              MenuItem(
                icon: 'assets/icons/logout.svg',
                title: 'Logout',
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SvgPicture.asset(
          icon,
          width: 24,
        ),
      ),
      title: Text(title),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
    );
  }
}
