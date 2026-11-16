import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ====== EDIT THESE BEFORE SUBMITTING ======
const String kAuthorName = 'Ahmad Hulaif Hilmi bin Insidin';
const String kMatricNo = '2024249606';
const String kCourse = 'Degree in Netcentric';
const String kGithubUrl = 'https://github.com/Hulaif/excess-baggage-calculator';
// ==========================================

const String kAppTitle = 'Excess Baggage Fee Estimator';
const double kServiceTaxRate = 0.08;

void main() => runApp(const BaggageApp());

class BaggageApp extends StatelessWidget {
  const BaggageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// Navigation drawer shared by both pages.
class AppDrawer extends StatelessWidget {
  final String current;
  const AppDrawer({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  Icon(Icons.luggage, color: Colors.white, size: 40),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kAppTitle,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: current == 'Home',
            onTap: () {
              Navigator.pop(context);
              if (current != 'Home') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomePage()));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            selected: current == 'About',
            onTap: () {
              Navigator.pop(context);
              if (current != 'About') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AboutPage()));
              }
            },
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  String _ticketClass = 'Economy'; // input in a non-textfield widget
  double? _excessWeight;
  double? _excessCharge;
  double? _totalPayable;

  int get _allowance => _ticketClass == 'Economy' ? 20 : 40;

  String? _validateNumber(String? v, String label) {
    if (v == null || v.trim().isEmpty) return 'Please enter $label';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n < 0) return '$label cannot be negative';
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _excessWeight = _excessCharge = _totalPayable = null;
      });
      return;
    }
    final weight = double.parse(_weightCtrl.text.trim());
    final rate = double.parse(_rateCtrl.text.trim());

    final diff = weight - _allowance;
    final excess = diff > 0 ? diff : 0.0; // never negative
    final charge = excess * rate;
    final total = charge + (charge * kServiceTaxRate);

    setState(() {
      _excessWeight = excess;
      _excessCharge = charge;
      _totalPayable = total;
    });
  }

  void _reset() {
    _formKey.currentState?.reset();
    _weightCtrl.clear();
    _rateCtrl.clear();
    setState(() {
      _ticketClass = 'Economy';
      _excessWeight = _excessCharge = _totalPayable = null;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppTitle),
        actions: const [Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.flight_takeoff),
        )],
      ),
      drawer: const AppDrawer(current: 'Home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Helpful notice / instructions
              Card(
                color: Colors.indigo.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'How to use: enter your checked baggage weight, choose your '
                    'ticket class, then enter the excess rate per kg.\n'
                    'Free allowance: Economy = 20 kg, Business = 40 kg.\n'
                    'An 8% service tax is added to the excess charge.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Baggage weight (kg)',
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (v) => _validateNumber(v, 'baggage weight'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _ticketClass,
                decoration: const InputDecoration(
                  labelText: 'Ticket class',
                  prefixIcon: Icon(Icons.airline_seat_recline_extra),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Economy', child: Text('Economy (20 kg)')),
                  DropdownMenuItem(
                      value: 'Business', child: Text('Business (40 kg)')),
                ],
                onChanged: (v) => setState(() => _ticketClass = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Excess baggage rate per kg (RM)',
                  prefixIcon: Icon(Icons.payments),
                ),
                validator: (v) => _validateNumber(v, 'rate per kg'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_totalPayable != null) _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _resultRow('Excess baggage weight',
                '${_excessWeight!.toStringAsFixed(2)} kg'),
            _resultRow('Excess baggage charge',
                'RM ${_excessCharge!.toStringAsFixed(2)}'),
            _resultRow('Service tax (8%)',
                'RM ${(_excessCharge! * kServiceTaxRate).toStringAsFixed(2)}'),
            const Divider(),
            _resultRow('Total amount payable',
                'RM ${_totalPayable!.toStringAsFixed(2)}',
                bold: true),
            if (_excessWeight == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Your baggage is within the free allowance. No charge applies.',
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontSize: bold ? 18 : 16,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(kGithubUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      drawer: const AppDrawer(current: 'About'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.indigo,
              child: Icon(Icons.luggage, size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(kAppTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Name'),
            subtitle: Text(kAuthorName),
          ),
          const ListTile(
            leading: Icon(Icons.badge),
            title: Text('Matric No'),
            subtitle: Text(kMatricNo),
          ),
          const ListTile(
            leading: Icon(Icons.school),
            title: Text('Course'),
            subtitle: Text(kCourse),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('GitHub Repository'),
            subtitle: const Text(
              kGithubUrl,
              style: TextStyle(
                  color: Colors.blue, decoration: TextDecoration.underline),
            ),
            onTap: () => _openUrl(context),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year} $kAuthorName. All rights reserved.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}