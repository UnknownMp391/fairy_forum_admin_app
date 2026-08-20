import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/utils/sentry_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

void showErrorSnackBar(
  ScaffoldMessengerState messenger,
  Object error, {
  String? prefix,
}) {
  final detail = '$error';
  final text = (prefix == null || prefix.isEmpty) ? detail : '$prefix$detail';
  final isNoByok = error is ApiException && error.errorCode == 'no_byok';
  reportError(error, context: 'snackbar');
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(
          label: isNoByok ? '配置 BYOK' : '复制详情',
          onPressed: isNoByok
              ? () => messenger.context.push('/settings/byok')
              : () => Clipboard.setData(ClipboardData(text: detail)),
        ),
      ),
    );
}

class AnimatedLoadSwitch extends StatelessWidget {
  final bool hasData;
  final WidgetBuilder dataBuilder;
  final WidgetBuilder nonDataBuilder;

  const AnimatedLoadSwitch({
    super.key,
    required this.hasData,
    required this.dataBuilder,
    required this.nonDataBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: hasData
          ? KeyedSubtree(
              key: const ValueKey('data'),
              child: dataBuilder(context),
            )
          : KeyedSubtree(
              key: const ValueKey('non-data'),
              child: nonDataBuilder(context),
            ),
    );
  }
}

class LoadErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  final String? context;

  const LoadErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    reportError(error, context: this.context ?? 'load-error-view');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              '加载失败: $error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: '$error')),
              child: const Text('复制详情'),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  final String? context;

  const SectionErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    reportError(error, context: this.context ?? 'section-error');
    final greyStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: Colors.grey);
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '加载失败: $error',
          style: greyStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('重试')),
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: '$error')),
              child: const Text('复制详情'),
            ),
          ],
        ),
      ],
    );
  }
}
