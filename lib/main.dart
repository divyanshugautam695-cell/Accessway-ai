import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'backend_config.dart';
import 'live_map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackend();
  runApp(const AccessWayApp());
}

class AccessWayApp extends StatefulWidget {
  const AccessWayApp({super.key});
  @override
  State<AccessWayApp> createState() => _AccessWayAppState();
}

class _AccessWayAppState extends State<AccessWayApp> {
  ThemeMode mode = ThemeMode.system;
  final List<Map<String, String>> reports = [];

  static const places = [
    {
      'name': 'City Care Hospital',
      'type': 'Hospital',
      'address': 'Kota, Rajasthan · Demo record',
      'entrance': 'Reviewed',
      'ramp': 'Community reported',
      'lift': 'Unknown',
      'washroom': 'Unknown',
      'pathway': 'Reviewed',
      'checked': 'Demo data · 02 Nov 2026',
    },
    {
      'name': 'Central Learning Centre',
      'type': 'Education',
      'address': 'Kota, Rajasthan · Demo record',
      'entrance': 'Unknown',
      'ramp': 'Unknown',
      'lift': 'Unknown',
      'washroom': 'Community reported',
      'pathway': 'Unknown',
      'checked': 'Demo data · 28 Oct 2026',
    },
    {
      'name': 'Community Sports Hall',
      'type': 'Community',
      'address': 'Kota, Rajasthan · Demo record',
      'entrance': 'Reviewed',
      'ramp': 'Needs rechecking',
      'lift': 'Unknown',
      'washroom': 'Unknown',
      'pathway': 'Community reported',
      'checked': 'Demo data · 20 Oct 2026',
    },
  ];

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AccessWay AI',
    debugShowCheckedModeBanner: false,
    themeMode: mode,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1769E0)),
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F7FB), foregroundColor: Color(0xFF10233F)),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF75A9FF), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0B1422),
      cardTheme: CardThemeData(color: const Color(0xFF142238), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    ),
    home: AuthGate(child: MainShell(
      places: places,
      reports: reports,
      mode: mode,
      onMode: (v) => setState(() => mode = v),
      onReport: _saveReport,
    )),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.places, required this.reports, required this.mode, required this.onMode, required this.onReport});
  final List<Map<String, String>> places;
  final List<Map<String, String>> reports;
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onMode;
  final Future<void> Function(Map<String, String>) onReport;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(places: widget.places, onExplore: () => setState(() => tab = 1), onOpen: _openPlace),
      ExplorePage(places: widget.places, onOpen: _openPlace),
      ReportPage(places: widget.places, onSubmit: widget.onReport),
      SettingsPage(count: widget.reports.length, mode: widget.mode, onMode: widget.onMode),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.add_a_photo_outlined), selectedIcon: Icon(Icons.add_a_photo), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Future<void> _saveReport(Map<String, String> report) async {
    final user = supabaseConfigured ? Supabase.instance.client.auth.currentUser : null;
    if (user != null) {
      await Supabase.instance.client.from('barrier_reports').insert({
        'reporter_id': user.id,
        'place_name': report['place'],
        'category': report['category'],
        'description': report['description'],
        'status': 'community_reported',
      });
    }
    if (mounted) setState(() => reports.insert(0, report));
  }

  void _openPlace(Map<String, String> place) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PassportPage(place: place)));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.places, required this.onExplore, required this.onOpen});
  final List<Map<String, String>> places;
  final VoidCallback onExplore;
  final ValueChanged<Map<String, String>> onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(children: [
        const CircleAvatar(backgroundColor: Color(0xFF1769E0), child: Icon(Icons.accessible_forward, color: Colors.white)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ACCESSWAY AI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          Text('Accessibility without boundaries', style: TextStyle(fontSize: 12)),
        ])),
        IconButton(onPressed: onExplore, icon: const Icon(Icons.map_outlined)),
      ]),
      const SizedBox(height: 28),
      Text('Make every journey more informed.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Explore accessibility information, understand what is known, and help report barriers.'),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: onExplore, icon: const Icon(Icons.search), label: const Text('Explore places')),
      const SizedBox(height: 24),
      Text('Places to explore', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...places.map((p) => PlaceCard(place: p, onTap: () => onOpen(p))),
      const SizedBox(height: 12),
      const Text('All locations shown are fictional sample records for this prototype.', style: TextStyle(fontSize: 12)),
    ],
  );
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.places, required this.onOpen});
  final List<Map<String, String>> places;
  final ValueChanged<Map<String, String>> onOpen;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final matches = widget.places.where((p) => ('${p['name']} ${p['type']}').toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Explore places'), actions: [IconButton(tooltip: 'Open live map', icon: const Icon(Icons.map_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveMapPage())))],),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search places or categories')),
        const SizedBox(height: 14),
        Text('${matches.length} demo locations'),
        const SizedBox(height: 8),
        ...matches.map((p) => PlaceCard(place: p, onTap: () => widget.onOpen(p))),
        if (matches.isEmpty) const Text('No matching demo places.'),
        const SizedBox(height: 12),
        const Text('Live map uses your device location and OpenStreetMap community data. Accessibility status must still be verified.'),
      ]),
    );
  }
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, required this.onTap});
  final Map<String, String> place;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: const CircleAvatar(child: Icon(Icons.location_city)),
      title: Text(place['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${place['type']} · ${place['address']}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class PassportPage extends StatelessWidget {
  const PassportPage({super.key, required this.place});
  final Map<String, String> place;
  @override
  Widget build(BuildContext context) {
    const keys = ['entrance', 'ramp', 'lift', 'washroom', 'pathway'];
    const labels = {'entrance': 'Step-free entrance', 'ramp': 'Ramp', 'lift': 'Lift', 'washroom': 'Accessible washroom', 'pathway': 'Pathway'};
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Passport')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(place['name']!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(place['address']!),
        const SizedBox(height: 14),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Demo profile'), subtitle: Text('Check each feature and its evidence. Unknown means not checked, not inaccessible.'))),
        const SizedBox(height: 12),
        Text('Feature information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ...keys.map((k) => Card(child: ListTile(
          title: Text(labels[k]!),
          subtitle: Text(place[k] ?? 'Unknown'),
          trailing: StatusPill(value: place[k] ?? 'Unknown'),
        ))),
        Text('Last checked: ${place['checked']}', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final unknown = value == 'Unknown';
    final stale = value == 'Needs rechecking';
    final bg = unknown ? Colors.grey.shade200 : stale ? const Color(0xFFFFE5E5) : const Color(0xFFE1EDFF);
    final fg = unknown ? Colors.black87 : stale ? const Color(0xFF9C3030) : const Color(0xFF174E9B);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)), child: Text(value, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)));
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.places, required this.onSubmit});
  final List<Map<String, String>> places;
  final Future<void> Function(Map<String, String>) onSubmit;
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final formKey = GlobalKey<FormState>();
  final description = TextEditingController();
  String? place;
  String category = 'Blocked pathway';
  final categories = const ['Blocked pathway', 'Missing or damaged ramp', 'Lift unavailable', 'Inaccessible washroom', 'Missing signage', 'Other'];

  @override
  void dispose() { description.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || place == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a place and complete the description.')));
      return;
    }
    try {
      await widget.onSubmit({'place': place!, 'category': category, 'description': description.text.trim(), 'status': 'Community reported'});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save report. Check your connection and try again.')));
      return;
    }
    description.clear();
    setState(() { place = null; category = categories.first; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(supabaseConfigured ? 'Report saved to your AccessWay account.' : 'Demo report saved for this app session.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report a barrier')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      Text('Help improve accessibility information.', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Describe only what you directly observed. This prototype does not upload photos or location data yet.'),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(value: place, decoration: const InputDecoration(labelText: 'Select a demo place'), items: widget.places.map((p) => DropdownMenuItem(value: p['name'], child: Text(p['name']!))).toList(), onChanged: (v) => setState(() => place = v)),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Barrier category'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => category = v ?? categories.first)),
      const SizedBox(height: 14),
      TextFormField(controller: description, minLines: 4, maxLines: 6, decoration: const InputDecoration(labelText: 'What did you observe?'), validator: (v) => v == null || v.trim().length < 8 ? 'Please add at least 8 characters.' : null),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: submit, icon: const Icon(Icons.send), label: const Text('Save demo report')),
    ])),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.count, required this.mode, required this.onMode});
  final int count;
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onMode;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile & settings')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const CircleAvatar(radius: 32, child: Icon(Icons.person_outline, size: 32)),
      const SizedBox(height: 12),
      Text(supabaseConfigured ? (Supabase.instance.client.auth.currentUser?.email ?? 'Signed in') : 'Guest user', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 18),
      Card(child: ListTile(leading: const Icon(Icons.assignment_outlined), title: const Text('Reports this session'), trailing: Text('$count'))),
      const SizedBox(height: 12),
      Card(child: Column(children: [
        RadioListTile<ThemeMode>(title: const Text('System theme'), value: ThemeMode.system, groupValue: mode, onChanged: (v) => onMode(v!)),
        RadioListTile<ThemeMode>(title: const Text('Light mode'), value: ThemeMode.light, groupValue: mode, onChanged: (v) => onMode(v!)),
        RadioListTile<ThemeMode>(title: const Text('Dark mode'), value: ThemeMode.dark, groupValue: mode, onChanged: (v) => onMode(v!)),
      ])),
      const SizedBox(height: 12),
      const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy first'), subtitle: Text('Account details and reports are stored only when Supabase is configured.'))),
      Card(child: ListTile(leading: const Icon(Icons.cloud_outlined), title: const Text('Backend status'), subtitle: Text(supabaseConfigured ? 'Supabase configured · Cloud report submission enabled' : 'Local demo mode · Supabase setup still required'))),
      if (supabaseConfigured) Card(child: ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: () => Supabase.instance.client.auth.signOut())),
      const Card(child: ListTile(leading: Icon(Icons.build_outlined), title: Text('Prototype status'), subtitle: Text('Live map · Cloud account foundation · AI route intelligence and Scout BLE still in development'))),
    ]),
  );
}
