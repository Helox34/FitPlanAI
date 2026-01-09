import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/user_provider.dart';
import '../../home/screens/main_shell.dart';

/// Initial 3-question survey screen (age, weight, height)
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
  
  int _currentQuestion = 0;
  
  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  void _nextQuestion() {
    if (_formKey.currentState!.validate()) {
      if (_currentQuestion < 2) {
        setState(() {
          _currentQuestion++;
        });
      } else {
        _submitSurvey();
      }
    }
  }
  
  void _previousQuestion() {
    if (_currentQuestion > 0) {
      setState(() {
        _currentQuestion--;
      });
    }
  }
  
  Future<void> _submitSurvey() async {
    final userProvider = context.read<UserProvider>();
    
    // Save survey data AND mark as completed
    await userProvider.saveInitialSurvey(
      age: int.parse(_ageController.text),
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
    );
    
    // Mark survey as completed
    await userProvider.markSurveyCompleted();
    
    if (mounted) {
      // Go directly to MainShell (no PlanTypeSelectionScreen)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainShell(),
        ),
      );
    }
  }
  
  Widget _buildQuestion() {
    switch (_currentQuestion) {
      case 0:
        return _buildAgeQuestion();
      case 1:
        return _buildWeightQuestion();
      case 2:
        return _buildHeightQuestion();
      default:
        return const SizedBox();
    }
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
                // Progress indicator
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
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
                  text: _currentQuestion < 2 ? 'Dalej' : 'Zakończ',
                  onPressed: _nextQuestion,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
