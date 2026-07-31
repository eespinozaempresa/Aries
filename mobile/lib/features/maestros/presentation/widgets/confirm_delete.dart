import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';

/// Muestra un diálogo de confirmación y, si se acepta, ejecuta [onDelete].
/// Si el backend rechaza el borrado (por ejemplo, por tener operaciones
/// asociadas), muestra el mensaje recibido en un snackbar.
/// Retorna `true` si el elemento fue eliminado.
Future<bool> confirmAndDelete(
  BuildContext context, {
  required String itemName,
  required Future<Either<ApiException, void>> Function() onDelete,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar'),
      content: Text('¿Eliminar "$itemName"? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar')),
      ],
    ),
  );
  if (confirmed != true) return false;
  if (!context.mounted) return false;

  final result = await onDelete();
  return result.fold(
    (e) async {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
      return false;
    },
    (_) async => true,
  );
}
