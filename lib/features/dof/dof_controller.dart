import 'package:camera_assistant/features/dof/dof_state.dart';
import 'package:camera_assistant/features/dof/dof_use_case.dart';

class DofController {
  const DofController({
    this.useCase = const DofUseCase(),
  });

  final DofUseCase useCase;

  DofCalculationState calculate(
    DofInput input, {
    bool live = false,
  }) {
    return useCase.calculate(input, live: live);
  }
}
