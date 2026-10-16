import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const DualMindApp());

class C {
  static const paper = Color(0xFFF8F3EE);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2B1D2A);
  static const purple = Color(0xFF593477);
  static const lavender = Color(0xFFE0D2F0);
  static const lilac = Color(0xFFEDE3F5);
  static const maroon = Color(0xFF5B1831);
  static const rose = Color(0xFFEFDDE2);
  static const brown = Color(0xFF946545);
  static const sand = Color(0xFFE8D3BE);
  static const muted = Color(0xFF655866);
  static const line = Color(0xFFD8CDD8);
  static const green = Color(0xFF356044);
}

class DualMindApp extends StatelessWidget {
  const DualMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DualMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.purple,
          surface: C.paper,
          primary: C.maroon,
        ),
        fontFamily: 'Roboto',
      ),
      home: const Workspace(),
    );
  }
}

class Workspace extends StatefulWidget {
  const Workspace({super.key});

  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  int page = 0;
  bool uploading = false;
  bool asking = false;
  String? documentId;
  String? documentName;
  String? answer;
  List<dynamic> sources = [];

  void go(int value) => setState(() => page = value);

  Future<void> uploadDocument() async {
    if (uploading) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isEmpty) return;

      final file = result.single;
      final filePath = file.path;

      if (filePath == null) {
        notice('Could not access that file. Please try another PDF.');
        return;
      }

      final fileSize = await file.length();
      if (fileSize == null) {
        notice('Could not determine the PDF size. Please try another file.');
        return;
      }
      if (fileSize > 20 * 1024 * 1024) {
        notice('This PDF is larger than the 20 MB upload limit.');
        return;
      }

