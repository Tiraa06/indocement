import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:indocement_apk/pages/absensi_lapangan_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'absensi_lapangan_page.dart'; // Import halaman AbsensiLapanganScreen

class EventMenuPage extends StatefulWidget {
  const EventMenuPage({super.key});

  @override
  State<EventMenuPage> createState() => _EventMenuPageState();
}

class _EventMenuPageState extends State<EventMenuPage> {
  int? _idEmployee;
  List<Map<String, dynamic>> _eventList = [];
  bool _eventLoading = true;
  bool _eventError = false;
  Map<int, String> _placeNames = {}; // key: index, value: place name

  @override
  void initState() {
    super.initState();
    _loadIdEmployeeAndEvents();
  }

  Future<void> _loadIdEmployeeAndEvents() async {
    setState(() {
      _eventLoading = true;
      _eventError = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('idEmployee');
      if (id != null) {
        _idEmployee = id;
        final events = await fetchEvents(_idEmployee!);
        setState(() {
          _eventList = events;
          _eventLoading = false;
        });
      } else {
        setState(() {
          _eventList = [];
          _eventLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _eventError = true;
        _eventLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchEvents(int idEmployee) async {
    final response = await http.get(
      Uri.parse('http://103.31.235.237:5555/api/Event'),
      headers: {'accept': 'text/plain'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.where((event) {
        final employees = event['Employees'] as List<dynamic>?;
        if (employees == null) return false;
        return employees.contains(idEmployee);
      }).map<Map<String, dynamic>>((event) => {
        'id': event['Id'],
        'nama': event['NamaEvent'],
        'lat': event['Latitude'],
        'long': event['Longitude'],
        'tglMulai': event['TanggalMulai'],
        'tglSelesai': event['TanggalSelesai'],
      }).toList();
    } else {
      throw Exception('Gagal memuat event');
    }
  }

  // Fungsi untuk dapatkan nama tempat dari lat long
  Future<void> _getPlaceName(double lat, double long, int index) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Tampilkan lokasi lengkap: nama, street, locality, subAdministrativeArea, administrativeArea, country
        final name = [
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        setState(() {
          _placeNames[index] = name;
        });
      }
    } catch (e) {
      setState(() {
        _placeNames[index] = "-";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1572E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        title: null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Event yang tersedia',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1572E8),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Expanded(
              child: _eventLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _eventError
                      ? const Center(
                          child: Text('Gagal memuat event',
                              style: TextStyle(color: Colors.red)))
                      : _eventList.isEmpty
                          ? const Center(child: Text('Tidak ada event untuk Anda'))
                          : ListView.builder(
                              itemCount: _eventList.length,
                              itemBuilder: (context, index) {
                                final event = _eventList[index];
                                // Ambil nama tempat jika belum ada
                                if (_placeNames[index] == null &&
                                    event['lat'] != null &&
                                    event['long'] != null) {
                                  _getPlaceName(
                                    double.tryParse(event['lat'].toString()) ?? 0.0,
                                    double.tryParse(event['long'].toString()) ?? 0.0,
                                    index,
                                  );
                                }
                                return Card(
                                  elevation: 10,
                                  margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  color: const Color(0xFFF9FAFB),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD1F2EB),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              padding: const EdgeInsets.all(14),
                                              child: const Icon(Icons.how_to_reg, color: Color(0xFF16A085), size: 38),
                                            ),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event['nama'] ?? '-',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 21,
                                                      color: Color(0xFF1572E8),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Card(
                                          elevation: 0,
                                          color: const Color(0xFFEAF4FC),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.place, size: 18, color: Color(0xFF1572E8)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _placeNames[index] ?? 'Mencari lokasi...',
                                                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                                                        maxLines: 4, // agar lokasi panjang tetap tampil
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month, size: 18, color: Color(0xFFF9A826)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Mulai: ${event['tglMulai']?.substring(0, 10) ?? '-'}',
                                                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month, size: 18, color: Color(0xFFF9A826)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Selesai: ${event['tglSelesai']?.substring(0, 10) ?? '-'}',
                                                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF16A085),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              elevation: 3,
                                            ),
                                            icon: const Icon(Icons.how_to_reg, color: Colors.white),
                                            label: const Text(
                                              'Absen Sekarang',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                            onPressed: () {
                                              double lat = 0.0;
                                              double long = 0.0;
                                              int eventId = event['id'] is int
                                                  ? event['id']
                                                  : int.tryParse(event['id'].toString()) ?? 0;

                                              // Pastikan lat dan long valid, bisa dari double atau string
                                              if (event['lat'] != null) {
                                                if (event['lat'] is double) {
                                                  lat = event['lat'];
                                                } else if (event['lat'] is String) {
                                                  lat = double.tryParse(event['lat']) ?? 0.0;
                                                }
                                              }
                                              if (event['long'] != null) {
                                                if (event['long'] is double) {
                                                  long = event['long'];
                                                } else if (event['long'] is String) {
                                                  long = double.tryParse(event['long']) ?? 0.0;
                                                }
                                              }

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AbsensiLapanganScreen(
                                                    kantorLat: lat,
                                                    kantorLng: long,
                                                    eventId: eventId, // kirim event id ke halaman selanjutnya
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}