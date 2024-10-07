import 'package:flutter/material.dart';

class ScrollingAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final Color textColor;
  final double height;

  ScrollingAppBar({
    Key? key,
    required this.backgroundColor,
    required this.textColor,
    this.height = kToolbarHeight,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  _ScrollingAppBarState createState() => _ScrollingAppBarState();
}

class _ScrollingAppBarState extends State<ScrollingAppBar> {
  late ScrollController _scrollController;
  final double _scrollSpeed = 50.0; // Adjust the scroll speed as needed

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start the scrolling animation after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() async {
    while (true) {
      double maxScrollExtent = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        maxScrollExtent,
        duration: Duration(seconds: (maxScrollExtent / _scrollSpeed).round()),
        curve: Curves.linear,
      );
      _scrollController.jumpTo(0);
    }
  }

  Widget _buildScrollingContent() {
    return Row(
      children: List.generate(20, (index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'EPISODE',
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 23,
                    letterSpacing: -3,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WE CREATE ENERGY HARVESTING FROM SENIOR',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w600
                  ),
                ),
                Text(
                  'MAKE SYNERGY WITH EPISODE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 50), // Space between repetitions
          ],
        );
      }),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: widget.backgroundColor,
      toolbarHeight: widget.height,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: _buildScrollingContent(),
      ),
    );
  }
}
