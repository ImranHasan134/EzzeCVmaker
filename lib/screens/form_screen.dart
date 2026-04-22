import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../cv_provider.dart';
import 'template_selection_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final provider = context.read<CVProvider>();
    if (provider.currentStep < AppConstants.formSteps.length - 1) {
      provider.setStep(provider.currentStep + 1);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateSelectionScreen()));
    }
  }

  void _prevStep() {
    final provider = context.read<CVProvider>();
    if (provider.currentStep > 0) {
      provider.setStep(provider.currentStep - 1);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final step = provider.currentStep;
    final totalSteps = AppConstants.formSteps.length;

    return Scaffold(
      backgroundColor: AppTheme.bgSurface,
      appBar: AppBar(
        title: const Text('Build Your CV'),
        backgroundColor: AppTheme.bgDeep,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: _prevStep),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateSelectionScreen())),
            child: Text('Skip to Templates', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          _StepProgressBar(current: step, total: totalSteps),
          _StepLabelBar(step: step, total: totalSteps),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PersonalInfoStep(),
                WorkExperienceStep(),
                EducationStep(),
                SkillsStep(),
                ProjectsStep(),
                CertificationsStep(),
              ],
            ),
          ),
          _FormNavBar(onBack: _prevStep, onNext: _nextStep, isLastStep: step == totalSteps - 1, isFirstStep: step == 0),
        ],
      ),
    );
  }
}

class _StepLabelBar extends StatelessWidget {
  final int step;
  final int total;
  const _StepLabelBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(20)),
            child: Text('Step ${step + 1} of $total', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ),
          const SizedBox(width: 10),
          Text(AppConstants.formSteps[step], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _StepProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: List.generate(total, (index) {
          final isCompleted = index < current;
          final isCurrent = index == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300), height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.primaryBlue : isCurrent ? AppTheme.accentCyan : AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < total - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FormNavBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLastStep;
  final bool isFirstStep;

  const _FormNavBar({required this.onBack, required this.onNext, required this.isLastStep, required this.isFirstStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          if (!isFirstStep)
            OutlinedButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Back')),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onNext,
            icon: Icon(isLastStep ? Icons.palette_outlined : Icons.arrow_forward, size: 16),
            label: Text(isLastStep ? 'Choose Template' : 'Continue'),
          ),
        ],
      ),
    );
  }
}

// ---- STEPS ----
class PersonalInfoStep extends StatefulWidget { const PersonalInfoStep({super.key}); @override State<PersonalInfoStep> createState() => _PersonalInfoStepState(); }
class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late PersonalInfo _info;
  @override void initState() { super.initState(); _info = context.read<CVProvider>().personalInfo; }
  void _update() { context.read<CVProvider>().updatePersonalInfo(_info); }
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.person_outline_rounded, title: 'Personal Information', subtitle: 'Tell us about yourself'),
          const SizedBox(height: 20),
          _FormField(label: 'Full Name *', hint: 'e.g. Sarah Johnson', initialValue: _info.fullName, onChanged: (v) { _info.fullName = v; _update(); }),
          _FormField(label: 'Job Title / Role *', hint: 'e.g. Senior Software Engineer', initialValue: _info.jobTitle, onChanged: (v) { _info.jobTitle = v; _update(); }),
          Row(
            children: [
              Expanded(child: _FormField(label: 'Email *', hint: 'email@example.com', initialValue: _info.email, keyboardType: TextInputType.emailAddress, onChanged: (v) { _info.email = v; _update(); })),
              const SizedBox(width: 12),
              Expanded(child: _FormField(label: 'Phone', hint: '+1 234 567 8900', initialValue: _info.phone, keyboardType: TextInputType.phone, onChanged: (v) { _info.phone = v; _update(); })),
            ],
          ),
          _FormField(label: 'Location', hint: 'City, Country', initialValue: _info.location, onChanged: (v) { _info.location = v; _update(); }),
          Row(
            children: [
              Expanded(child: _FormField(label: 'LinkedIn', hint: 'linkedin.com/in/...', initialValue: _info.linkedin, onChanged: (v) { _info.linkedin = v; _update(); })),
              const SizedBox(width: 12),
              Expanded(child: _FormField(label: 'Website / Portfolio', hint: 'yourwebsite.com', initialValue: _info.website, onChanged: (v) { _info.website = v; _update(); })),
            ],
          ),
          _FormField(label: 'Professional Summary', hint: 'A brief overview...', initialValue: _info.summary, maxLines: 4, onChanged: (v) { _info.summary = v; _update(); }),
        ],
      ),
    );
  }
}

