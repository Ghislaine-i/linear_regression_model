import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Public API deployed on Render.
const String apiUrl =
    'https://linear-regression-model-ikuw.onrender.com/predict';

void main() => runApp(const SalaryApp());

class SalaryApp extends StatelessWidget {
  const SalaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Developer Salary Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PredictPage(),
    );
  }
}

/// One model input: the JSON key sent to the API, the label shown to the
/// user, a hint with the allowed values, and whether it is a number.
class InputSpec {
  final String key;
  final String label;
  final String hint;
  final bool isNumber;
  const InputSpec(this.key, this.label, this.hint, {this.isNumber = false});
}

const List<InputSpec> inputs = [
  InputSpec(
    'WorkExp',
    'Years of work experience',
    'Number from 0 to 15',
    isNumber: true,
  ),
  InputSpec(
    'YearsCode',
    'Years of coding',
    'Number from 0 to 40',
    isNumber: true,
  ),
  InputSpec(
    'Country',
    'Country',
    'Brazil, Canada, France, Germany, India, Italy, Netherlands, Poland, Spain, UK, USA, Ukraine',
  ),
  InputSpec(
    'EdLevel',
    'Education level',
    'Primary, Secondary, Some college, Associate, Bachelor, Master, Professional, Other',
  ),
  InputSpec(
    'OrgSize',
    'Company size',
    'Just me, Under 20, 20-99, 100-499, 500-999, 1000-4999, 5000-9999, 10000+, Unknown',
  ),
  InputSpec(
    'WorkArrangement',
    'Work arrangement',
    'Remote, Hybrid, In-person, Flexible',
  ),
  InputSpec(
    'DevType',
    'Developer role',
    'Architect, Back-end, Desktop/Enterprise, DevOps, Embedded, Front-end, Full-stack, Mobile, Other',
  ),
  InputSpec('ICorPM', 'Individual contributor or manager', 'IC or Manager'),
];

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final Map<String, TextEditingController> _controllers = {
    for (final spec in inputs) spec.key: TextEditingController(),
  };
  final GlobalKey _resultKey = GlobalKey();

  bool _loading = false;
  String? _result; // shown when the prediction succeeds
  String? _error; // shown when something is wrong

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _labelFor(String key) => inputs
      .firstWhere((s) => s.key == key, orElse: () => InputSpec(key, key, ''))
      .label;

  String _formatUsd(num value) {
    final digits = value.round().toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  /// Turns the API's validation errors (HTTP 422) into readable sentences.
  String _describeApiError(dynamic detail) {
    final lines = <String>[];
    if (detail is List) {
      for (final item in detail) {
        if (item is! Map) continue;
        final loc = item['loc'];
        final key = (loc is List && loc.isNotEmpty)
            ? loc.last.toString()
            : 'Input';
        final label = _labelFor(key);
        final ctx = item['ctx'] is Map ? item['ctx'] as Map : const {};
        switch (item['type']) {
          case 'missing':
            lines.add('$label is required.');
            break;
          case 'less_than_equal':
            lines.add('$label must be at most ${ctx['le']}.');
            break;
          case 'greater_than_equal':
            lines.add('$label must be at least ${ctx['ge']}.');
            break;
          case 'literal_error':
            final allowed = (ctx['expected'] ?? '').toString().replaceAll(
              "'",
              '',
            );
            lines.add('$label must be one of: $allowed.');
            break;
          case 'float_parsing':
          case 'float_type':
            lines.add('$label must be a number.');
            break;
          default:
            lines.add('$label: ${item['msg']}');
        }
      }
    }
    return lines.isNotEmpty
        ? lines.join('\n')
        : 'The server rejected the input.';
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    // 1. Missing values are caught before calling the API
    final body = <String, dynamic>{};
    final missing = <String>[];
    for (final spec in inputs) {
      final text = _controllers[spec.key]!.text.trim();
      if (text.isEmpty) {
        missing.add(spec.label);
        continue;
      }
      // Numbers are sent as numbersthe API itself reports the wrong data type.
      body[spec.key] = spec.isNumber ? (double.tryParse(text) ?? text) : text;
    }
    if (missing.isNotEmpty) {
      _show(error: 'Please fill in: ${missing.join(', ')}.');
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 75));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final usd = data['predicted_salary_usd'] as num;
        final k = data['predicted_salary_k'] as num;
        _show(
          result:
              'Estimated annual salary:\n\$${_formatUsd(usd)}  (about \$${k.toStringAsFixed(1)}k)',
        );
      } else if (response.statusCode == 422) {
        _show(error: _describeApiError(data['detail']));
      } else {
        _show(
          error:
              'The server returned an error (code ${response.statusCode}). Please try again.',
        );
      }
    } on TimeoutException {
      _show(
        error: 'The server took too long to answer. It may be waking up, so please try again in a moment.',
      );
    } catch (_) {
      _show(
        error: 'Could not reach the server. Check your internet connection and try again.',
      );
    }
  }

  void _show({String? result, String? error}) {
    setState(() {
      _loading = false;
      _result = result;
      _error = error;
    });
    // Scroll so the display area is visible after the keyboard closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  Widget _field(InputSpec spec) {
    return TextField(
      controller: _controllers[spec.key],
      keyboardType: spec.isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: spec.label,
        helperText: spec.hint,
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _display(ColorScheme scheme) {
    final isError = _error != null;
    final hasContent = _loading || isError || _result != null;
    final Color background = isError
        ? scheme.errorContainer
        : scheme.primaryContainer;
    final Color foreground = isError
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;

    Widget child;
    if (_loading) {
      child = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Contacting the server... the first request can take up to a minute.',
            ),
          ),
        ],
      );
    } else if (hasContent) {
      child = Text(
        isError ? _error! : _result!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foreground,
          fontSize: isError ? 15 : 20,
          fontWeight: isError ? FontWeight.normal : FontWeight.bold,
        ),
      );
    } else {
      child = Text(
        'Your estimate will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    return Container(
      key: _resultKey,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasContent && !_loading
            ? background
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Salary Estimator')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the details below to estimate the annual salary of an early-career developer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final spec in inputs) ...[
                _field(spec),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _predict,
                  child: const Text('Predict'),
                ),
              ),
              const SizedBox(height: 16),
              _display(scheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
