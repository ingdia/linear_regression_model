import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// EDIT THIS: must match your FastAPI Pydantic model exactly.
// Removing a feature = deleting one entry. UI, validation and JSON all follow.
// - Android emulator: use http://10.0.2.2:<port>/predict (its alias for host localhost)
// - Chrome/web, Windows desktop, iOS simulator: use http://127.0.0.1:<port>/predict
// Swap to your Render URL (…/predict) once deployed.
// ---------------------------------------------------------------------------
const String kApiUrl = 'http://127.0.0.1:8002/predict';

// Palette — clean light theme, single accent color.
const Color kBg = Color(0xFFFAFAFA);
const Color kSurface = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE5E5E5);
const Color kInk = Color(0xFF1A1A1A);
const Color kInkMuted = Color(0xFF6B6B6B);
const Color kAccent = Color(0xFF2563EB);
const Color kAccentSoft = Color(0xFFEFF4FF);
const Color kErrorBg = Color(0xFFFEF2F2);
const Color kErrorBorder = Color(0xFFFCA5A5);
const Color kErrorInk = Color(0xFFB91C1C);

enum FieldKind { choice, number }

class FieldSpec {
  final String key;
  final String label;
  final FieldKind kind;
  final List<String> options;
  final double min;
  final double max;
  final String hint;

  const FieldSpec.choice(this.key, this.label, this.options)
      : kind = FieldKind.choice,
        min = 0,
        max = 0,
        hint = '';

  const FieldSpec.number(this.key, this.label,
      {required this.min, required this.max, this.hint = ''})
      : kind = FieldKind.number,
        options = const [];
}

const List<FieldSpec> kFields = [
  FieldSpec.choice('Region', 'Region', [
    'Urban',
    'Rural',
  ]),
  FieldSpec.choice('Day_of_Week', 'Day of week', [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ]),
  FieldSpec.choice('Season', 'Season', [
    'Spring',
    'Summer',
    'Fall',
    'Winter',
  ]),
  FieldSpec.choice('Time_of_Day', 'Time of day', [
    'Early Morning',
    'Late Morning',
    'Afternoon',
    'Evening',
    'Night',
  ]),
  FieldSpec.choice('Urgency_Level', 'Urgency level', [
    'Critical',
    'High',
    'Medium',
    'Low',
  ]),
  FieldSpec.choice('Patient_Outcome', 'Patient outcome', [
    'Admitted',
    'Discharged',
    'Left Without Being Seen',
  ]),
  FieldSpec.number('Nurse_to_Patient_Ratio', 'Nurse-to-patient ratio',
      min: 0.1, max: 10.0, hint: '0.1 - 10.0'),
  FieldSpec.number('Specialist_Availability', 'Specialist availability',
      min: 0, max: 20, hint: '0 - 20 on duty'),
  FieldSpec.number('Facility_Size_Beds', 'Facility size (beds)',
      min: 10, max: 1000, hint: '10 - 1000'),
  FieldSpec.number('Patient_Satisfaction', 'Patient satisfaction',
      min: 0, max: 5, hint: '0 - 5'),
];

// Urgency reads as accent intensity on the side stripe.
const Map<String, Color> kUrgencyColor = {
  'Critical': Color(0xFFDC2626),
  'High': Color(0xFFF59E0B),
  'Medium': Color(0xFFEAB308),
  'Low': Color(0xFF16A34A),
};

void main() => runApp(const ErApp());

class ErApp extends StatelessWidget {
  const ErApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ER Wait Time Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const PredictPage(),
    );
  }
}

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final Map<String, String?> _choices = {};
  final Map<String, TextEditingController> _numbers = {};

  bool _loading = false;
  String? _error;
  double? _result;

  @override
  void initState() {
    super.initState();
    for (final f in kFields) {
      if (f.kind == FieldKind.number) {
        _numbers[f.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _numbers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color get _stripeColor =>
      kUrgencyColor[_choices['Urgency_Level']] ?? kBorder;

  String? _validate(Map<String, dynamic> payload) {
    for (final f in kFields) {
      if (f.kind == FieldKind.choice) {
        if (_choices[f.key] == null) return 'Choose a value for ${f.label}.';
        payload[f.key] = _choices[f.key];
      } else {
        final raw = _numbers[f.key]!.text.trim();
        if (raw.isEmpty) return 'Enter a value for ${f.label}.';
        final v = double.tryParse(raw);
        if (v == null) return '${f.label} must be a number.';
        if (v < f.min || v > f.max) {
          return '${f.label} must be between ${f.min} and ${f.max}.';
        }
        payload[f.key] = v;
      }
    }
    return null;
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();
    final payload = <String, dynamic>{};
    final problem = _validate(payload);
    if (problem != null) {
      setState(() {
        _error = problem;
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await http
          .post(
            Uri.parse(kApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final value = body['prediction_minutes'];
        if (value == null) {
          setState(() => _error = 'The API replied without a prediction field.');
        } else {
          setState(() => _result = (value as num).toDouble());
        }
      } else if (res.statusCode == 422) {
        final detail = jsonDecode(res.body)['detail'];
        setState(() => _error = 'The API rejected these values: $detail');
      } else {
        setState(() => _error = 'Server returned ${res.statusCode}.');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach the API. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  _formCard(),
                  const SizedBox(height: 20),
                  _predictButton(),
                  const SizedBox(height: 20),
                  _resultCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ER Wait Time Predictor',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: kInk,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter visit details to estimate total wait in minutes.',
          style: TextStyle(
            fontSize: 14,
            color: kInkMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _formCard() {
    return _card(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: 4,
              decoration: BoxDecoration(
                color: _stripeColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final f in kFields) ...[
                      f.kind == FieldKind.choice
                          ? _dropdown(f)
                          : _numberField(f),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: kInkMuted, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
      floatingLabelStyle: const TextStyle(color: kAccent, fontSize: 14),
      filled: true,
      fillColor: kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAccent, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
    );
  }

  Widget _dropdown(FieldSpec f) {
    return DropdownButtonFormField<String>(
      initialValue: _choices[f.key],
      isExpanded: true,
      dropdownColor: kSurface,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.expand_more, color: kInkMuted),
      style: const TextStyle(color: kInk, fontSize: 15),
      decoration: _decoration(f.label),
      items: f.options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) => setState(() => _choices[f.key] = v),
    );
  }

  Widget _numberField(FieldSpec f) {
    return TextField(
      controller: _numbers[f.key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: kInk, fontSize: 15),
      cursorColor: kAccent,
      decoration: _decoration(f.label, hint: f.hint),
    );
  }

  Widget _predictButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _predict,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kAccent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Colors.white),
              )
            : const Text(
                'Predict wait time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _resultCard() {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kErrorBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kErrorBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: kErrorInk, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: kErrorInk,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_result != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kAccentSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAccent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estimated total wait',
              style: TextStyle(
                fontSize: 13,
                color: kInkMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _result!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: kAccent,
                    height: 1.0,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'minutes',
                  style: TextStyle(fontSize: 16, color: kInkMuted),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _card(
      child: const Text(
        'Your prediction will appear here.',
        style: TextStyle(fontSize: 14, color: kInkMuted),
      ),
    );
  }
}
