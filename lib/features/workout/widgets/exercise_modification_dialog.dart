import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/plan_provider.dart';
import '../../../services/exercise_modification_service.dart';
import '../../../services/openrouter_service.dart';

/// Dialog for requesting AI-powered exercise modifications
class ExerciseModificationDialog extends StatefulWidget {
  final PlanItem exercise;
  final int dayIndex;
  final int exerciseIndex;

  const ExerciseModificationDialog({
    super.key,
    required this.exercise,
    required this.dayIndex,
    required this.exerciseIndex,
  });

  @override
  State<ExerciseModificationDialog> createState() =>
      _ExerciseModificationDialogState();
}

class _ExerciseModificationDialogState
    extends State<ExerciseModificationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<PlanItem>? _alternatives;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Proszę wpisać swoją prośbę';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _alternatives = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final planProvider = context.read<PlanProvider>();

      // 1. Build user context
      final userContext =
          await ExerciseModificationService().buildUserContext(
        userProvider: userProvider,
        planProvider: planProvider,
      );

      // 2. Request AI suggestions
      final alternatives = await OpenRouterService().modifyExercise(
        currentExercise: widget.exercise,
        userRequest: _controller.text,
        userContext: userContext,
      );

      // 3. Validate alternatives for safety
      final modService = ExerciseModificationService();
      final safeAlternatives = alternatives.where((alt) {
        return modService.validateExerciseSafety(
          exercise: alt,
          userContext: userContext,
        );
      }).toList();

      if (safeAlternatives.isEmpty) {
        setState(() {
          _errorMessage =
              'Niestety, AI nie znalazło bezpiecznych alternatyw dla Twojego profilu. Spróbuj innej prośby lub skonsultuj się z trenerem.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _alternatives = safeAlternatives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Wystąpił błąd: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectAlternative(PlanItem alternative) {
    final planProvider = context.read<PlanProvider>();
    
    // Replace exercise in plan
    planProvider.replaceExercise(
      dayIndex: widget.dayIndex,
      exerciseIndex: widget.exerciseIndex,
      newExercise: alternative,
    );

    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Ćwiczenie zmienione na: ${alternative.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Zmień ćw iczenie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current exercise card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Obecne ćwiczenie:',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.exercise.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.exercise.details,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input field (matching mockup)
            TextField(
              controller: _controller,
              enabled: !_isLoading,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Np. Zmień dzisiejszy trening na łatwiejszy...',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),

            const SizedBox(height: 16),

            // Submit button (matching mockup)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Zatwierdź zmianę',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Alternatives list
            if (_alternatives != null && _alternatives!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Proponowane alternatywy:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _alternatives!.length,
                  itemBuilder: (context, index) {
                    final alt = _alternatives![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _selectAlternative(alt),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alt.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alt.details,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (alt.tips != null && alt.tips!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    alt.tips!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
