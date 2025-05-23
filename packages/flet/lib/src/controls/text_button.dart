import 'package:flutter/material.dart';

import '../flet_control_backend.dart';
import '../models/control.dart';
import '../utils/buttons.dart';
import '../utils/icons.dart';
import '../utils/launch_url.dart';
import '../utils/others.dart';
import 'create_control.dart';
import 'cupertino_button.dart';
import 'cupertino_dialog_action.dart';
import 'flet_store_mixin.dart';

class TextButtonControl extends StatefulWidget {
  final Control? parent;
  final Control control;
  final List<Control> children;
  final bool parentDisabled;
  final bool? parentAdaptive;
  final FletControlBackend backend;

  const TextButtonControl(
      {super.key,
      this.parent,
      required this.control,
      required this.children,
      required this.parentDisabled,
      required this.parentAdaptive,
      required this.backend});

  @override
  State<TextButtonControl> createState() => _TextButtonControlState();
}

class _TextButtonControlState extends State<TextButtonControl>
    with FletStoreMixin {
  late final FocusNode _focusNode;
  String? _lastFocusValue;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    widget.backend.triggerControlEvent(
        widget.control.id, _focusNode.hasFocus ? "focus" : "blur");
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Button build: ${widget.control.id}");

    return withPagePlatform((context, platform) {
      bool? adaptive =
          widget.control.attrBool("adaptive") ?? widget.parentAdaptive;
      if (adaptive == true &&
          (platform == TargetPlatform.iOS ||
              platform == TargetPlatform.macOS)) {
        return widget.control.name == "action" &&
                (widget.parent?.type == "alertdialog" ||
                    widget.parent?.type == "cupertinoalertdialog")
            ? CupertinoDialogActionControl(
                control: widget.control,
                parentDisabled: widget.parentDisabled,
                parentAdaptive: adaptive,
                children: widget.children,
                backend: widget.backend)
            : CupertinoButtonControl(
                control: widget.control,
                parentDisabled: widget.parentDisabled,
                parentAdaptive: adaptive,
                children: widget.children,
                backend: widget.backend);
      }

      String text = widget.control.attrString("text", "")!;
      var clipBehavior = parseClip(widget.control.attrString("clipBehavior"));
      IconData? icon = parseIcon(widget.control.attrString("icon"));
      Color? iconColor = widget.control.attrColor("iconColor", context);
      var contentCtrls =
          widget.children.where((c) => c.name == "content" && c.isVisible);
      bool onHover = widget.control.attrBool("onHover", false)!;
      bool onLongPress = widget.control.attrBool("onLongPress", false)!;
      String url = widget.control.attrString("url", "")!;
      String? urlTarget = widget.control.attrString("urlTarget");
      bool autofocus = widget.control.attrBool("autofocus", false)!;
      bool disabled = widget.control.isDisabled || widget.parentDisabled;

      Function()? onPressed = !disabled
          ? () {
              debugPrint("Button ${widget.control.id} clicked!");
              if (url != "") {
                openWebBrowser(url, webWindowName: urlTarget);
              }
              widget.backend.triggerControlEvent(widget.control.id, "click");
            }
          : null;

      Function()? onLongPressHandler = onLongPress && !disabled
          ? () {
              debugPrint("Button ${widget.control.id} long pressed!");
              widget.backend
                  .triggerControlEvent(widget.control.id, "long_press");
            }
          : null;

      Function(bool)? onHoverHandler = onHover && !disabled
          ? (state) {
              debugPrint("Button ${widget.control.id} hovered!");
              widget.backend.triggerControlEvent(
                  widget.control.id, "hover", state.toString());
            }
          : null;

      TextButton? button;

      var theme = Theme.of(context);

      var style = parseButtonStyle(Theme.of(context), widget.control, "style",
          defaultForegroundColor: theme.colorScheme.primary,
          defaultBackgroundColor: Colors.transparent,
          defaultOverlayColor: Colors.transparent,
          defaultShadowColor: Colors.transparent,
          defaultSurfaceTintColor: Colors.transparent,
          defaultElevation: 0,
          defaultPadding: const EdgeInsets.all(8),
          defaultBorderSide: BorderSide.none,
          defaultShape: theme.useMaterial3
              ? const StadiumBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)));

      if (icon != null) {
        button = TextButton.icon(
            autofocus: autofocus,
            focusNode: _focusNode,
            onPressed: onPressed,
            onLongPress: onLongPressHandler,
            onHover: onHoverHandler,
            style: style,
            clipBehavior: clipBehavior,
            icon: Icon(
              icon,
              color: iconColor,
            ),
            label: Text(text));
      } else if (contentCtrls.isNotEmpty) {
        button = TextButton(
            autofocus: autofocus,
            focusNode: _focusNode,
            onPressed: onPressed,
            onLongPress: onLongPressHandler,
            onHover: onHoverHandler,
            clipBehavior: clipBehavior,
            style: style,
            child:
                createControl(widget.control, contentCtrls.first.id, disabled));
      } else {
        button = TextButton(
            autofocus: autofocus,
            focusNode: _focusNode,
            style: style,
            onPressed: onPressed,
            onLongPress: onLongPressHandler,
            onHover: onHoverHandler,
            clipBehavior: clipBehavior,
            child: Text(text));
      }

      var focusValue = widget.control.attrString("focus");
      if (focusValue != null && focusValue != _lastFocusValue) {
        _lastFocusValue = focusValue;
        _focusNode.requestFocus();
      }

      return constrainedControl(context, button, widget.parent, widget.control);
    });
  }
}
