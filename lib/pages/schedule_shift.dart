import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:indocement_apk/pages/bpjs_page.dart';
import 'package:indocement_apk/pages/hr_menu.dart';
import 'package:indocement_apk/pages/id_card.dart';
import 'package:indocement_apk/pages/layanan_menu.dart';
import 'package:indocement_apk/pages/skkmedic_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:indocement_apk/utils/network_helper.dart';

class ScheduleShiftPage extends StatefulWidget {
  const ScheduleShiftPage({super.key});

  @override
  State<ScheduleShiftPage> createState() => _ScheduleShiftPageState();
}

class _ScheduleShiftPageState extends State<ScheduleShiftPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Form controllers and state
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _employees = [];
  final List<Map<String, dynamic>> _selectedPairs = [];
  DateTime? _selectedDate;
  final _keteranganController = TextEditingController();
  bool _isLoading = false;
  String? _userSection;
  int? _userIdEmployee;

  // Shift options
  final List<String> _shiftOptions = [
    'Shift A',
    'Shift B',
    'Shift C',
    'Shift D'
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadEmployeeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  Future<void> _loadEmployeeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? idEmployee = prefs.getInt('idEmployee');
      if (idEmployee == null) {
        throw Exception('ID pengguna tidak ditemukan. Silakan login ulang.');
      }
      _userIdEmployee = idEmployee;

      final employeeResponse = await safeRequest(
        context,
        () => http.get(
          Uri.parse('http://103.31.235.237:5555/api/Employees/$idEmployee'),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (employeeResponse == null) return; // Sudah redirect ke error

      print('Fetch User Employee Status: ${employeeResponse.statusCode}');
      print('Fetch User Employee Body: ${employeeResponse.body}');

      if (employeeResponse.statusCode != 200) {
        throw Exception('Gagal memuat data pengguna: ${employeeResponse.body}');
      }
      final employeeData = json.decode(employeeResponse.body);
      _userSection = employeeData['IdSection']?.toString();
      print(
          'User ID: $idEmployee, IdSection: $_userSection, User Data: $employeeData');

      if (_userSection == null || _userSection!.isEmpty) {
        throw Exception('IdSection pengguna tidak ditemukan dalam data.');
      }

      final response = await safeRequest(
        context,
        () => http.get(
          Uri.parse('http://103.31.235.237:5555/api/Employees'),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (response == null) return; // Sudah redirect ke error

      print('Fetch All Employees Status: ${response.statusCode}');
      print('Fetch All Employees Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Raw Employee Data: $data');
        final Map<int, Map<String, dynamic>> uniqueEmployees = {};
        for (var e in data) {
          final idEsl = e['IdEsl'] ?? e['idEsl'] ?? e['IDESL'];
          print(
              'Employee: Id=${e['Id']}, Name=${e['EmployeeName']}, IdSection=${e['IdSection']}, IdEsl=$idEsl');
          if (e['IdSection']?.toString() == _userSection && idEsl == 6) {
            final int id = e['Id'];
            if (!uniqueEmployees.containsKey(id)) {
              uniqueEmployees[id] = {
                'IdEmployee': id,
                'EmployeeName': e['EmployeeName'] ?? 'Unknown',
                'IdSection': e['IdSection']?.toString() ?? '',
              };
              print('Included Employee: Id=$id, Name=${e['EmployeeName']}');
            } else {
              print('Skipped Duplicate Employee: Id=$id');
            }
          } else {
            print(
                'Excluded Employee: Id=${e['Id']}, Reason: IdSection=${e['IdSection']} != $_userSection or IdEsl=$idEsl != 6');
          }
        }
        setState(() {
          _employees = uniqueEmployees.values.toList();
          print(
              'Filtered Employees (IdSection=$_userSection, IdEsl=6): $_employees');
          if (_employees.any((e) => e['IdEmployee'] == idEmployee)) {
            _selectedPairs.add({
              'IdEmployee': idEmployee,
              'EmployeeName': 'Anda',
              'DariShift': null,
              'KeShift': null,
            });
            print(
                'Added current user to selectedPairs: IdEmployee=$idEmployee');
          } else {
            print(
                'Warning: Current user (IdEmployee=$idEmployee) not found in filtered employees');
          }
        });

        final idSet = _employees.map((e) => e['IdEmployee']).toSet();
        if (idSet.length != _employees.length) {
          print('Warning: Duplicate IdEmployee found in _employees');
        }
      } else {
        throw Exception('Gagal memuat data karyawan: ${response.body}');
      }
    } catch (e) {
      print('Error loading employee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPairs.length > 4 || _selectedPairs.length % 2 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Jumlah karyawan harus genap (2 atau 4) untuk tukar shift')),
      );
      return;
    }

    for (var pair in _selectedPairs) {
      if (pair['DariShift'] == null || pair['KeShift'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua shift harus diisi')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = _selectedPairs
          .map((pair) => {
                'IdEmployee': pair['IdEmployee'],
                'TglShift': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                'DariShift': pair['DariShift'],
                'KeShift': pair['KeShift'],
                'Keterangan': _keteranganController.text,
              })
          .toList();

      print('Submitting request: $requestBody');

      final response = await http
          .post(
            Uri.parse(
                'http://103.31.235.237:5555/api/TukarSchedule/generate-document'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': '*/*',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Sukses'),
            content: const Text('Pengajuan tukar shift berhasil dikirim.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LayananMenuPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Gagal mengirim pengajuan: ${response.body}');
      }
    } catch (e) {
      print('Error submitting form: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Error'),
          content: Text('Terjadi kesalahan: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final double paddingValue = screenWidth * 0.04;
        final double baseFontSize = screenWidth * 0.04;

        final availableEmployees = _employees
            .where((e) =>
                e['IdEmployee'] != null &&
                !_selectedPairs
                    .any((pair) => pair['IdEmployee'] == e['IdEmployee']))
            .toList();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LayananMenuPage()),
                );
              },
            ),
            title: Text(
              "Tukar Schedule Shift",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.25,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1572E8),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _toggleMenu,
              ),
            ],
          ),
          body: Stack(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: EdgeInsets.all(paddingValue),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: paddingValue),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "Form untuk mengajukan tukar schedule shift. Pilih karyawan dari seksi yang sama (maksimal 2 pasangan).",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: baseFontSize * 0.9,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: paddingValue * 0.5),
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: Padding(
                                      padding: EdgeInsets.all(paddingValue),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Pilih Karyawan (Maks. 2 Pasangan)",
                                            style: GoogleFonts.poppins(
                                              fontSize: baseFontSize * 0.9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: availableEmployees.isEmpty
                                                ? Text(
                                                    "Tidak ada karyawan yang tersedia. Pastikan ada karyawan di seksi $_userSection dengan IdEsl=6.",
                                                    style: const TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 14),
                                                  )
                                                : DropdownButton<int>(
                                                    isExpanded: true,
                                                    hint: const Text(
                                                        "Pilih karyawan"),
                                                    value: null,
                                                    items: availableEmployees
                                                        .map((employee) {
                                                      return DropdownMenuItem<
                                                          int>(
                                                        value: employee[
                                                                'IdEmployee']
                                                            as int,
                                                        child: Text(employee[
                                                            'EmployeeName']),
                                                      );
                                                    }).toList(),
                                                    onChanged: (int? value) {
                                                      if (value != null) {
                                                        if (_selectedPairs
                                                                .length <
                                                            4) {
                                                          final employee =
                                                              _employees
                                                                  .firstWhere(
                                                            (e) =>
                                                                e['IdEmployee'] ==
                                                                value,
                                                            orElse: () => {
                                                              'IdEmployee':
                                                                  value,
                                                              'EmployeeName':
                                                                  'Unknown',
                                                              'IdSection':
                                                                  _userSection ??
                                                                      '',
                                                            },
                                                          );
                                                          setState(() {
                                                            _selectedPairs.add({
                                                              'IdEmployee':
                                                                  value,
                                                              'EmployeeName':
                                                                  employee[
                                                                      'EmployeeName'],
                                                              'DariShift': null,
                                                              'KeShift': null,
                                                            });
                                                          });
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Maksimal 2 pasangan (4 karyawan)')),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    underline: const SizedBox(),
                                                  ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...List.generate(
                                              (_selectedPairs.length / 2)
                                                  .ceil(), (index) {
                                            final pairIndex = index * 2;
                                            final employee1 = pairIndex <
                                                    _selectedPairs.length
                                                ? _selectedPairs[pairIndex]
                                                : null;
                                            final employee2 = pairIndex + 1 <
                                                    _selectedPairs.length
                                                ? _selectedPairs[pairIndex + 1]
                                                : null;
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Pasangan ${index + 1}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize:
                                                            baseFontSize * 0.9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (employee1 != null) ...[
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              employee1[
                                                                  'EmployeeName'],
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red),
                                                            onPressed: employee1[
                                                                        'IdEmployee'] ==
                                                                    _userIdEmployee
                                                                ? null
                                                                : () {
                                                                    setState(
                                                                        () {
                                                                      _selectedPairs
                                                                          .removeAt(
                                                                              pairIndex);
                                                                      if (employee2 !=
                                                                          null) {
                                                                        _selectedPairs
                                                                            .removeAt(pairIndex);
                                                                      }
                                                                    });
                                                                  },
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                DropdownButton<
                                                                    String>(
                                                              isExpanded: true,
                                                              hint: const Text(
                                                                  "Dari Shift"),
                                                              value: employee1[
                                                                  'DariShift'],
                                                              items: _shiftOptions
                                                                  .map((shift) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: shift,
                                                                  child: Text(
                                                                      shift),
                                                                );
                                                              }).toList(),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  employee1[
                                                                          'DariShift'] =
                                                                      value;
                                                                  if (employee2 !=
                                                                          null &&
                                                                      value !=
                                                                          null) {
                                                                    employee2[
                                                                            'KeShift'] =
                                                                        value;
                                                                    if (employee2[
                                                                            'DariShift'] ==
                                                                        value) {
                                                                      employee2[
                                                                              'DariShift'] =
                                                                          employee1[
                                                                              'KeShift'];
                                                                    }
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                DropdownButton<
                                                                    String>(
                                                              isExpanded: true,
                                                              hint: const Text(
                                                                  "Ke Shift"),
                                                              value: employee1[
                                                                  'KeShift'],
                                                              items: _shiftOptions
                                                                  .map((shift) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: shift,
                                                                  child: Text(
                                                                      shift),
                                                                );
                                                              }).toList(),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  employee1[
                                                                          'KeShift'] =
                                                                      value;
                                                                  if (employee2 !=
                                                                          null &&
                                                                      value !=
                                                                          null) {
                                                                    employee2[
                                                                            'DariShift'] =
                                                                        value;
                                                                    if (employee2[
                                                                            'KeShift'] ==
                                                                        value) {
                                                                      employee2[
                                                                              'KeShift'] =
                                                                          employee1[
                                                                              'DariShift'];
                                                                    }
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                    if (employee2 != null) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              employee2[
                                                                  'EmployeeName'],
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red),
                                                            onPressed: employee2[
                                                                        'IdEmployee'] ==
                                                                    _userIdEmployee
                                                                ? null
                                                                : () {
                                                                    setState(
                                                                        () {
                                                                      _selectedPairs.removeAt(
                                                                          pairIndex +
                                                                              1);
                                                                    });
                                                                  },
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                DropdownButton<
                                                                    String>(
                                                              isExpanded: true,
                                                              hint: const Text(
                                                                  "Dari Shift"),
                                                              value: employee2[
                                                                  'DariShift'],
                                                              items: _shiftOptions
                                                                  .map((shift) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: shift,
                                                                  child: Text(
                                                                      shift),
                                                                );
                                                              }).toList(),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  employee2[
                                                                          'DariShift'] =
                                                                      value;
                                                                  if (value !=
                                                                      null) {
                                                                    employee1?[
                                                                            'KeShift'] =
                                                                        value;
                                                                    if (employee1?[
                                                                            'DariShift'] ==
                                                                        value) {
                                                                      employee1?[
                                                                              'DariShift'] =
                                                                          employee2[
                                                                              'KeShift'];
                                                                    }
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                DropdownButton<
                                                                    String>(
                                                              isExpanded: true,
                                                              hint: const Text(
                                                                  "Ke Shift"),
                                                              value: employee2[
                                                                  'KeShift'],
                                                              items: _shiftOptions
                                                                  .map((shift) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: shift,
                                                                  child: Text(
                                                                      shift),
                                                                );
                                                              }).toList(),
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  employee2[
                                                                          'KeShift'] =
                                                                      value;
                                                                  if (value !=
                                                                      null) {
                                                                    employee1?[
                                                                            'DariShift'] =
                                                                        value;
                                                                    if (employee1?[
                                                                            'KeShift'] ==
                                                                        value) {
                                                                      employee1?[
                                                                              'KeShift'] =
                                                                          employee2[
                                                                              'DariShift'];
                                                                    }
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Tanggal Shift",
                                            style: GoogleFonts.poppins(
                                              fontSize: baseFontSize * 0.9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () => _selectDate(context),
                                            child: InputDecorator(
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                              child: Text(
                                                _selectedDate == null
                                                    ? 'Pilih tanggal'
                                                    : DateFormat('dd/MM/yyyy')
                                                        .format(_selectedDate!),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Keterangan",
                                            style: GoogleFonts.poppins(
                                              fontSize: baseFontSize * 0.9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _keteranganController,
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Masukkan alasan tukar shift',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Masukkan keterangan';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _submitForm,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1572E8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                              child: _isLoading
                                                  ? const CircularProgressIndicator(
                                                      color: Colors.white)
                                                  : Text(
                                                      'Kirim Pengajuan',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            baseFontSize * 0.9,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final ScrollController scrollController =
                            ScrollController();
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.all(16.0),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.95,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Scrollbar(
                              controller: scrollController,
                              thumbVisibility: false,
                              thickness: 3,
                              radius: const Radius.circular(10),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Frequently Asked Questions (FAQ)',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1572E8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFAQItem(
                                      icon: Icons.schedule,
                                      question: 'Apa itu menu Schedule Shift?',
                                      answer:
                                          'Menu Schedule Shift berfungsi untuk melihat jadwal kerja atau shift Anda setiap harinya. Fitur ini sudah aktif dan dapat digunakan.',
                                    ),
                                    _buildFAQItem(
                                      icon: Icons.swap_horiz,
                                      question:
                                          'Bagaimana cara mengajukan Tukar Schedule?',
                                      answer:
                                          'Pada halaman Tukar Schedule, disediakan form yang harus Anda isi. Anda perlu memilih karyawan lain yang ingin diajak bertukar shift, lalu tentukan tanggal penukaran shift dan cantumkan keterangan alasan penukaran dengan jelas.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  'Tutup',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  label: const Text(
                    "FAQ",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                ),
              ),
              SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Menu",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        _buildMenuItem(
                          icon: Icons.health_and_safety,
                          title: "BPJS",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const BPJSPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.badge,
                          title: "ID & Slip Salary",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const IdCardUploadPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.description,
                          title: "SK Kerja & Medical",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SKKMedicPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.headset_mic,
                          title: "HR Care",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HRCareMenuPage()),
                            );
                          },
                        ),
                        SizedBox(height: paddingValue * 0.5),
                        _buildMenuItem(
                          icon: Icons.support_agent,
                          title: "Layanan Karyawan",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LayananMenuPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem({
    required IconData icon,
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1572E8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
