import 'package:fairy_forum_admin_app/utils/sentry_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PagedResult<T> {
  final List<T> items;
  final bool hasMore;

  const PagedResult({required this.items, required this.hasMore});
}

class PagedListView<T> extends HookWidget {
  final Future<PagedResult<T>> Function(int page) fetchPage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;
  final Object? resetKey;

  final ValueChanged<List<T>>? onItemsChanged;

  const PagedListView({
    super.key,
    required this.fetchPage,
    required this.itemBuilder,
    this.emptyText = '暂无数据',
    this.resetKey,
    this.onItemsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final items = useState<List<T>>(const []);
    final page = useState(1);
    final hasMore = useState(true);
    final initialLoading = useState(true);
    final loadingMore = useState(false);
    final error = useState<Object?>(null);
    final prevResetKey = useState<Object?>(resetKey);
    final fetchRef = useRef(fetchPage);
    fetchRef.value = fetchPage;

    if (prevResetKey.value != resetKey) {
      prevResetKey.value = resetKey;
      items.value = const [];
      page.value = 1;
      hasMore.value = true;
      error.value = null;
      initialLoading.value = true;
    }

    Future<void> load(int targetPage) async {
      try {
        final result = await fetchRef.value(targetPage);
        if (result.items.isNotEmpty) {
          items.value = [...items.value, ...result.items];
        }
        if (!result.hasMore || result.items.isEmpty) {
          hasMore.value = false;
        }
        page.value = targetPage + 1;
      } catch (e, st) {
        error.value = e;
        reportError(e, stackTrace: st, context: 'paged-list-load');
      } finally {
        initialLoading.value = false;
        loadingMore.value = false;
      }
    }

    useEffect(() {
      if (initialLoading.value) {
        load(1);
      }
      return null;
    }, [prevResetKey.value]);

    useEffect(() {
      void listener() {
        if (!controller.hasClients) return;
        if (loadingMore.value || !hasMore.value || initialLoading.value) {
          return;
        }
        final position = controller.position;
        if (position.pixels >= position.maxScrollExtent - 200) {
          loadingMore.value = true;
          load(page.value);
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onItemsChanged?.call(items.value);
      });
      return null;
    }, [items.value]);

    final textTheme = Theme.of(context).textTheme;
    final greyStyle = textTheme.labelMedium!.copyWith(color: Colors.grey);

    Widget footer;
    if (error.value != null && items.value.isNotEmpty) {
      footer = Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: ${error.value}', style: greyStyle),
              TextButton(
                onPressed: () {
                  error.value = null;
                  loadingMore.value = true;
                  load(page.value);
                },
                child: const Text('重试'),
              ),
              OutlinedButton(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: '${error.value}')),
                child: const Text('复制详情'),
              ),
            ],
          ),
        ),
      );
    } else if (hasMore.value) {
      footer = const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else {
      footer = Padding(
        padding: const EdgeInsets.all(12),
        child: Center(child: Text('没有更多了', style: greyStyle)),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: initialLoading.value
            ? const CircularProgressIndicator()
            : error.value != null && items.value.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${error.value}'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          error.value = null;
                          initialLoading.value = true;
                          load(1);
                        },
                        child: const Text('重试'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: '${error.value}'),
                        ),
                        child: const Text('复制详情'),
                      ),
                    ],
                  ),
                ),
              )
            : items.value.isEmpty
            ? Text(emptyText)
            : ListView.separated(
                controller: controller,
                itemCount: items.value.length + 1,
                itemBuilder: (context, index) {
                  if (index < items.value.length) {
                    return itemBuilder(context, items.value[index]);
                  }
                  return footer;
                },
                separatorBuilder: (_, _) => const Divider(height: 1),
              ),
      ),
    );
  }
}
