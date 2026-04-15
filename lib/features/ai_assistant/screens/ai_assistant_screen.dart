import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/cubit/home_cubit.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AiAssistantCubit(),
      child: const AiAssistantView(),
    );
  }
}

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final Color primaryColor = const Color(0xFF2B7CEE);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF101822);
  final Color textDark = const Color(0xFF111418);
  final Color textGrey = const Color(0xFF617289);

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _textController.text;
    if (message.trim().isEmpty) return;

    context.read<AiAssistantCubit>().sendMessage(message);
    _textController.clear();
    _focusNode.requestFocus();
  }

  void _sendSuggestion(String suggestion) {
    context.read<AiAssistantCubit>().sendSuggestion(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF1A2737) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey[200]!;

    final authState = context.watch<AuthCubit>().state;
    final photoUrl = authState.user?.photoUrl;

    return BlocConsumer<AiAssistantCubit, AiAssistantState>(
      listener: (context, state) {
        _scrollToBottom();
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () => context.read<AiAssistantCubit>().clearError(),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context, textColor, borderColor),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isLoading) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: _buildTypingIndicator(cardColor),
                        );
                      }
                      final message = state.messages[index];
                      final showSpacing = index > 0;
                      return Padding(
                        padding: EdgeInsets.only(top: showSpacing ? 24 : 0),
                        child: message.role == MessageRole.user
                            ? _buildUserMessage(message.content, photoUrl)
                            : _buildAiMessage(message.content, cardColor, textColor),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSuggestions(isDarkMode, state.isLoading),
                      _buildComposer(cardColor, textColor, borderColor, isDarkMode, state.isLoading, photoUrl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Color textColor, Color borderColor) {
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scaffoldBgColor.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.read<HomeCubit>().setTab(0),
            child: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "iMate AI",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "ACTIVE",
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<AiAssistantCubit>().clearChat(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh, color: primaryColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(String text, Color cardColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.smart_toy, color: primaryColor, size: 16),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text("iMate AI", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: textGrey)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.manrope(fontSize: 14, color: textColor, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildUserMessage(String text, String? photoUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 40),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Text("You", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: textGrey)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.zero,
                  ),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.manrope(fontSize: 14, color: Colors.white, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 16,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : const NetworkImage("https://i.pravatar.cc/150?img=12"),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(Color cardColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.smart_toy, color: primaryColor, size: 16),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.zero,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: _TypingDots(color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildSuggestions(bool isDarkMode, bool isLoading) {
    final suggestions = [
      {"icon": Icons.restaurant, "text": "Suggest a healthy dinner"},
      {"icon": Icons.account_balance_wallet, "text": "Check my budget"},
      {"icon": Icons.lightbulb, "text": "Turn off living room lights"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: isLoading ? null : () => _sendSuggestion(s['text'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Opacity(
              opacity: isLoading ? 0.5 : 1.0,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(s['icon'] as IconData, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      s['text'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildComposer(Color cardColor, Color textColor, Color borderColor, bool isDarkMode, bool isLoading, String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const NetworkImage("https://i.pravatar.cc/150?img=12"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : const Color(0xFFF0F2F4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: !isLoading,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: isLoading ? "Waiting for response..." : "Ask me anything...",
                          hintStyle: GoogleFonts.manrope(color: textGrey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: GoogleFonts.manrope(color: textColor),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: textGrey),
                    onPressed: isLoading ? null : () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: isLoading ? null : _sendMessage,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isLoading ? Colors.grey : primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isLoading ? Icons.hourglass_empty : Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated typing dots indicator
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < _controllers.length; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _controllers[i].forward().then((_) {
            if (mounted) _controllers[i].reverse();
          });
        }
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

