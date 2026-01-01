import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/tab_config.dart';
import '../viewmodels/bottom_nav_viewmodel.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ScrollController _scrollController = ScrollController();
  bool canScrollLeft = false;
  bool canScrollRight = true;

  late final List<TabConfig> tabs;

  @override
  void initState() {
    super.initState();
    tabs = Tabs.all;

    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  void _updateArrows() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    setState(() {
      canScrollLeft = pos.pixels > pos.minScrollExtent + 2;
      canScrollRight = pos.pixels < pos.maxScrollExtent - 2;
    });
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.offset + offset;

    _scrollController.animateTo(
      target.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navVM = context.watch<BottomNavViewModel>();
    final selectedIndex = navVM.index;

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: tabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: _BottomBar(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onTap: (i) => context.read<BottomNavViewModel>().setIndex(i),
        scrollController: _scrollController,
        canScrollLeft: canScrollLeft,
        canScrollRight: canScrollRight,
        scrollBy: _scrollBy,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<TabConfig> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  final ScrollController scrollController;
  final bool canScrollLeft;
  final bool canScrollRight;
  final void Function(double offset) scrollBy;

  const _BottomBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    required this.scrollController,
    required this.canScrollLeft,
    required this.canScrollRight,
    required this.scrollBy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          height: 74,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, -2),
                color: Colors.black.withOpacity(0.08),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView.separated(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  itemCount: tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    final selected = index == selectedIndex;

                    return GestureDetector(
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.blue.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: selected ? 35 : 25,
                              color: selected ? Colors.blue : Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: selected ? 90 : 0,
                                ),
                                child: AnimatedOpacity(
                                  opacity: selected ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    tab.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // left arrow overlay
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _ArrowOverlay(
                  visible: canScrollLeft,
                  alignment: Alignment.centerLeft,
                  icon: Icons.chevron_left,
                  onTap: () => scrollBy(-200),
                ),
              ),

              // right arrow overlay
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _ArrowOverlay(
                  visible: canScrollRight,
                  alignment: Alignment.centerRight,
                  icon: Icons.chevron_right,
                  onTap: () => scrollBy(200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowOverlay extends StatelessWidget {
  final bool visible;
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowOverlay({
    required this.visible,
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
          width: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignment == Alignment.centerLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              end: alignment == Alignment.centerLeft
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
          child: Align(
            alignment: alignment,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  size: 26,
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