class WorkExperienceStep extends StatelessWidget {
  const WorkExperienceStep({super.key});
  @override Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final exps = provider.workExperiences;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.work_outline_rounded, title: 'Work Experience', subtitle: 'Add your professional history'),
          const SizedBox(height: 20),
          ...exps.asMap().entries.map((entry) => _WorkExpCard(index: entry.key, experience: entry.value)),
          const SizedBox(height: 12),
          _AddButton(label: 'Add Work Experience', onTap: () => provider.addWorkExperience()),
          if (exps.isEmpty) const Padding(padding: EdgeInsets.all(24), child: _EmptyStateHint(icon: Icons.work_history_outlined, text: 'No experience added yet.')),
        ],
      ),
    );
  }
}

class _WorkExpCard extends StatefulWidget { final int index; final WorkExperience experience; const _WorkExpCard({required this.index, required this.experience}); @override State<_WorkExpCard> createState() => _WorkExpCardState(); }
class _WorkExpCardState extends State<_WorkExpCard> {
  bool _expanded = true;
  @override Widget build(BuildContext context) {
    final exp = widget.experience;
    return _CollapsibleCard(
      title: exp.company.isNotEmpty ? exp.company : 'New Experience', subtitle: exp.position, expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded), onDelete: () => context.read<CVProvider>().removeWorkExperience(widget.index),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _FormField(label: 'Company', hint: 'Company Name', initialValue: exp.company, onChanged: (v) { exp.company = v; context.read<CVProvider>().updateWorkExperience(widget.index, exp); })),
              const SizedBox(width: 12),
              Expanded(child: _FormField(label: 'Position', hint: 'Your Job Title', initialValue: exp.position, onChanged: (v) { exp.position = v; context.read<CVProvider>().updateWorkExperience(widget.index, exp); })),
            ],
          ),
          Row(
            children: [
              Expanded(child: _FormField(label: 'Start Date', hint: 'Jan 2022', initialValue: exp.startDate, onChanged: (v) { exp.startDate = v; context.read<CVProvider>().updateWorkExperience(widget.index, exp); })),
              const SizedBox(width: 12),
              Expanded(child: exp.isCurrentJob ? const Padding(padding: EdgeInsets.only(top: 8), child: Text('Present', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600))) : _FormField(label: 'End Date', hint: 'Dec 2023', initialValue: exp.endDate, onChanged: (v) { exp.endDate = v; context.read<CVProvider>().updateWorkExperience(widget.index, exp); })),
            ],
          ),
          SwitchListTile(title: const Text('Current Job', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)), value: exp.isCurrentJob, dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.primaryBlue, onChanged: (v) { exp.isCurrentJob = v; context.read<CVProvider>().updateWorkExperience(widget.index, exp); }),
          _FormField(label: 'Key Responsibilities', hint: '- Achieved...', initialValue: exp.description, maxLines: 4, onChanged: (v) { exp.description = v; context.read<CVProvider>().updateWorkExperience(widget.index, exp); }),
        ],
      ),
    );
  }
}

class EducationStep extends StatelessWidget {
  const EducationStep({super.key});
  @override Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final edus = provider.educations;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.school_outlined, title: 'Education', subtitle: 'Add your academic background'),
          const SizedBox(height: 20),
          ...edus.asMap().entries.map((e) => _EducationCard(index: e.key, education: e.value)),
          const SizedBox(height: 12),
          _AddButton(label: 'Add Education', onTap: () => provider.addEducation()),
          if (edus.isEmpty) const Padding(padding: EdgeInsets.all(24), child: _EmptyStateHint(icon: Icons.school_outlined, text: 'No education added yet.')),
        ],
      ),
    );
  }
}

