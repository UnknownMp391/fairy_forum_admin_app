import 'package:cached_network_image/cached_network_image.dart';
import 'package:fairy_forum_admin_app/dto/routes/user.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManagementUserListPage extends HookConsumerWidget {
  const ManagementUserListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userListFuture = useMemoized(() async {
      final client = ref.read(apiClientProvider);
      return await client.listUsers();
    });
    final userListSnapshot = useFuture(userListFuture);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final idTextTheme = textTheme.labelMedium!.copyWith(color: Colors.grey);
    final emailTextTheme = textTheme.labelSmall!.copyWith(color: Colors.grey);
    final banLabelTextTheme = textTheme.labelLarge!.copyWith(
      color: colorScheme.error,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('用户 ')),
      body: Center(
        child: userListSnapshot.hasData
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: ListView.separated(
                    itemCount: userListSnapshot.data?.length ?? 0,
                    itemBuilder: (ctx, i) {
                      final user = userListSnapshot.data![i];

                      final avatarHeroTag = 'user ${user.id}';

                      return InkWell(
                        onTap: () {
                          context.push(
                            '/management/user/${Uri.encodeComponent(user.id)}',
                            extra: ManagementUserDetailPageExtra(
                              name: user.name,
                              avatarUrl: user.avatarUrl,
                              age: user.age,
                              bio: user.bio,
                              createdAt: user.createdAt,
                              email: user.email,
                              gender: user.gender,
                              isBanned: user.isBanned,
                              heroTag: avatarHeroTag,
                            ),
                          );
                        },
                        child: ListTile(
                          leading: SizedBox(
                            width: 64,
                            height: 64,
                            child: Hero(
                              tag: avatarHeroTag,
                              child: Material(
                                child: CachedNetworkImage(
                                  imageUrl: user.avatarUrl,
                                ),
                              ),
                            ),
                          ),
                          title: SizedBox(
                            height: 64,
                            child: Column(
                              crossAxisAlignment: .start,
                              mainAxisAlignment: .start,
                              children: [
                                Text(
                                  user.name,
                                  style: textTheme.labelLarge,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user.id,
                                  style: idTextTheme,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                                Text(
                                  user.email,
                                  style: emailTextTheme,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                              ],
                            ),
                          ),
                          trailing: user.isBanned
                              ? Text('已封禁', style: banLabelTextTheme)
                              : null,
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const Divider(),
                  ),
                ),
              )
            : userListSnapshot.hasError
            ? Text('Error: ${userListSnapshot.error!.toString()}')
            : const CircularProgressIndicator(),
      ),
    );
  }
}
