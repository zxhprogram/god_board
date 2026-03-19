import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:go_router/go_router.dart';

class ShellLayout extends StatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  bool expanded = false;

  NavigationItem buildButton(
    String text,
    IconData icon, {
    required String path,
    bool isSelected = false,
  }) {
    return NavigationItem(
      label: Text(text),
      selectedStyle: const ButtonStyle.primaryIcon(),
      selected: isSelected,
      onChanged: (selected) {
        if (selected) {
          context.go(path);
        }
      },
      child: Icon(icon),
    );
  }

  NavigationGroup buildLabel(String label, List<Widget> children) {
    return NavigationGroup(
      labelAlignment: Alignment.centerLeft,
      label: Text(label).semiBold.muted.xSmall,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            backgroundColor: theme.colorScheme.accent.withValues(alpha: 0.4),
            labelType: NavigationLabelType.expanded,
            labelPosition: NavigationLabelPosition.end,
            alignment: NavigationRailAlignment.start,
            expandedSize: 250,
            expanded: expanded,
            header: [
              Builder(
                builder: (context) {
                  return NavigationSlot(
                    leading: IconContainer(
                      backgroundColor: Colors.blue,
                      icon: const Icon(LucideIcons.radioTower).iconMedium,
                    ),
                    title: const Text('God Board').medium.small,
                    subtitle: const Text('中国铁塔视联平台').xSmall.normal,
                    trailing: const Icon(LucideIcons.chevronsUpDown).iconSmall,
                    onPressed: () {
                      showDropdown(
                        context: context,
                        anchorAlignment: AlignmentDirectional.centerEnd,
                        alignment: AlignmentDirectional.centerStart,
                        offset: const Offset(10, 0),
                        builder: (context) {
                          return DropdownMenu(
                            children: [
                              MenuButton(
                                leading: const Icon(Icons.settings),
                                child: const Text('k8s服务器配置'),
                                onPressed: (ctx) {
                                  context.go('/settings');
                                },
                              ),
                              MenuButton(
                                leading: const Icon(Icons.settings),
                                child: const Text('nacos服务器配置'),
                                onPressed: (ctx) {
                                  context.go('/nacosSettings');
                                },
                              ),
                              MenuButton(
                                leading: const Icon(Icons.settings),
                                child: const Text('Newland Gateway'),
                                onPressed: (ctx) {
                                  context.go('/newland-gateway');
                                },
                              ),
                              MenuButton(
                                leading: const Icon(Icons.storage),
                                child: const Text('Storage Config'),
                                onPressed: (ctx) {
                                  context.go('/storage-config');
                                },
                              ),
                              MenuButton(
                                leading: const Icon(Icons.cached),
                                child: const Text('Cache Metadata'),
                                onPressed: (ctx) {
                                  context.go('/cache-metadata-config');
                                },
                              ),
                              MenuButton(
                                leading: const Icon(Icons.key),
                                child: const Text('Industry Mongo Auth'),
                                onPressed: (ctx) {
                                  context.go('/industry-mongo-auth-config');
                                },
                              ),
                              const MenuDivider(),
                              MenuButton(
                                leading: const Icon(Icons.person),
                                child: const Text('Profile'),
                                onPressed: (ctx) {},
                              ),
                              MenuButton(
                                leading: const Icon(Icons.logout),
                                child: const Text('Logout'),
                                onPressed: (ctx) {},
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
            footer: [
              NavigationSlot(
                leading: Avatar(
                  size: 32,
                  initials: 'SU',
                  backgroundColor: Colors.green.shade800,
                ),
                title: const Text('sunarya-thito').medium.small,
                subtitle: const Text('m@gmail.com').xSmall.normal,
                trailing: const Icon(LucideIcons.chevronsUpDown).iconSmall,
                onPressed: () {},
              ),
            ],
            children: [
              buildLabel('Menu', [
                buildButton(
                  'Home',
                  Icons.home,
                  path: '/',
                  isSelected: location == '/',
                ),
                buildButton(
                  'K8S',
                  SimpleIcons.kubernetes,
                  path: '/k8s',
                  isSelected: location.startsWith('/k8s'),
                ),
                buildButton(
                  'Nacos',
                  Icons.cloud,
                  path: '/nacos',
                  isSelected: location.startsWith('/nacos'),
                ),
                buildButton(
                  '自动巡检',
                  LucideIcons.clipboardCheck,
                  path: '/inspection',
                  isSelected: location == '/inspection',
                ),
                buildButton(
                  '配置洞察',
                  LucideIcons.lightbulb,
                  path: '/config-insight',
                  isSelected: location == '/config-insight',
                ),
              ]),
            ],
          ),
          const VerticalDivider(),
          // 主内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton.ghost(
                    onPressed: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    icon: const Icon(LucideIcons.panelLeft),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
