import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String kAuthorName = 'Ahmad Hulaif Hilmi bin Insidin';
const String kMatricNo = '2024249606';
const String kCourse = 'Netcentric';
const String kGithubUrl =
    'https://github.com/Hulaif/excess-baggage-calculator';

const String kAppTitle = 'Excess Baggage Estimator';
const double kServiceTaxRate = 0.08; // 8% service tax
const int kEconomyAllowance = 20; // kg
const int kBusinessAllowance = 40; // kg

void main() {
  runApp(const BaggageApp());
}


class AppColors {
  static const Color colorPrimary = Color(0xFF1565C0);
  static const Color colorOnPrimary = Color(0xFFFFFFFF);
  static const Color colorSecondary = Color(0xFFE65100);
  static const Color colorOnSecondary = Color(0xFFFFFFFF);
}

ThemeData buildTheme(Brightness brightness) {
  final bool isLight = brightness == Brightness.light;

  ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.colorPrimary,
    brightness: brightness,
  );

  if (isLight) {
    scheme = scheme.copyWith(
      primary: AppColors.colorPrimary,
      onPrimary: AppColors.colorOnPrimary,
      secondary: AppColors.colorSecondary,
      onSecondary: AppColors.colorOnSecondary,
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: scheme.onPrimary,
      ),
      // From Lab 5
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: isLight ? Brightness.light : Brightness.dark,
        statusBarBrightness: isLight ? Brightness.dark : Brightness.light,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

class BaggageApp extends StatelessWidget {
  const BaggageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      debugShowCheckedModeBanner: false, // Lab 2
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark), // Lab 5 exercise 3
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}


class BaggageResult {
  final double weight;
  final String ticketClass;
  final int allowance;
  final double rate;
  final double excessWeight;
  final double charge;
  final double tax;
  final double total;

  const BaggageResult({
    required this.weight,
    required this.ticketClass,
    required this.allowance,
    required this.rate,
    required this.excessWeight,
    required this.charge,
    required this.tax,
    required this.total,
  });

  /// From Lab 6
  String get summary => 'Excess Baggage Estimate\n'
      'Ticket class: $ticketClass ($allowance kg free)\n'
      'Baggage weight: ${weight.toStringAsFixed(2)} kg\n'
      'Rate: RM ${rate.toStringAsFixed(2)} per kg\n'
      'Excess weight: ${excessWeight.toStringAsFixed(2)} kg\n'
      'Excess charge: RM ${charge.toStringAsFixed(2)}\n'
      'Service tax (8%): RM ${tax.toStringAsFixed(2)}\n'
      'Total payable: RM ${total.toStringAsFixed(2)}';
}

BaggageResult calculateBaggage({
  required double weight,
  required String ticketClass,
  required double rate,
}) {
  final int allowance =
      ticketClass == 'Economy' ? kEconomyAllowance : kBusinessAllowance;

  final double difference = weight - allowance;
  final double excessWeight = difference > 0 ? difference : 0.0; 
  final double charge = excessWeight * rate;
  final double tax = charge * kServiceTaxRate;
  final double total = charge + tax;

  return BaggageResult(
    weight: weight,
    ticketClass: ticketClass,
    allowance: allowance,
    rate: rate,
    excessWeight: excessWeight,
    charge: charge,
    tax: tax,
    total: total,
  );
}


// From Lab 3: menu items 
enum MenuAction { home, about }

