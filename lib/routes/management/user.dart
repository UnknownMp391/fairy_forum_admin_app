import 'package:cached_network_image/cached_network_image.dart';
import 'package:fairy_forum_admin_app/api/types/users.dart';
import 'package:fairy_forum_admin_app/components/copyable.dart';
import 'package:fairy_forum_admin_app/dto/routes/user.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementUserDetailPage extends HookConsumerWidget {
  final String id;
  final Object? extra;

  const ManagementUserDetailPage({super.key, required this.id, this.extra});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reloadKey = useState(UniqueKey());

    final isProcessing = useState(false);

    final snapshot = useFuture(
      useMemoized(() async {
        final client = ref.read(apiClientProvider);
        return UserListItem.fromJson((await client.findUser('id', id))[0]!);
      }, [reloadKey.value]),
    );

    final preload = extra is ManagementUserDetailPageExtra
        ? extra as ManagementUserDetailPageExtra
        : null;

    final name = snapshot.data?.name ?? preload?.name;
    final createdAt = snapshot.data?.createdAt ?? preload?.createdAt;
    final age = snapshot.data?.age ?? preload?.age;
    final avatarUrl = snapshot.data?.avatarUrl ?? preload?.avatarUrl;
    final bio = snapshot.data?.bio ?? preload?.bio;
    final email = snapshot.data?.email ?? preload?.email;
    final gender = snapshot.data?.gender ?? preload?.gender;
    final isBanned = snapshot.data?.isBanned ?? preload?.isBanned;
    final avatarHeroTag = preload?.heroTag;

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final infoLabelTextTheme = textTheme.labelLarge!.copyWith(
      color: Colors.grey,
    );

    return Scaffold(
      appBar: AppBar(title: Text(name ?? '加载中...')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 32.0,
                    right: 8.0,
                    left: 8.0,
                    bottom: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        crossAxisAlignment: .center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: Hero(
                              tag: avatarHeroTag ?? id,
                              child: Material(
                                child: avatarUrl == null
                                    ? null
                                    : CachedNetworkImage(imageUrl: avatarUrl),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: .start,
                              crossAxisAlignment: .start,
                              children: [
                                CopyableWidget(
                                  value: name ?? '',
                                  copyOnLongPress: true,
                                  withInk: true,
                                  child: Text(
                                    name ?? '',
                                    style: textTheme.titleLarge,
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CopyableWidget(
                                  value: id,
                                  copyOnLongPress: true,
                                  withInk: true,
                                  child: Text(
                                    id,
                                    style: textTheme.bodyMedium!.copyWith(
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isBanned ?? false)
                            Align(
                              alignment: .centerEnd,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                ),
                                child: Text(
                                  '已封禁',
                                  style: textTheme.labelLarge!.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(bio ?? ''),
                      const SizedBox(height: 16),
                      ListView(
                        shrinkWrap: true,
                        children: [
                          Row(
                            children: [
                              Text('E-Mail:', style: infoLabelTextTheme),
                              const SizedBox(width: 4),
                              CopyableWidget(
                                value: email ?? '',
                                copyOnLongPress: true,
                                withInk: true,
                                child: Text(email ?? ''),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('年龄 (出生日期):', style: infoLabelTextTheme),
                              const SizedBox(width: 4),
                              Text(age == null ? '' : '$age'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('性别:', style: infoLabelTextTheme),
                              const SizedBox(width: 4),
                              Text(gender == null ? '' : '$gender'),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                      if ((!snapshot.hasData && !snapshot.hasError) ||
                          isProcessing.value)
                        const LinearProgressIndicator(),
                      const Divider(),
                      if (snapshot.hasData) ...[
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () async {
                                if (isBanned != null) {
                                  try {
                                    isProcessing.value = true;
                                    final client = ref.read(apiClientProvider);
                                    if (isBanned) {
                                      await client.unbanUser(id);
                                    } else {
                                      await client.banUser(id);
                                    }
                                    reloadKey.value = UniqueKey();
                                  } finally {
                                    isProcessing.value = false;
                                  }
                                }
                              },
                              child: Text(isBanned ?? false ? '解禁' : '封禁'),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: const Text('这里是帖子列表不过没有写...')),
            ],
          ),
        ),
      ),
    );
  }
}
