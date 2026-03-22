import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const READitApp());
}

class READitApp extends StatelessWidget {
  const READitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'READit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const PredictionPage(),
    );
  }
}

// ── Input field ───────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final String range;
  final IconData icon;
  final TextEditingController controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.range,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0097A7), size: 13),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF006064),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00BCD4).withOpacity(0.4),
                ),
              ),
              child: Text(
                range,
                style: const TextStyle(
                  color: Color(0xFF006064),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Color(0xFF006064),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF006064).withOpacity(0.35),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.6),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFF00BCD4), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Prediction page ───────────────────────────────────────────
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage>
    with SingleTickerProviderStateMixin {
  final _studyHoursController  = TextEditingController();
  final _attendanceController  = TextEditingController();
  final _resourcesController   = TextEditingController();
  final _motivationController  = TextEditingController();
  final _internetController    = TextEditingController();
  final _discussionsController = TextEditingController();
  final _assignmentController  = TextEditingController();
  final _eduTechController     = TextEditingController();

  String _result = '';
  double? _score;
  bool _isLoading = false;
  bool _hasError = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final String _apiUrl = 'https://readit-api.onrender.com/predict';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _studyHoursController.dispose();
    _attendanceController.dispose();
    _resourcesController.dispose();
    _motivationController.dispose();
    _internetController.dispose();
    _discussionsController.dispose();
    _assignmentController.dispose();
    _eduTechController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _score = null;
      _hasError = false;
    });
    _animController.reset();

    final controllers = [
      _studyHoursController, _attendanceController,
      _resourcesController,  _motivationController,
      _internetController,   _discussionsController,
      _assignmentController, _eduTechController,
    ];

    for (var c in controllers) {
      if (c.text.isEmpty) {
        setState(() {
          _result = 'Please fill in all fields before predicting.';
          _hasError = true;
          _isLoading = false;
        });
        _animController.forward();
        return;
      }
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'StudyHours':           int.parse(_studyHoursController.text),
          'Attendance':           int.parse(_attendanceController.text),
          'Resources':            int.parse(_resourcesController.text),
          'Motivation':           int.parse(_motivationController.text),
          'Internet':             int.parse(_internetController.text),
          'Discussions':          int.parse(_discussionsController.text),
          'AssignmentCompletion': int.parse(_assignmentController.text),
          'EduTech':              int.parse(_eduTechController.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final score = (data['predicted_exam_score'] as num).toDouble();
        setState(() {
          _score = score;
          _result = data['message'];
          _hasError = false;
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _result = error['detail']?.toString() ??
              'Invalid input. Check that values are within range.';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _result =
            'Could not connect to the API.\nPlease check your internet connection.';
        _hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF00897B);
    if (score >= 60) return const Color(0xFFF57F17);
    return const Color(0xFFE53935);
  }

  String _scoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Average';
    return 'Needs Support';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4DD0E1),
              Color(0xFF26C6DA),
              Color(0xFF00BCD4),
              Color(0xFF0097A7),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF006064),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'READit',
                            style: TextStyle(
                              color: Color(0xFF006064),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Exam Score Predictor',
                            style: TextStyle(
                              color: const Color(0xFF006064)
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Glassmorphism input card ───────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Details',
                        style: TextStyle(
                          color: Color(0xFF006064),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in all fields to generate a prediction.',
                        style: TextStyle(
                          color: const Color(0xFF006064)
                              .withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _InputField(
                        label: 'STUDY HOURS',
                        hint: 'e.g. 10',
                        range: '0 – 24',
                        icon: Icons.menu_book_rounded,
                        controller: _studyHoursController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'ATTENDANCE',
                        hint: 'e.g. 85',
                        range: '0 – 100%',
                        icon: Icons.calendar_today_rounded,
                        controller: _attendanceController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'RESOURCES ACCESS',
                        hint: '0 = No  /  1 = Yes',
                        range: '0 or 1',
                        icon: Icons.library_books_rounded,
                        controller: _resourcesController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'MOTIVATION',
                        hint: '0 = No  /  1 = Yes',
                        range: '0 or 1',
                        icon: Icons.bolt_rounded,
                        controller: _motivationController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'INTERNET ACCESS',
                        hint: '0 = No  /  1 = Yes',
                        range: '0 or 1',
                        icon: Icons.wifi_rounded,
                        controller: _internetController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'CLASS DISCUSSIONS',
                        hint: 'e.g. 7',
                        range: '0 – 10',
                        icon: Icons.forum_rounded,
                        controller: _discussionsController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'ASSIGNMENT COMPLETION',
                        hint: 'e.g. 90',
                        range: '0 – 100%',
                        icon: Icons.task_alt_rounded,
                        controller: _assignmentController,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'EDUTECH USAGE',
                        hint: '0 = No  /  1 = Yes',
                        range: '0 or 1',
                        icon: Icons.devices_rounded,
                        controller: _eduTechController,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Predict button ─────────────────────────
                GestureDetector(
                  onTap: _isLoading ? null : _predict,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Colors.white.withOpacity(0.3)
                          : const Color(0xFF006064),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF006064)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_graph_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Predict',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                // ── Result card ────────────────────────────
                if (_result.isNotEmpty)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _hasError
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.25),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE53935)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFE53935),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _result,
                                        style: const TextStyle(
                                          color: Color(0xFFE53935),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.3),
                                  borderRadius:
                                      BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white
                                          .withOpacity(0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Predicted Score',
                                      style: TextStyle(
                                        color: const Color(0xFF006064)
                                            .withOpacity(0.7),
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_score?.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: _scoreColor(
                                            _score ?? 0),
                                        fontSize: 72,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      '/ 100',
                                      style: TextStyle(
                                        color: const Color(0xFF006064)
                                            .withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _scoreColor(
                                                _score ?? 0)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _scoreColor(
                                                  _score ?? 0)
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        _scoreLabel(_score ?? 0),
                                        style: TextStyle(
                                          color: _scoreColor(
                                              _score ?? 0),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (_score ?? 0) / 100,
                                        minHeight: 8,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.3),
                                        valueColor:
                                            AlwaysStoppedAnimation(
                                          _scoreColor(_score ?? 0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}