      setState(() => uploading = true);
      notice('Uploading and processing your PDF...');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/documents/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(const Duration(minutes: 3));
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map
            ? data['error']?.toString() ??
                  data['message']?.toString() ??
                  'Upload failed (${response.statusCode}).'
            : 'Upload failed (${response.statusCode}).';
        throw Exception(message);
      }

      if (data is! Map || data['document_id'] == null) {
        throw Exception('Server response did not include a document ID.');
      }

      if (!mounted) return;

      setState(() {
        documentId = data['document_id'].toString();
        documentName = data['filename']?.toString() ?? file.name;
      });

      notice('PDF uploaded successfully: $documentName');
    } catch (error) {
      if (mounted) notice('Could not upload PDF: $error');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> askDocument(String question, String mode) async {
    final id = documentId;

    if (mode != 'general' && id == null) {
      notice('Upload a PDF for Document or Combined mode.');
      return;
    }
    if (asking) return;

    setState(() {
      asking = true;
      answer = null;
      sources = [];
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:5000/documents/${id ?? 'general'}/ask'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question, 'top_k': 3, 'mode': mode}),
          )
          .timeout(const Duration(minutes: 3));

      final data = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map
            ? data['error']?.toString() ??
                  'Question failed (${response.statusCode}).'
            : 'Question failed (${response.statusCode}).';
        throw Exception(message);
      }

      if (data is! Map || data['answer'] == null) {
        throw Exception('The server did not return an answer.');
      }

      if (!mounted) return;
      setState(() {
        answer = data['answer'].toString();
        sources = data['sources'] is List ? data['sources'] as List : [];
      });
    } catch (error) {
      if (mounted) notice('Could not get an answer: $error');
    } finally {
      if (mounted) setState(() => asking = false);
    }
  }

  void notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: C.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;

        final pages = [
          HomePage(
            onLibrary: () => go(1),
            onResearch: () => go(2),
            onUpload: uploadDocument,
          ),
          LibraryPage(
            onUpload: uploadDocument,
            onResearch: () => go(2),
            documentName: documentName,
          ),
          ResearchPage(
            onSend: askDocument,
            onLibrary: () => go(1),
            documentName: documentName,
            answer: answer,
            sources: sources,
            asking: asking,
          ),
        ];

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (desktop) NavigationSidebar(page: page, onSelect: go),
                Expanded(
                  child: Column(
                    children: [
                      TopBar(
                        onSettings: () =>
                            notice('Appearance and settings are coming next.'),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey(page),
                            child: pages[page],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: desktop
              ? null
              : BottomNavigationBar(
                  currentIndex: page,
                  onTap: go,
                  backgroundColor: C.white,
                  selectedItemColor: C.maroon,
                  unselectedItemColor: C.muted,
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.auto_stories_outlined),
                      activeIcon: Icon(Icons.auto_stories_rounded),
                      label: 'Library',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.forum_outlined),
                      activeIcon: Icon(Icons.forum_rounded),
                      label: 'Research',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: C.ink,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.all_inclusive_rounded,
              color: C.lavender,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DualMind',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: C.ink,
                ),
              ),
              Text(
                'YOUR PERSONAL KNOWLEDGE STUDIO',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.1,
                  color: C.muted,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded, color: C.ink),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: C.brown),
            ),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: C.lavender,
              child: Icon(Icons.person_outline, color: C.purple, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({
    super.key,
    required this.page,
    required this.onSelect,
  });

  final int page;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 225,
      decoration: const BoxDecoration(
        color: C.white,
        border: Border(right: BorderSide(color: C.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 0, 15),
            child: Text(
              'YOUR SPACE',
              style: TextStyle(
                color: C.muted,
                fontSize: 10,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: page == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.auto_stories_outlined,
            label: 'My library',
            selected: page == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            icon: Icons.forum_outlined,
            label: 'AI research',
            selected: page == 2,
            onTap: () => onSelect(2),
          ),
          const SizedBox(height: 28),
          const Divider(color: C.line),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              'YOUR APPROACH',
              style: TextStyle(
                color: C.muted,
                fontSize: 10,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const _MiniFeature(
            icon: Icons.menu_book_rounded,
            title: 'Read thoughtfully',
          ),
          const _MiniFeature(
            icon: Icons.travel_explore_rounded,
            title: 'Explore connections',
          ),
          const _MiniFeature(
            icon: Icons.format_quote_rounded,
            title: 'Keep the sources',
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: C.lilac,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: C.purple),
                SizedBox(height: 12),
                Text(
                  'Knowledge grows when curiosity leads.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: C.ink,
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? C.lilac : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? C.maroon : C.muted),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? C.maroon : C.ink,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _MiniFeature extends StatelessWidget {
  const _MiniFeature({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 0, 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: C.brown),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: C.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onLibrary,
    required this.onResearch,
    required this.onUpload,
  });

  final VoidCallback onLibrary;
  final VoidCallback onResearch;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('A QUIETER WAY TO THINK'),
          const SizedBox(height: 18),
          const Text(
            'Ideas deserve\nroom to grow.',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 43,
              height: 1.12,
              letterSpacing: -1.5,
              color: C.ink,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 500,
            child: Text(
              'Bring your documents together. Ask better questions. '
              'Find the ideas hiding between the pages.',
              style: TextStyle(fontSize: 15, height: 1.8, color: C.muted),
            ),
          ),
          const SizedBox(height: 28),
          _ResearchPrompt(onTap: onResearch),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your little corner of knowledge',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 23,
                    color: C.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: onLibrary,
                child: const Text('Explore all →'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > 570;
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: wide
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.stretch,
                children: [
                  ExpandedIf(
                    expanded: wide,
                    child: _CollectionTile(
                      color: C.lilac,
                      icon: Icons.auto_stories_rounded,
                      kicker: 'YOUR LIBRARY',
                      title: 'Documents,\nall together.',
                      action: 'Browse your collection',
                      onTap: onLibrary,
                    ),
                  ),
                  SizedBox(width: wide ? 15 : 0, height: wide ? 0 : 14),
                  ExpandedIf(
                    expanded: wide,
                    child: _CollectionTile(
                      color: C.sand,
                      icon: Icons.forum_rounded,
                      kicker: 'YOUR RESEARCH',
                      title: 'Questions lead\nto discoveries.',
                      action: 'Start exploring',
                      onTap: onResearch,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: C.brown.withValues(alpha: .5)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.format_quote_rounded, color: C.maroon, size: 27),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Every good answer should help you find your way back to the source.',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      color: C.ink,
                      height: 1.5,
                    ),
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

class ExpandedIf extends StatelessWidget {
  const ExpandedIf({super.key, required this.expanded, required this.child});
  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      expanded ? Expanded(child: child) : child;
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.onUpload,
    required this.onResearch,
    required this.documentName,
  });

  final VoidCallback onUpload;
  final VoidCallback onResearch;
  final String? documentName;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('A HOME FOR WHAT YOU LEARN'),
          const SizedBox(height: 14),
          const Text(
            'The library.',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 42,
              color: C.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your documents, ready to be rediscovered.',
            style: TextStyle(color: C.muted, fontSize: 14),
          ),
          const SizedBox(height: 25),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: 'Find a document...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: C.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: C.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: C.line),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your collection',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 23,
                    color: C.ink,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onUpload,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: C.maroon,
                  foregroundColor: C.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (widget.documentName == null)
            _EmptyLibrary(onUpload: widget.onUpload)
          else if (!widget.documentName!.toLowerCase().contains(
            query.toLowerCase(),
          ))
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No matching documents yet. Try another search.',
                style: TextStyle(color: C.muted),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: C.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 54,
                    decoration: BoxDecoration(
                      color: C.lilac,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: C.maroon,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.documentName!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: C.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Uploaded and ready to research',
                          style: TextStyle(color: C.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ask about this PDF',
                    onPressed: widget.onResearch,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: C.purple,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: C.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: C.brown, size: 25),
                const SizedBox(width: 13),
                const Expanded(
                  child: Text(
                    'Have a question about a document? You can explore it in AI research.',
                    style: TextStyle(color: C.ink, height: 1.5, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: widget.onResearch,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onUpload});
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.line),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 76,
            decoration: BoxDecoration(
              color: C.lilac,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: C.purple,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your next discovery starts here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Georgia', fontSize: 21, color: C.ink),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a PDF to begin building your personal library.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Choose a document'),
          ),
        ],
      ),
    );
  }
}

class ResearchPage extends StatefulWidget {
  const ResearchPage({
    super.key,
    required this.onSend,
    required this.onLibrary,
    required this.documentName,
    required this.answer,
    required this.sources,
    required this.asking,
  });

  final Future<void> Function(String question, String mode) onSend;
  final VoidCallback onLibrary;
  final String? documentName;
  final String? answer;
  final List<dynamic> sources;
  final bool asking;

  @override
  State<ResearchPage> createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> {
  final controller = TextEditingController();
  String selectedMode = 'document';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('THINK WITH YOUR DOCUMENTS'),
          const SizedBox(height: 14),
          const Text(
            'Let curiosity lead.',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 39,
              letterSpacing: -1,
              color: C.ink,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ask a question. Follow the evidence. Keep the sources close.',
            style: TextStyle(color: C.muted, height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [C.ink, C.purple],
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: C.lavender, size: 27),
                SizedBox(height: 18),
                Text(
                  'Good questions open doors.',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 27,
                    color: C.white,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'DualMind can use passages from your PDFs to help answer your questions, with sources you can revisit.',
                  style: TextStyle(color: C.lavender, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What would you like to understand?',
            style: TextStyle(fontFamily: 'Georgia', fontSize: 22, color: C.ink),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: C.white,
              border: Border.all(color: C.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  decoration: const InputDecoration(
                    labelText: 'Answer mode',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'document',
                      child: Text('Document — use my PDF'),
                    ),
                    DropdownMenuItem(
                      value: 'general',
                      child: Text('General Knowledge — no PDF needed'),
                    ),
                    DropdownMenuItem(
                      value: 'combined',
                      child: Text('Combined — PDF + general knowledge'),
                    ),
                  ],
                  onChanged: widget.asking
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => selectedMode = value);
                          }
                        },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: selectedMode == 'general'
                        ? 'Ask anything you want to learn...'
                        : selectedMode == 'combined'
                        ? 'Ask using your PDF and general knowledge...'
                        : 'Ask something about your documents...',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(color: C.line),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Choose from library',
                      onPressed: widget.onLibrary,
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: C.purple,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (selectedMode == 'general'
                            ? 'General knowledge'
                            : selectedMode == 'combined'
                            ? 'PDF + general knowledge'
                            : 'Grounded in your documents'),
                        style: TextStyle(fontSize: 11, color: C.muted),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        if (controller.text.trim().isEmpty || widget.asking) {
                          return;
                        }
                        widget.onSend(controller.text.trim(), selectedMode);
                      },
                      icon: widget.asking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: C.white,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: Text(widget.asking ? 'Thinking...' : 'Ask'),
                      style: FilledButton.styleFrom(
                        backgroundColor: C.maroon,
                        foregroundColor: C.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.documentName == null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: C.sand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Upload a PDF in your Library first, then ask a question about it here.',
                style: TextStyle(color: C.ink, height: 1.5),
              ),
            ),
          if (widget.asking)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: LinearProgressIndicator(color: C.purple),
            ),
          if (widget.answer != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: C.purple),
                      SizedBox(width: 9),
                      Text(
                        'DualMind’s answer',
                        style: TextStyle(
                          color: C.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    widget.answer!,
                    style: const TextStyle(color: C.ink, height: 1.7),
                  ),
                  if (widget.sources.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: C.line),
                    const SizedBox(height: 8),
                    const Text(
                      'Sources from your PDF',
                      style: TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < widget.sources.length; i++)
                      if (widget.sources[i] is Map)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: C.paper,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Page ${widget.sources[i]['page'] ?? '—'}',
                                style: const TextStyle(
                                  color: C.maroon,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${widget.sources[i]['text'] ?? ''}',
                                style: const TextStyle(
                                  color: C.muted,
                                  height: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'A few places to begin',
            style: TextStyle(fontFamily: 'Georgia', fontSize: 20, color: C.ink),
          ),
          const SizedBox(height: 12),
          _Suggestion(
            text: 'Summarise the key ideas in a document',
            onTap: () =>
                controller.text = 'Summarise the key ideas in my document.',
          ),
          _Suggestion(
            text: 'Find evidence that supports a particular idea',
            onTap: () =>
                controller.text = 'Find evidence that supports this idea.',
          ),
          _Suggestion(
            text: 'Explain a difficult concept in simple words',
            onTap: () => controller.text =
                'Explain a difficult concept in simple words.',
          ),
        ],
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: C.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: C.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(Icons.north_west_rounded, color: C.brown, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(color: C.ink, fontSize: 13),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: C.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResearchPrompt extends StatelessWidget {
  const _ResearchPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: C.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: C.lilac,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_awesome, color: C.purple),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Begin with a question',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Explore what your documents have to say',
                      style: TextStyle(color: C.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: C.maroon),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.color,
    required this.icon,
    required this.kicker,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String kicker;
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: C.maroon),
              const SizedBox(height: 19),
              Text(
                kicker,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: C.muted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 25,
                  height: 1.2,
                  color: C.ink,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: C.maroon,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: C.maroon,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: C.maroon,
      ),
    );
  }
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 38),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: child,
        ),
      ),
    );
  }
}