class _EducationCard extends StatefulWidget { final int index; final Education education; const _EducationCard({required this.index, required this.education}); @override State<_EducationCard> createState() => _EducationCardState(); }
class _EducationCardState extends State<_EducationCard> {
  bool _expanded = true;
  @override Widget build(BuildContext context) {
    final edu = widget.education;
    return _CollapsibleCard(
      title: edu.institution.isNotEmpty ? edu.institution : 'New Education', subtitle: edu.degree, expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded), onDelete: () => context.read<CVProvider>().removeEducation(widget.index),
      child: Column(
        children: [
          _FormField(label: 'Institution', hint: 'University Name', initialValue: edu.institution, onChanged: (v) { edu.institution = v; context.read<CVProvider>().updateEducation(widget.index, edu); }),
          Row(
            children: [
              Expanded(child: _FormField(label: 'Degree', hint: 'B.Sc.', initialValue: edu.degree, onChanged: (v) { edu.degree = v; context.read<CVProvider>().updateEducation(widget.index, edu); })),
              const SizedBox(width: 12),
              Expanded(child: _FormField(label: 'Field of Study', hint: 'Computer Science', initialValue: edu.field, onChanged: (v) { edu.field = v; context.read<CVProvider>().updateEducation(widget.index, edu); })),
            ],
          ),
          Row(
            children: [
              Expanded(child: _FormField(label: 'Start Year', hint: '2018', initialValue: edu.startYear, onChanged: (v) { edu.startYear = v; context.read<CVProvider>().updateEducation(widget.index, edu); })),
              const SizedBox(width: 12),
              Expanded(child: _FormField(label: 'End Year', hint: '2022', initialValue: edu.endYear, onChanged: (v) { edu.endYear = v; context.read<CVProvider>().updateEducation(widget.index, edu); })),
              const SizedBox(width: 12),
              Expanded(child: _FormField(label: 'GPA', hint: '3.8', initialValue: edu.grade, onChanged: (v) { edu.grade = v; context.read<CVProvider>().updateEducation(widget.index, edu); })),
            ],
          ),
        ],
      ),
    );
  }
}

class SkillsStep extends StatefulWidget { const SkillsStep({super.key}); @override State<SkillsStep> createState() => _SkillsStepState(); }
class _SkillsStepState extends State<SkillsStep> {
  final _langController = TextEditingController();
  @override void dispose() { _langController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.psychology_outlined, title: 'Skills & Languages', subtitle: 'Highlight your expertise'),
          const SizedBox(height: 20),
          const Text('Technical & Soft Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...provider.skills.asMap().entries.map((e) => _SkillRow(index: e.key, skill: e.value)),
          const SizedBox(height: 8),
          _AddButton(label: 'Add Skill', onTap: () => provider.addSkill()),
          const SizedBox(height: 24), const Divider(color: AppTheme.divider), const SizedBox(height: 16),
          const Text('Languages', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: provider.languages.asMap().entries.map((e) => Container(
              decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2))),
              child: Chip(
                label: Text(e.value, style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.primaryBlue), onDeleted: () => provider.removeLanguage(e.key),
                backgroundColor: Colors.transparent, side: BorderSide.none,
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _langController, decoration: const InputDecoration(labelText: 'Add Language', hintText: 'e.g. Spanish'))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () { provider.addLanguage(_langController.text.trim()); _langController.clear(); }, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)), child: const Icon(Icons.add)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatefulWidget { final int index; final Skill skill; const _SkillRow({required this.index, required this.skill}); @override State<_SkillRow> createState() => _SkillRowState(); }
class _SkillRowState extends State<_SkillRow> {
  late TextEditingController _controller;
  @override void initState() { super.initState(); _controller = TextEditingController(text: widget.skill.name); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Row(
        children: [
          Expanded(flex: 3, child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Skill name', isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false), onChanged: (v) { widget.skill.name = v; context.read<CVProvider>().updateSkill(widget.index, widget.skill); })),
          const SizedBox(width: 8),
          Row(
            children: List.generate(5, (i) {
              final filled = i < widget.skill.level;
              return GestureDetector(
                onTap: () { widget.skill.level = i + 1; context.read<CVProvider>().updateSkill(widget.index, widget.skill); },
                child: Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? AppTheme.primaryBlue : AppTheme.divider)),
              );
            }),
          ),
          const SizedBox(width: 6),
          GestureDetector(onTap: () => context.read<CVProvider>().removeSkill(widget.index), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.delete_outline, size: 16, color: Colors.red))),
        ],
      ),
    );
  }
}

class ProjectsStep extends StatelessWidget {
  const ProjectsStep({super.key});
  @override Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final projects = provider.projects;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.code_rounded, title: 'Projects', subtitle: 'Showcase your work'),
          const SizedBox(height: 20),
          ...projects.asMap().entries.map((e) => _ProjectCard(index: e.key, project: e.value)),
          const SizedBox(height: 12),
          _AddButton(label: 'Add Project', onTap: () => provider.addProject()),
          if (projects.isEmpty) const Padding(padding: EdgeInsets.all(24), child: _EmptyStateHint(icon: Icons.rocket_launch_outlined, text: 'No projects added yet.')),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget { final int index; final Project project; const _ProjectCard({required this.index, required this.project}); @override State<_ProjectCard> createState() => _ProjectCardState(); }
