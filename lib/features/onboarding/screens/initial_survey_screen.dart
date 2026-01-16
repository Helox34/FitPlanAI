import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/user_provider.dart';
import '../../home/screens/main_shell.dart';

/// Initial 4-question survey screen (gender, age, weight, height)
class InitialSurveyScreen extends StatefulWidget {
  const InitialSurveyScreen({super.key});

  @override
  State<InitialSurveyScreen> createState() => _InitialSurveyScreenState();
}

class _InitialSurveyScreenState extends State<InitialSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedGender; // NEW: Gender selection
  bool _isSubmitting = false; // Prevent double-submission
  
  int _currentQuestion = 0;
  
  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  void _nextQuestion() {
    // Prevent multiple clicks
    if (_isSubmitting) return;
    
    // Gender question doesn't use form validation
    if (_currentQuestion == 0) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proszę wybrać płeć')),
        );
        return;
      }
      setState(() => _currentQuestion++);
      return;
    }
    
    // Other questions use form validation
    if (_formKey.currentState!.validate()) {
      if (_currentQuestion < 3) {
        setState(() => _currentQuestion++);
      } else {
        _submitSurvey();
      }
    }
  }
  
  void _previousQuestion() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }
  
  Future<void> _submitSurvey() async {
    if (_isSubmitting) {
      print('⚠️ Already submitting, ignoring...');
      return;
    }
    
    setState(() => _isSubmitting = true);
    print('🔵 _submitSurvey started');
    final userProvider = context.read<UserProvider>();
    
    try {
      // Save gender first
      print('🟢 Saving gender: $_selectedGender');
      await userProvider.updateGender(_selectedGender!);
      print('✅ Gender saved');
      
      // Save survey data
      print('🟢 Saving survey data...');
      await userProvider.saveInitialSurvey(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
      );
      print('✅ Survey data saved');
      
      // Mark survey as completed
      print('🟢 Marking survey as completed...');
      await userProvider.markSurveyCompleted();
      print('✅ Survey marked complete');
      
      if (mounted) {
        print('🟢 Navigating to MainShell...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainShell()),
        );
        print('✅ Navigation called');
      } else {
        print('❌ Widget not mounted!');
      }
    } catch (e) {
      print('❌ Error in _submitSurvey: $e');
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Widget _buildQuestion() {
    switch (_currentQuestion) {
      case 0:
        return _buildGenderQuestion();
      case 1:
        return _buildAgeQuestion();
      case 2:
        return _buildWeightQuestion();
      case 3:
        return _buildHeightQuestion();
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildGenderQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jaka jest Twoja płeć?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        
        // Kobieta
        _buildGenderCard(
          gender: 'female',
          label: 'Kobieta',
          icon: Icons.female,
          color: const Color(0xFFEC4899), // Pink
        ),
        const SizedBox(height: 16),
        
        // Mężczyzna
        _buildGenderCard(
          gender: 'male',
          label: 'Mężczyzna',
          icon: Icons.male,
          color: const Color(0xFF3B82F6), // Blue
        ),
      ],
    );
  }
  
  Widget _buildGenderCard({
    required String gender,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedGender == gender;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedGender = gender),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withOpacity(0.1) 
                : AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAgeQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ile masz lat?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _ageController,
          label: 'Wiek',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Proszę podać wiek';
            }
            final age = int.tryParse(value);
            if (age == null || age < 13 || age > 120) {
              return 'Proszę podać prawidłowy wiek (13-120)';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildWeightQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ile ważysz?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _weightController,
          label: 'Waga (kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Proszę podać wagę';
            }
            final weight = double.tryParse(value);
            if (weight == null || weight < 30 || weight > 300) {
              return 'Proszę podać prawidłową wagę (30-300 kg)';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildHeightQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jaki masz wzrost?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _heightController,
          label: 'Wzrost (cm)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Proszę podać wzrost';
            }
            final height = double.tryParse(value);
            if (height == null || height < 100 || height > 250) {
              return 'Proszę podać prawidłowy wzrost (100-250 cm)';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentQuestion > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: _previousQuestion,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator (4 steps now)
                Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentQuestion
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),
                
                // Question
                Expanded(
                  child: _buildQuestion(),
                ),
                
                // Next button
                CustomButton(
                  text: _currentQuestion < 3 ? 'Dalej' : 'Zakończ',
                  onPressed: _nextQuestion,
                  isLoading: _isSubmitting, // Show loading when submitting
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
