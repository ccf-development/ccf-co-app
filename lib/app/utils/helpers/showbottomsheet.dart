import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

onShowCustomCupertinoModalSheet({
  @required BuildContext? context,
  Widget? icon,
  Function? onTap,
  Widget? dynamicTitle,
  @required String? title,
  bool? isLeading = false,
  GestureTapCallback? onLeading,
  @required Widget? child,
  Widget? trailing,
  bool? isShowAppBar = true,
  bool? isNoIcon = false,
  bool? isBackgroundColor = false,
  Color? backgroundColor,
  Color? isColorsAppBar,
  bool? isUseRootNavigation = true,
  Color? titleColors,
  Color? backGroundColor,
}) {
  return CupertinoScaffold.showCupertinoModalBottomSheet(
      backgroundColor: backgroundColor ?? Colors.transparent,
      context: context!,
      useRootNavigator: isUseRootNavigation!,
      enableDrag: false,
      builder: (context) => StatefulBuilder(builder: (context, setMyState) {
            return Material(
              child: Scaffold(
                backgroundColor: backGroundColor ?? Colors.transparent,
                body: Column(
                  children: [
                    isShowAppBar!
                        ? Container(
                            // height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isColorsAppBar ?? Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                    offset: Offset(1.1, -1.1),
                                    blurRadius: 6,
                                    color: Colors.black12)
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (!isNoIcon!)
                                  IconButton(
                                    onPressed: onLeading != null
                                        ? onLeading
                                        : isLeading == true
                                            ? () {
                                                Navigator.pop(context);
                                              }
                                            : () {
                                                Navigator.pop(context);
                                              },
                                    icon: kIsWeb
                                        ? icon ?? const Icon(Icons.arrow_back)
                                        : Platform.isAndroid
                                            ? icon ??
                                                const Icon(Icons.arrow_back)
                                            : icon ??
                                                const Icon(
                                                    Icons.arrow_back_ios),
                                  ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: dynamicTitle ??
                                      Text(
                                        title!,
                                        style: TextStyle(
                                            color: titleColors ?? Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                ),
                                const SizedBox(
                                  width: 40,
                                ),
                                const Spacer(),
                                if (trailing != null) trailing,
                                const SizedBox(
                                  width: 20,
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    // if (!kIsWeb)
                    Expanded(
                      child: child!,
                    ),
                  ],
                ),
              ),
            );
          }));
}
