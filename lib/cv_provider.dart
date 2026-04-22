import 'dart:convert';
import 'package:flutter/material.dart';
import 'models.dart';

class CVProvider extends ChangeNotifier {
  PersonalInfo _personalInfo = PersonalInfo();
  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  List<Project> _projects = [];
  List<Certification> _certifications = [];
  List<Skill> _skills = [];
  List<String> _languages = [];

  int _selectedTemplateIndex = 0;
  int _currentStep = 0;
  List<SavedCV> _savedCVs = [];
  bool _previewDarkMode = false;

  PersonalInfo get personalInfo => _personalInfo;
  List<WorkExperience> get workExperiences => _workExperiences;
  List<Education> get educations => _educations;
  List<Project> get projects => _projects;
  List<Certification> get certifications => _certifications;
  List<Skill> get skills => _skills;
  List<String> get languages => _languages;
  int get selectedTemplateIndex => _selectedTemplateIndex;
  int get currentStep => _currentStep;
  List<SavedCV> get savedCVs => _savedCVs;
  bool get previewDarkMode => _previewDarkMode;

  CVTemplate get selectedTemplate => AppConstants.templates[_selectedTemplateIndex];

  void updatePersonalInfo(PersonalInfo info) { _personalInfo = info; notifyListeners(); }
  void addWorkExperience() { _workExperiences.add(WorkExperience()); notifyListeners(); }
  void updateWorkExperience(int index, WorkExperience exp) { _workExperiences[index] = exp; notifyListeners(); }
  void removeWorkExperience(int index) { _workExperiences.removeAt(index); notifyListeners(); }
  void addEducation() { _educations.add(Education()); notifyListeners(); }
  void updateEducation(int index, Education edu) { _educations[index] = edu; notifyListeners(); }
  void removeEducation(int index) { _educations.removeAt(index); notifyListeners(); }
  void addProject() { _projects.add(Project()); notifyListeners(); }
  void updateProject(int index, Project proj) { _projects[index] = proj; notifyListeners(); }
  void removeProject(int index) { _projects.removeAt(index); notifyListeners(); }
  void addCertification() { _certifications.add(Certification()); notifyListeners(); }
  void updateCertification(int index, Certification cert) { _certifications[index] = cert; notifyListeners(); }
  void removeCertification(int index) { _certifications.removeAt(index); notifyListeners(); }
  void addSkill() { _skills.add(Skill()); notifyListeners(); }
  void updateSkill(int index, Skill skill) { _skills[index] = skill; notifyListeners(); }
  void removeSkill(int index) { _skills.removeAt(index); notifyListeners(); }
  void addLanguage(String lang) { if (lang.isNotEmpty) _languages.add(lang); notifyListeners(); }
  void removeLanguage(int index) { _languages.removeAt(index); notifyListeners(); }
  void selectTemplate(int index) { _selectedTemplateIndex = index; notifyListeners(); }
  void setStep(int step) { _currentStep = step; notifyListeners(); }
  void togglePreviewDarkMode() { _previewDarkMode = !_previewDarkMode; notifyListeners(); }
  void addSavedCV(SavedCV cv) { _savedCVs.insert(0, cv); notifyListeners(); }
  void removeSavedCV(String id) { _savedCVs.removeWhere((cv) => cv.id == id); notifyListeners(); }

  void saveDraft() {
    final dt = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    final draft = SavedCV(
      id: dt.millisecondsSinceEpoch.toString(),
      name: _personalInfo.fullName.isNotEmpty ? '${_personalInfo.fullName} (Draft)' : 'Untitled Draft',
      templateName: AppConstants.templates[_selectedTemplateIndex].name,
      savedAt: dateStr,
      filePath: null,
      isDraft: true,
      personalInfo: _personalInfo.copyWith(),
      workExperiences: _workExperiences.map((e) => e.copy()).toList(),
      educations: _educations.map((e) => e.copy()).toList(),
      projects: _projects.map((e) => e.copy()).toList(),
      certifications: _certifications.map((e) => e.copy()).toList(),
      skills: _skills.map((e) => e.copy()).toList(),
      languages: List.from(_languages),
      templateIndex: _selectedTemplateIndex,
    );
    addSavedCV(draft);
  }

  void loadCV(SavedCV cv) {
    _personalInfo = cv.personalInfo.copyWith();
    _workExperiences = cv.workExperiences.map((e) => e.copy()).toList();
    _educations = cv.educations.map((e) => e.copy()).toList();
    _projects = cv.projects.map((e) => e.copy()).toList();
    _certifications = cv.certifications.map((e) => e.copy()).toList();
    _skills = cv.skills.map((e) => e.copy()).toList();
    _languages = List.from(cv.languages);
    _selectedTemplateIndex = cv.templateIndex;
    _currentStep = 0;
    notifyListeners();
  }

  void resetForm() {
    _personalInfo = PersonalInfo();
    _workExperiences = [];
    _educations = [];
    _projects = [];
    _certifications = [];
    _skills = [];
    _languages = [];
    _selectedTemplateIndex = 0;
    _currentStep = 0;
    notifyListeners();
  }

  String exportToJson() {
    final data = {
      'personalInfo': _personalInfo.toJson(),
      'workExperiences': _workExperiences.map((e) => e.toJson()).toList(),
      'educations': _educations.map((e) => e.toJson()).toList(),
      'projects': _projects.map((e) => e.toJson()).toList(),
      'certifications': _certifications.map((e) => e.toJson()).toList(),
      'skills': _skills.map((e) => e.toJson()).toList(),
      'languages': _languages,
      'templateIndex': _selectedTemplateIndex,
    };
    return jsonEncode(data);
  }

  void importFromJson(String jsonString) {
    final data = jsonDecode(jsonString);
    _personalInfo = PersonalInfo.fromJson(data['personalInfo'] ?? {});
    _workExperiences = (data['workExperiences'] as List?)?.map((e) => WorkExperience.fromJson(e)).toList() ?? [];
    _educations = (data['educations'] as List?)?.map((e) => Education.fromJson(e)).toList() ?? [];
    _projects = (data['projects'] as List?)?.map((e) => Project.fromJson(e)).toList() ?? [];
    _certifications = (data['certifications'] as List?)?.map((e) => Certification.fromJson(e)).toList() ?? [];
    _skills = (data['skills'] as List?)?.map((e) => Skill.fromJson(e)).toList() ?? [];
    _languages = List<String>.from(data['languages'] ?? []);
    _selectedTemplateIndex = data['templateIndex'] ?? 0;
    _currentStep = 0;
    notifyListeners();
  }
}