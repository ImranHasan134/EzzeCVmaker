import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';
import '../cv_provider.dart';
import 'form_screen.dart';
import 'template_selection_screen.dart';
import 'saved_cvs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedCVs = context.watch<CVProvider>().savedCVs;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(context),
                      const SizedBox(height: 36),
                      _buildTemplatesPreview(context),
                      const SizedBox(height: 36),
                      if (savedCVs.isNotEmpty) ...[
                        _buildSavedCVsSection(context, savedCVs),
                        const SizedBox(height: 28),
                      ],
                      _buildTipsCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_rounded, color: Color(0xFF0A0F1E), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('EzzeCV', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: IconButton(
                  onPressed: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom, allowedExtensions: ['json'],
                      );
                      if (result != null && result.files.single.path != null) {
                        File file = File(result.files.single.path!);
                        String jsonString = await file.readAsString();
                        if (context.mounted) {
                          context.read<CVProvider>().importFromJson(jsonString);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CV Imported Successfully!'), backgroundColor: Colors.green));
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to import file. Make sure it is a valid EzzeCV .json backup.'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  icon: const Icon(Icons.file_upload_outlined, color: Colors.white70, size: 20),
                  tooltip: 'Import CV (.json)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Build Your\nCareer Story', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Create professional CVs with ATS-friendly\ntemplates — 100% offline.', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'GET STARTED'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_outline_rounded, label: 'Create New CV', subtitle: 'Start from scratch',
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                onTap: () {
                  context.read<CVProvider>().resetForm();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_open_rounded, label: 'Saved CVs', subtitle: 'View your history',
                gradient: const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCVsScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatesPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel(label: 'TEMPLATES'),
            GestureDetector(
              onTap: () {
                context.read<CVProvider>().resetForm();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: const Text('See All', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = AppConstants.templates[index];
              return _MiniTemplateCard(template: template, index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCVsSection(BuildContext context, List<SavedCV> savedCVs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'RECENT CVs'),
        const SizedBox(height: 14),
        ...savedCVs.take(3).map((cv) => _SavedCVTile(cv: cv)),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro Tip', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB45309), fontSize: 13)),
                SizedBox(height: 4),
                Text(
                  'Use the Classic ATS template when applying to large companies — it ensures your CV passes automated screening systems.',
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.4));
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.subtitle, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.1)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MiniTemplateCard extends StatelessWidget {
  final CVTemplate template;
  final int index;

  const _MiniTemplateCard({required this.template, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<CVProvider>()..resetForm()..selectTemplate(index);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
      },
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider), color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: template.primaryColor.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(template.icon, color: template.primaryColor, size: 22),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                template.name, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: template.primaryColor, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCVTile extends StatelessWidget {
  final SavedCV cv;
  const _SavedCVTile({required this.cv});

  @override
  Widget build(BuildContext context) {
    // Basic implementation since printing relies on _buildPDF outside this file
    // Real printing logic would be inside SavedCVsScreen or exported utility
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: cv.isDraft ? AppTheme.accentGold.withOpacity(0.12) : AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cv.isDraft ? Icons.edit_document : Icons.description, color: cv.isDraft ? AppTheme.accentGold : AppTheme.primaryBlue, size: 18),
        ),
        title: Text(cv.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
        subtitle: Text(
          cv.isDraft ? 'Draft · ${cv.savedAt}' : '${cv.templateName} · ${cv.savedAt}',
          style: TextStyle(fontSize: 11, color: cv.isDraft ? AppTheme.accentGold : AppTheme.textSecondary, fontWeight: cv.isDraft ? FontWeight.w600 : FontWeight.normal),
        ),
        trailing: GestureDetector(
          onTap: () {
            context.read<CVProvider>().loadCV(cv);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FormScreen()));
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.edit, size: 16, color: AppTheme.accentGold),
          ),
        ),
      ),
    );
  }
}