void openAbout(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AboutPage()),
  );
}
class NavMenu extends StatelessWidget {
  final String current;
  const NavMenu({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MenuAction>(
      onSelected: (MenuAction action) {
        switch (action) {
          case MenuAction.home:
            if (current != 'Home') {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
            break;
          case MenuAction.about:
            if (current != 'About') {
              openAbout(context);
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem(value: MenuAction.home, child: Text('Home')),
        PopupMenuItem(value: MenuAction.about, child: Text('About')),
      ],
    );
  }
}
class AppBarTitle extends StatelessWidget {
  final String text;
  const AppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}


// Home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Input 1 and Input 3: text fields (Lab 4: controllers)
  final TextEditingController weightController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  // Input 2: radio group (Lab 4). null = nothing selected yet.
  String? ticketClass;

  // Output
  BaggageResult? result;

  @override
  void dispose() {
    weightController.dispose();
    rateController.dispose();
    super.dispose();
  }

  // ---- messages (Lab 3 / Lab 4: SnackBar) -----------------------------------
  void showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Show an error 
  void showError(String text) {
    setState(() => result = null);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: scheme.error,
          content: Text(text, style: TextStyle(color: scheme.onError)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // Lab 4: Calculate la
  void calculate() {
    FocusScope.of(context).unfocus();

    final String weightText = weightController.text.trim();
    final String rateText = rateController.text.trim();
    final String? selectedClass = ticketClass;

    // 1. Weight
    if (weightText.isEmpty) {
      showError('Please enter the baggage weight.');
      return;
    }
    final double? weight = double.tryParse(weightText);
    if (weight == null || !weight.isFinite) {
      debugPrint('Invalid weight: $weightText'); // trace in the Debug Console
      showError('Baggage weight must be a number, e.g. 25 or 42.5.');
      return;
    }
    if (weight < 0) {
      showError('Baggage weight cannot be negative.');
      return;
    }
    if (weight > 200) {
      showError('Please enter a realistic weight (0 to 200 kg).');
      return;
    }

    // 2. Ticket class
    if (selectedClass == null) {
      showError('Please select a ticket class.');
      return;
    }

    // 3. Rate
    if (rateText.isEmpty) {
      showError('Please enter the excess baggage rate per kg.');
      return;
    }
    final double? rate = double.tryParse(rateText);
    if (rate == null || !rate.isFinite) {
      debugPrint('Invalid rate: $rateText');
      showError('Rate must be a number, e.g. 15 or 12.50.');
      return;
    }
    if (rate < 0) {
      showError('Rate cannot be negative.');
      return;
    }

    // All values are valid
    setState(() {
      result = calculateBaggage(
        weight: weight,
        ticketClass: selectedClass,
        rate: rate,
      );
    });
  }

  // ---- reset (Lab 4 exercise 3) ---------------------------------------------
  void resetForm() {
    FocusScope.of(context).unfocus();
    weightController.clear();
    rateController.clear();
    setState(() {
      ticketClass = null;
      result = null;
    });
  }

  // ---- share (Lab 6: share_plus) --------------------------------------------
  Future<void> shareResult() async {
    final BaggageResult? current = result;
    if (current == null) {
      showMessage('Calculate first, then share the result.');
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: current.summary,
          subject: 'Excess baggage estimate',
        ),
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      if (!mounted) return;
      showMessage('Sharing is not available on this device.');
    }
  }



  // ---- UI -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(kAppTitle),
        actions: [
          NavMenu(current:'Home')
        ],
      ),

      body: SafeArea(
        // Lab 7: LayoutBuilder decides the layout from the available width.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 720;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildHeader(context),
                      const SizedBox(height: 16),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: buildInputCard(context)),
                            const SizedBox(width: 16),
                            Expanded(child: buildResultCard(context)),
                          ],
                        )
                      else ...[
                        buildInputCard(context),
                        const SizedBox(height: 16),
                        buildResultCard(context),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Logo + short instructions (helpful notice).
  Widget buildHeader(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab 2: Image.asset
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png',
                width: 72,
                height: 72,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.luggage, size: 72),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Enter your checked baggage weight (kg).\n'
                    '2. Choose your ticket class: Economy = 20 kg free, '
                    'Business = 40 kg free.\n'
                    '3. Enter the excess baggage rate per kg (RM).\n'
                    '4. Tap Calculate. An 8% service tax is added to the '
                    'excess charge.',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputCard(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baggage details', style: textTheme.titleLarge),
            const SizedBox(height: 16),

            // Input 1: weight (TextField)
            TextField(
              key: const Key('weightField'),
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Baggage weight (kg)',
                hintText: 'e.g. 25 or 42.5',
                prefixIcon: Icon(Icons.scale),
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 16),

            // Input 2: ticket class (RadioGroup, not a TextField)
            Text('Ticket class', style: textTheme.titleMedium),
            RadioGroup<String>(
              groupValue: ticketClass,
              onChanged: (String? value) =>
                  setState(() => ticketClass = value),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Economy (20 kg)'),
                    value: 'Economy',
                  ),
                  RadioListTile<String>(
                    title: Text('Business (40 kg)'),
                    value: 'Business',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Input 3: rate per kg (TextField)
            TextField(
              key: const Key('rateField'),
              controller: rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => calculate(),
              decoration: const InputDecoration(
                labelText: 'Excess baggage rate per kg (RM)',
                hintText: 'e.g. 15',
                prefixIcon: Icon(Icons.payments),
                prefixText: 'RM ',
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: calculate,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildResultCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final BaggageResult? r = result;

    // Nothing calculated yet: show a hint instead of an empty box.
    if (r == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Result', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.outline),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fill in the details and tap Calculate. The excess '
                      'weight, excess charge and total amount payable will '
                      'appear here.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final bool isDark = theme.brightness == Brightness.dark;
    final Color okColor = isDark ? Colors.green.shade300 : Colors.green.shade800;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${r.ticketClass} class - ${r.allowance} kg free allowance'),
            const Divider(height: 24),
            resultRow(
              'Excess baggage weight',
              '${r.excessWeight.toStringAsFixed(2)} kg',
            ),
            resultRow(
              'Excess baggage charge',
              'RM ${r.charge.toStringAsFixed(2)}',
            ),
            resultRow(
              'Service tax (8%)',
              'RM ${r.tax.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),
            resultRow(
              'Total amount payable',
              'RM ${r.total.toStringAsFixed(2)}',
              emphasize: true,
              valueColor: scheme.secondary, // Lab 5 exercise 2
            ),
            if (r.excessWeight == 0) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: okColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your baggage is within the free allowance. '
                      'No excess charge applies.',
                      style: TextStyle(color: okColor),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: shareResult,
                icon: const Icon(Icons.share),
                label: const Text('Share result'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultRow(
    String label,
    String value, {
    bool emphasize = false,
    Color? valueColor,
  }) {
    final TextStyle style = TextStyle(
      fontSize: emphasize ? 18 : 16,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// About page
// -----------------------------------------------------------------------------
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> openRepository(BuildContext context) async {
    final Uri uri = Uri.parse(kGithubUrl);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $uri: $e');
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
      title: const Text('About'),
      actions: const [NavMenu(current: 'About')],
        ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Application icon
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 96,
                      height: 96,
                      errorBuilder: (context, error, stack) => Icon(
                        Icons.luggage,
                        size: 96,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    kAppTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Center(child: Text('Version 1.0.0')),
                const SizedBox(height: 24),

                // Author information
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Name'),
                        subtitle: Text(kAuthorName),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.badge),
                        title: Text('Matric No'),
                        subtitle: Text(kMatricNo),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.school),
                        title: Text('Course'),
                        subtitle: Text(kCourse),
                      ),
                      const Divider(height: 1),
                      // Clickable GitHub URL
                      ListTile(
                        leading: const Icon(Icons.link),
                        title: const Text('GitHub Repository'),
                        subtitle: Text(
                          kGithubUrl,
                          style: TextStyle(
                            color: scheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => openRepository(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Copyright notice
                Center(
                  child: Text(
                    '© ${DateTime.now().year} $kAuthorName. '
                    'All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}