class _ProjectCardState extends State<_ProjectCard> {
  bool _expanded = true;
  @override Widget build(BuildContext context) {
    final proj = widget.project;
    return _CollapsibleCard(
      title: proj.name.isNotEmpty ? proj.name : 'New Project', subtitle: proj.technologies, expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded), onDelete: () => context.read<CVProvider>().removeProject(widget.index),
      child: Column(
        children: [
          _FormField(label: 'Project Name', hint: 'e.g. E-Commerce', initialValue: proj.name, onChanged: (v) { proj.name = v; context.read<CVProvider>().updateProject(widget.index, proj); }),
          _FormField(label: 'Technologies', hint: 'Flutter, Firebase', initialValue: proj.technologies, onChanged: (v) { proj.technologies = v; context.read<CVProvider>().updateProject(widget.index, proj); }),
          _FormField(label: 'Link', hint: 'github.com/...', initialValue: proj.link, onChanged: (v) { proj.link = v; context.read<CVProvider>().updateProject(widget.index, proj); }),
          _FormField(label: 'Description', hint: 'Briefly describe...', initialValue: proj.description, maxLines: 3, onChanged: (v) { proj.description = v; context.read<CVProvider>().updateProject(widget.index, proj); }),
        ],
      ),
    );
  }
}

class CertificationsStep extends StatelessWidget {
  const CertificationsStep({super.key});
  @override Widget build(BuildContext context) {
    final provider = context.watch<CVProvider>();
    final certs = provider.certifications;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.verified_outlined, title: 'Certifications', subtitle: 'Add credentials'),
          const SizedBox(height: 20),
          ...certs.asMap().entries.map((e) => _CertCard(index: e.key, cert: e.value)),
          const SizedBox(height: 12),
          _AddButton(label: 'Add Certification', onTap: () => provider.addCertification()),
          if (certs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: _EmptyStateHint(icon: Icons.military_tech_outlined, text: 'No certifications added yet.')),
        ],
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final int index; final Certification cert; const _CertCard({required this.index, required this.cert});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _FormField(label: 'Certification Name', hint: 'AWS Certified', initialValue: cert.name, onChanged: (v) { cert.name = v; context.read<CVProvider>().updateCertification(index, cert); })),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: _FormField(label: 'Year', hint: '2023', initialValue: cert.year, onChanged: (v) { cert.year = v; context.read<CVProvider>().updateCertification(index, cert); })),
            ],
          ),
          _FormField(label: 'Issuer', hint: 'Amazon', initialValue: cert.issuer, onChanged: (v) { cert.issuer = v; context.read<CVProvider>().updateCertification(index, cert); }),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.read<CVProvider>().removeCertification(index),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red.withOpacity(0.07), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_outline, size: 14, color: Colors.red), SizedBox(width: 4), Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500))])),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- SHARED FORM UI WIDGETS ----

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 20)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))]),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label; final VoidCallback onTap; const _AddButton({required this.label, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primaryBlue), const SizedBox(width: 8), Text(label, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13))]),
      ),
    );
  }
}

class _FormField extends StatefulWidget {
  final String label; final String hint; final String initialValue; final int maxLines; final TextInputType keyboardType; final ValueChanged<String> onChanged;
  const _FormField({required this.label, required this.hint, required this.initialValue, required this.onChanged, this.maxLines = 1, this.keyboardType = TextInputType.text, super.key});
  @override State<_FormField> createState() => _FormFieldState();
}
class _FormFieldState extends State<_FormField> {
  late TextEditingController _controller;
  @override void initState() { super.initState(); _controller = TextEditingController(text: widget.initialValue); _controller.addListener(() { widget.onChanged(_controller.text); }); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: _controller, decoration: InputDecoration(labelText: widget.label, hintText: widget.hint), maxLines: widget.maxLines, keyboardType: widget.keyboardType, textDirection: TextDirection.ltr),
    );
  }
}

class _CollapsibleCard extends StatelessWidget {
  final String title; final String subtitle; final bool expanded; final VoidCallback onToggle; final VoidCallback onDelete; final Widget child;
  const _CollapsibleCard({required this.title, required this.subtitle, required this.expanded, required this.onToggle, required this.onDelete, required this.child});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)), if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))])),
                  GestureDetector(onTap: onDelete, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.withOpacity(0.07), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline, size: 16, color: Colors.red))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(6)), child: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.textSecondary, size: 18)),
                ],
              ),
            ),
          ),
          if (expanded) Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))), padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: child),
        ],
      ),
    );
  }
}

class _EmptyStateHint extends StatelessWidget {
  final IconData icon; final String text; const _EmptyStateHint({required this.icon, required this.text});
  @override Widget build(BuildContext context) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.divider.withOpacity(0.5), shape: BoxShape.circle), child: Icon(icon, size: 36, color: AppTheme.textMuted)),
        const SizedBox(height: 14),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
      ],
    );
  }
}