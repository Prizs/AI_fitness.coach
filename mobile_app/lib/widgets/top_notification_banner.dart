import 'dart:async';
import 'package:flutter/material.dart';

class NotificationPayload {
  final String title;
  final String message;
  final String senderRole;
  final VoidCallback? onTap;

  NotificationPayload({
    required this.title,
    required this.message,
    this.senderRole = 'trainer',
    this.onTap,
  });
}

class TopNotificationBanner {
  static final GlobalKey<TopNotificationBannerState> bannerKey = GlobalKey<TopNotificationBannerState>();

  static void show({
    required String title,
    required String message,
    String senderRole = 'trainer',
    VoidCallback? onTap,
  }) {
    bannerKey.currentState?.displayNotification(
      NotificationPayload(
        title: title,
        message: message,
        senderRole: senderRole,
        onTap: onTap,
      ),
    );
  }
}

class TopNotificationBannerWrapper extends StatefulWidget {
  final Widget child;

  const TopNotificationBannerWrapper({super.key, required this.child});

  @override
  State<TopNotificationBannerWrapper> createState() => TopNotificationBannerState();
}

class TopNotificationBannerState extends State<TopNotificationBannerWrapper>
    with SingleTickerProviderStateMixin {
  NotificationPayload? _currentPayload;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void displayNotification(NotificationPayload payload) {
    _dismissTimer?.cancel();
    setState(() {
      _currentPayload = payload;
    });
    _animController.forward(from: 0.0);

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      dismiss();
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentPayload = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentPayload != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! < -5) {
                      dismiss();
                    }
                  },
                  onTap: () {
                    final cb = _currentPayload?.onTap;
                    dismiss();
                    if (cb != null) cb();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101B2D).withOpacity(0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1FAE87),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1FAE87).withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF1FAE87),
                                child: Icon(
                                  _currentPayload!.senderRole == 'trainer' ? Icons.sports : Icons.person,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF101B2D), width: 1.5),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _currentPayload!.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Text(
                                      'Ahora',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _currentPayload!.message,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                            onPressed: dismiss,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
