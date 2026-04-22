import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models.dart';
import '../cv_provider.dart';
import '../pdf_generator.dart';
import 'form_screen.dart';

class CVPreviewScreen extends StatefulWidget {
  const CVPreviewScreen({super.key});
  @override State<CVPreviewScreen> createState() => _CVPreviewScreenState();
}

class _CVPreviewScreenState extends State<CVPreviewScreen> {
  final List<Color> _pdfColors = [
    const Color(0xFF2C3E50), // Navy
    const Color(0xFF8B0000), // Dark Red
    const Color(0xFF2E86C1), // Bright Blue
    const Color(0xFF1E8449), // Emerald Green
    const Color(0xFF212F3D), // Charcoal
  ];

  final List<String> _pdfFonts = ['Roboto', 'Merriweather', 'Open Sans'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final template = provider.selectedTemplate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        title: Text('Preview — ${template.name}'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FormScreen())),
            tooltip: 'Edit Information',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: provider.pdfFont,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).cardColor,
                    items: _pdfFonts.map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black)))).toList(),
                    onChanged: (val) { if (val != null) provider.updatePdfFont(val); },
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: _pdfColors.map((color) => GestureDetector(
                    onTap: () => provider.updatePdfColor(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: provider.pdfColor == color ? Border.all(color: Colors.blue, width: 2) : null),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

          Expanded(
            child: PdfPreview(
              build: (format) => buildPDF(provider), // Triggers live rebuild!
              useActions: false, allowPrinting: false, allowSharing: false,
              canChangeOrientation: false, canChangePageFormat: false,
              maxPageWidth: 700,
              scrollViewDecoration: const BoxDecoration(color: Color(0xFFECEFF1)),
            ),
          ),
          _PreviewActionBar(provider: provider, isDark: isDark),
        ],
      ),
    );
  }
}

class _PreviewActionBar extends StatelessWidget {
  final CVProvider provider;
  final bool isDark;
  const _PreviewActionBar({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0, runSpacing: 12.0,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final success = await provider.saveDraft();
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved successfully to Downloads!'), backgroundColor: Colors.green));
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save. Storage permission required.'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.save_outlined, size: 16), label: const Text('Save Draft'),
            ),
            ElevatedButton.icon(
              onPressed: () => generateAndSavePDF(context, provider),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16), label: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }
}