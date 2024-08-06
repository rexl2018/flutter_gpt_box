part of 'home.dart';

class _ChatPage extends StatefulWidget {
  const _ChatPage();

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: _buildChat(),
      bottomNavigationBar: const _HomeBottom(isHome: false),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return AutoHide(
      key: _chatFabAutoHideKey,
      controller: _chatScrollCtrl,
      direction: AxisDirection.right,
      offset: 75,
      child: ListenBuilder(
        listenable: _chatFabRN,
        builder: () {
          final valid = _chatScrollCtrl.positions.length == 1 &&
              _chatScrollCtrl.position.hasContentDimensions &&
              _chatScrollCtrl.position.maxScrollExtent > 0;
          return AnimatedSwitcher(
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween<double>(begin: 0.5, end: 0).animate(animation),
                child: child,
              );
            },
            duration: _durationShort,
            switchInCurve: Curves.fastEaseInToSlowEaseOut,
            switchOutCurve: Curves.fastEaseInToSlowEaseOut,
            child: valid ? _buildFABBtn() : UIs.placeholder,
          );
        },
      ),
    );
  }

  Widget _buildFABBtn() {
    final up =
        _chatScrollCtrl.offset >= _chatScrollCtrl.position.maxScrollExtent / 2;
    final icon = up ? MingCute.up_fill : MingCute.down_fill;
    return FloatingActionButton(
      key: ValueKey(up),
      mini: true,
      onPressed: () async {
        if (!_chatScrollCtrl.hasClients) return;
        if (up) {
          await _chatScrollCtrl.animateTo(
            0,
            duration: _durationMedium,
            curve: Curves.easeInOut,
          );
        } else {
          await _chatScrollCtrl.animateTo(
            _chatScrollCtrl.position.maxScrollExtent,
            duration: _durationMedium,
            curve: Curves.easeInOut,
          );
        }
        _chatFabRN.notify();
      },
      child: Icon(icon),
    );
  }

  Widget _buildChat() {
    var switchDirection = SwitchDirection.next;
    final scrollSwitchChat = Stores.setting.scrollSwitchChat.fetch();

    final child = ListenBuilder(
      listenable: _chatRN,
      builder: () {
        final item = _curChat?.items;
        if (item == null) return UIs.placeholder;
        final listView = ListView.builder(
          key: Key(_curChatId),
          controller: _chatScrollCtrl,
          padding: const EdgeInsets.all(7),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: item.length,
          itemBuilder: (_, index) {
            return _buildChatItem(item, index);
          },
        );
        if (!scrollSwitchChat) return listView;
        return AnimatedSwitcher(
          duration: _durationShort,
          switchInCurve: Easing.standardDecelerate,
          switchOutCurve: Easing.standardDecelerate,
          transitionBuilder: (child, animation) => SlideTransitionX(
            position: animation,
            direction: switchDirection == SwitchDirection.next
                ? AxisDirection.up
                : AxisDirection.down,
            child: child,
          ),
          child: listView,
        );
      },
    );

    if (!scrollSwitchChat) return child;

    return SwitchIndicator(
      onSwitchPage: (direction) async {
        switchDirection = direction;
        switch (direction) {
          case SwitchDirection.previous:
            _switchPreviousChat();
            break;
          case SwitchDirection.next:
            _switchNextChat();
            break;
        }
      },
      child: child,
    );
  }

  Widget _buildChatItem(List<ChatHistoryItem> chatItems, int idx) {
    final chatItem = chatItems[idx];
    final node = _chatItemRNMap.putIfAbsent(chatItem.id, () => RNode());

    final title = switch (chatItem.role) {
      // User & System msgs have no loading status
      ChatRole.user || ChatRole.system => ChatRoleTitle(
          role: chatItem.role,
          loading: false,
        ),
      ChatRole.tool || ChatRole.assist => ListenBuilder(
          listenable: _loadingChatIdRN,
          builder: () {
            final isWorking = _loadingChatIds.contains(chatItem.id);
            return ChatRoleTitle(role: chatItem.role, loading: isWorking);
          },
        ),
    };

    final child = Padding(
      padding: const EdgeInsets.only(top: 11, left: 11, right: 11, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          UIs.height13,
          ListenBuilder(
            listenable: node,
            builder: () => ChatHistoryContentView(chatItem: chatItem),
          ).paddingSymmetric(horizontal: 2),
          UIs.height13,
        ],
      ),
    );

    return _isWide.listenVal(
      (wide) {
        final content = InkWell(
          borderRadius: BorderRadius.circular(13),
          onLongPress: wide
              ? null
              : () {
                  final funcs = _buildChatItemFuncs(chatItems, chatItem);
                  context.showRoundDialog(
                    contentPadding: const EdgeInsets.all(11),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: funcs,
                      ),
                    ),
                  );
                },
          child: child,
        );
        if (!wide) return content;

        final hovers = _buildChatItemHovers(chatItems, chatItem);
        return Hover(
          builder: (bool isHovered) {
            final hover = AnimatedContainer(
              duration: Durations.medium1,
              curve: Curves.fastEaseInToSlowEaseOut,
              width: isHovered ? hovers.length * 33.7 : 0,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: hovers,
                ),
              ),
            );
            return Stack(
              children: [
                content,
                Align(alignment: Alignment.topRight, child: hover),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildChatItemHovers(
    List<ChatHistoryItem> chatItems,
    ChatHistoryItem chatItem,
  ) {
    final replayEnabled = chatItem.role.isUser;
    const size = 19.0;

    return [
      Btn.icon(
        onTap: () {
          context.pop();
          _MarkdownCopyPage.go(context, chatItem);
        },
        text: l10n.freeCopy,
        icon: const Icon(BoxIcons.bxs_crop, size: size),
      ),
      if (replayEnabled)
        ListenBuilder(
          listenable: _sendBtnRN,
          builder: () {
            final isWorking = _loadingChatIds.contains(_curChatId);
            if (isWorking) return UIs.placeholder;
            return Btn.icon(
              onTap: () {
                context.pop();
                _onTapReplay(context, _curChatId, chatItem);
              },
              text: l10n.replay,
              icon: const Icon(MingCute.refresh_4_line, size: size),
            );
          },
        ),
      if (replayEnabled)
        Btn.icon(
          onTap: () {
            context.pop();
            _onTapEditMsg(context, chatItem);
          },
          text: libL10n.edit,
          icon: const Icon(Icons.edit, size: size),
        ),
      Btn.icon(
        onTap: () {
          context.pop();
          _onTapDelChatItem(context, chatItems, chatItem);
        },
        text: l10n.delete,
        icon: const Icon(Icons.delete, size: size),
      ),
      Btn.icon(
        onTap: () {
          context.pop();
          Pfs.copy(chatItem.toMarkdown);
        },
        text: libL10n.copy,
        icon: const Icon(MingCute.copy_2_fill, size: size),
      ),
    ];
  }

  List<Widget> _buildChatItemFuncs(
    List<ChatHistoryItem> chatItems,
    ChatHistoryItem chatItem,
  ) {
    final replayEnabled = chatItem.role.isUser;

    return [
      Btn.tile(
        onTap: () {
          context.pop();
          _MarkdownCopyPage.go(context, chatItem);
        },
        text: l10n.freeCopy,
        icon: const Icon(BoxIcons.bxs_crop),
      ),
      if (replayEnabled)
        ListenBuilder(
          listenable: _sendBtnRN,
          builder: () {
            final isWorking = _loadingChatIds.contains(_curChatId);
            if (isWorking) return UIs.placeholder;
            return Btn.tile(
              onTap: () {
                context.pop();
                _onTapReplay(context, _curChatId, chatItem);
              },
              text: l10n.replay,
              icon: const Icon(MingCute.refresh_4_line),
            );
          },
        ),
      if (replayEnabled)
        Btn.tile(
          onTap: () {
            context.pop();
            _onTapEditMsg(context, chatItem);
          },
          text: libL10n.edit,
          icon: const Icon(Icons.edit),
        ),
      Btn.tile(
        onTap: () {
          context.pop();
          _onTapDelChatItem(context, chatItems, chatItem);
        },
        text: l10n.delete,
        icon: const Icon(Icons.delete),
      ),
      Btn.tile(
        onTap: () {
          context.pop();
          Pfs.copy(chatItem.toMarkdown);
        },
        text: libL10n.copy,
        icon: const Icon(MingCute.copy_2_fill),
      ),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
