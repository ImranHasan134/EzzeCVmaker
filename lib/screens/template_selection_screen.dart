import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../cv_provider.dart';
import 'preview_screen.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final selected = provider.selectedTemplateIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Choose Template'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: AppTheme.primaryBlue),
                SizedBox(width: 10),
                Expanded(child: Text('Select a template that best fits your profile. You can change it anytime.', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12, height: 1.4))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AppConstants.templates.length,
              itemBuilder: (context, index) {
                final template = AppConstants.templates[index];
                final isSelected = index == selected;

                return GestureDetector(
                  onTap: () => provider.selectTemplate(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSelected ? template.primaryColor : (isDark ? Colors.white12 : AppTheme.divider), width: isSelected ? 2 : 1),
                      color: isSelected ? template.primaryColor.withOpacity(0.05) : Theme.of(context).cardColor,
                      boxShadow: isDark ? null : (isSelected ? [BoxShadow(color: template.primaryColor.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))] : [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 54, height: 70,
                            decoration: BoxDecoration(color: template.primaryColor, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(template.icon, color: Colors.white, size: 22),
                                const SizedBox(height: 4), Container(height: 2, width: 28, color: Colors.white54),
                                const SizedBox(height: 3), Container(height: 2, width: 22, color: Colors.white38),
                                const SizedBox(height: 3), Container(height: 2, width: 26, color: Colors.white38),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(child: Text(template.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isSelected ? template.primaryColor : (isDark ? Colors.white : AppTheme.textPrimary)))),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: template.primaryColor, borderRadius: BorderRadius.circular(20)), child: const Text('Selected', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(template.description, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppTheme.textSecondary, height: 1.4)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? template.primaryColor : (isDark ? Colors.white24 : AppTheme.divider), size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: isDark ? Colors.white12 : AppTheme.divider))),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CVPreviewScreen())),
                icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Preview CV'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}