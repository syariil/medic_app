import 'package:flutter/material.dart';
import '../error_handler.dart';
import '../theme/app_theme.dart';

/// Abstract base class for all input screens
/// Handles common form operations and state management
abstract class InputScreenBase<T> extends StatefulWidget {
  final T? entity;
  const InputScreenBase({this.entity});

  @override
  State<InputScreenBase<T>> createState() => _InputScreenBaseState<T>();
}

/// Abstract base state for input screens
/// Generic T represents the entity type being edited
/// W represents the widget type that extends InputScreenBase
abstract class _InputScreenBaseState<T, W extends InputScreenBase<T>>
    extends State<W> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  bool get isSaving => _isSaving;
  bool get isEdit => widget.entity != null;

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  /// Override to dispose any text controllers or other resources
  @protected
  void disposeControllers();

  /// Override to build the form widget(s)
  /// Called from build() method
  @protected
  Widget buildForm();

  /// Override to save/update the entity in database
  @protected
  Future<void> saveEntity();

  /// Override to get success message
  String getSuccessMessage() =>
      isEdit ? 'Data berhasil diperbarui' : 'Data berhasil disimpan';

  /// Override to handle navigation after save
  void handleNavigateAfterSave() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  /// Submit form with validation
  @protected
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await saveEntity();

      if (!mounted) return;
      showSuccessSnackBar(getSuccessMessage());
      handleNavigateAfterSave();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorHandler.getReadableError(e);
      showErrorSnackBar('Gagal menyimpan: $errorMessage');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Show success SnackBar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Show error SnackBar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(key: formKey, child: buildForm()),
      ),
    );
  }
}
