import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:blaise_wallet_flutter/appstate_container.dart';
import 'package:blaise_wallet_flutter/bus/daemon_changed_event.dart';
import 'package:blaise_wallet_flutter/constants.dart';
import 'package:blaise_wallet_flutter/model/available_themes.dart';
import 'package:blaise_wallet_flutter/model/available_currency.dart';
import 'package:blaise_wallet_flutter/model/notification_enabled.dart';
import 'package:blaise_wallet_flutter/service_locator.dart';
import 'package:blaise_wallet_flutter/store/account/account.dart';
import 'package:blaise_wallet_flutter/ui/widgets/webview.dart';
import 'package:blaise_wallet_flutter/util/ui_util.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:package_info/package_info.dart';
import 'package:share/share.dart';
import 'package:blaise_wallet_flutter/themes.dart';
import 'package:blaise_wallet_flutter/ui/settings/backup_private_key/backup_private_key_sheet.dart';
import 'package:blaise_wallet_flutter/ui/settings/change_daemon_sheet.dart';
import 'package:blaise_wallet_flutter/ui/settings/public_key_sheet.dart';
import 'package:blaise_wallet_flutter/ui/util/app_icons.dart';
import 'package:blaise_wallet_flutter/ui/util/text_styles.dart';
import 'package:blaise_wallet_flutter/ui/widgets/overlay_dialog.dart';
import 'package:blaise_wallet_flutter/ui/widgets/settings_list_item.dart';
import 'package:blaise_wallet_flutter/ui/widgets/sheets.dart';
import 'package:blaise_wallet_flutter/util/sharedprefs_util.dart';
import 'package:blaise_wallet_flutter/util/vault.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final Account account;

  SettingsPage({this.account}) : super();

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  List<DialogListItem> languageList = [];

  List<DialogListItem> getThemeList() {
    List<DialogListItem> ret = [];
    ThemeOptions.values.forEach((ThemeOptions value) {
      ThemeSetting theme = ThemeSetting(value);
      ret.add(DialogListItem(
          option: theme.getDisplayName(context),
          action: () {
            StateContainer.of(context).updateTheme(ThemeSetting(value));
            Navigator.of(context).pop();
          }));
    });
    return ret;
  }

  List<DialogListItem> getCurrencyList() {
    List<DialogListItem> ret = [];
    AvailableCurrencyEnum.values.forEach((AvailableCurrencyEnum value) {
      AvailableCurrency currency = AvailableCurrency(value);
      ret.add(DialogListItem(
          option: currency.getDisplayName(context),
          action: () {
            sl.get<SharedPrefsUtil>()
                .setCurrency(currency)
                .then((result) {
              if (StateContainer.of(context).curCurrency.currency != currency.currency) {
                setState(() {
                  StateContainer.of(context).curCurrency = currency;
                });
                walletState.requestUpdate();
              }
            });
            Navigator.of(context).pop();
          }));
    });
    return ret;
  }

  List<DialogListItem> getNotificationList() {
    List<DialogListItem> ret = [];
    NotificationOptions.values.forEach((NotificationOptions value) {
      NotificationSetting setting = NotificationSetting(value);
      ret.add(DialogListItem(
          option: setting.getDisplayName(context),
          action: () {
            if (setting != _curNotificiationSetting) {
              sl.get<SharedPrefsUtil>().setNotificationsOn(setting.setting == NotificationOptions.ON).then((result) {
                setState(() {
                  _curNotificiationSetting = setting;
                });
                // TODO we should probably pass a list for less websocket requests
                walletState.walletAccounts.forEach((acct) {
                  walletState.fcmUpdate(acct.account);
                });
              });
            }
            Navigator.of(context).pop();
          }));
    });
    return ret;
  }

  String daemonURL;
  String versionString = "";
  NotificationSetting _curNotificiationSetting =
      NotificationSetting(NotificationOptions.ON);

  @override
  void initState() {
    super.initState();
    sl.get<SharedPrefsUtil>().getRpcUrl().then((result) {
      if (result != AppConstants.DEFAULT_RPC_HTTP_URL && mounted) {
        setState(() {
          daemonURL = result;
        });
      }
    });
    // Version string
    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        versionString = "v${packageInfo.version}";
      });
    });
    languageList = [
      DialogListItem(
          option: "English (en)",
          action: () {
            Navigator.pop(context);
          }),
    ];
    // Get default notification setting
    sl.get<SharedPrefsUtil>().getNotificationsOn().then((notificationsOn) {
      setState(() {
        _curNotificiationSetting = notificationsOn
            ? NotificationSetting(NotificationOptions.ON)
            : NotificationSetting(NotificationOptions.OFF);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // The main scaffold that holds everything
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      key: _scaffoldKey,
      backgroundColor: StateContainer.of(context).curTheme.backgroundPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: <Widget>[
            // Container for the gradient background
            Container(
              height: 104 +
                  (MediaQuery.of(context).padding.top) +
                  (36 - (MediaQuery.of(context).padding.top) / 2),
              decoration: BoxDecoration(
                gradient: StateContainer.of(context).curTheme.gradientPrimary,
              ),
            ),
            // Column for the rest
            Column(
              children: <Widget>[
                // Container for the header and button
                Container(
                  margin: EdgeInsetsDirectional.only(
                    top: (MediaQuery.of(context).padding.top) +
                        (36 - (MediaQuery.of(context).padding.top) / 2),
                    bottom: 8,
                  ),
                  // Row for back button and the header
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Back Button
                      Container(
                        margin: EdgeInsetsDirectional.only(start: 2),
                        height: 50,
                        width: 50,
                        child: FlatButton(
                            highlightColor:
                                StateContainer.of(context).curTheme.textLight15,
                            splashColor:
                                StateContainer.of(context).curTheme.textLight30,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Icon(AppIcons.back,
                                color: StateContainer.of(context)
                                    .curTheme
                                    .textLight,
                                size: 24)),
                      ),
                      // The header
                      Container(
                        width: MediaQuery.of(context).size.width - 100,
                        margin: EdgeInsetsDirectional.fromSTEB(4, 0, 24, 0),
                        child: AutoSizeText(
                          "Settings",
                          style: AppStyles.header(context),
                          maxLines: 1,
                          stepGranularity: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expanded list
                Expanded(
                  // Container for the list
                  child: Container(
                    margin: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color:
                          StateContainer.of(context).curTheme.backgroundPrimary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        StateContainer.of(context).curTheme.shadowSettingsList,
                      ],
                    ),
                    // Settings List
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12)),
                      child: ListView(
                        padding: EdgeInsetsDirectional.only(
                            bottom: MediaQuery.of(context).padding.bottom + 24),
                        children: <Widget>[
                          // Preferences text
                          Container(
                            alignment: Alignment(-1, 0),
                            margin: EdgeInsetsDirectional.only(
                                start: 24, end: 24, top: 18, bottom: 8),
                            child: AutoSizeText(
                              "Preferences",
                              style: AppStyles.settingsHeader(context),
                              maxLines: 1,
                              stepGranularity: 0.1,
                            ),
                          ),
                          // Divider
                          Container(
                            width: double.maxFinite,
                            height: 1,
                            color:
                                StateContainer.of(context).curTheme.textDark10,
                          ),
                          // List Items
                          SettingsListItem(
                            header: "Currency",
                            subheader: StateContainer.of(context).curCurrency.getDisplayName(context),
                            icon: AppIcons.currency,
                            onPressed: () {
                              showAppDialog(
                                  context: context,
                                  builder: (_) => DialogOverlay(
                                      title: 'Currency',
                                      optionsList: getCurrencyList()));
                            },
                          ),
                          SettingsListItem(
                            header: "Language",
                            subheader: "System Default",
                            icon: AppIcons.language,
                            onPressed: () {
                              showAppDialog(
                                  context: context,
                                  builder: (_) => DialogOverlay(
                                      title: 'Language',
                                      optionsList: languageList));
                            },
                          ),
                          SettingsListItem(
                            header: "Theme",
                            subheader: StateContainer.of(context)
                                        .curTheme
                                        .toString() ==
                                    BlaiseLightTheme().toString()
                                ? "Light"
                                : StateContainer.of(context)
                                            .curTheme
                                            .toString() ==
                                        BlaiseDarkTheme().toString()
                                    ? "Dark"
                                    : "Copper",
                            icon: AppIcons.theme,
                            onPressed: () {
                              showAppDialog(
                                  context: context,
                                  builder: (_) => DialogOverlay(
                                      title: 'Theme',
                                      optionsList: getThemeList()));
                            },
                          ),
                          SettingsListItem(
                            header: "Notifications",
                            subheader: _curNotificiationSetting.getDisplayName(context),
                            icon: AppIcons.notifications,
                            onPressed: () {
                              showAppDialog(
                                  context: context,
                                  builder: (_) => DialogOverlay(
                                      title: 'Notifications',
                                      optionsList: getNotificationList()));
                            },
                          ),
                          SettingsListItem(
                            header: "Security",
                            icon: AppIcons.security,
                            onPressed: () {
                              Navigator.pushNamed(context, '/security');
                            },
                          ),
                          SettingsListItem(
                            header: "Daemon",
                            subheader: daemonURL ?? "Default",
                            icon: AppIcons.changedaemon,
                            onPressed: () {
                              AppSheets.showBottomSheet(
                                  context: context,
                                  widget:
                                      ChangeDaemonSheet(onChanged: (newDaemon) {
                                    EventTaxiImpl.singleton().fire(
                                        DaemonChangedEvent(
                                            newDaemon: newDaemon));
                                    if (newDaemon !=
                                        AppConstants.DEFAULT_RPC_HTTP_URL) {
                                      setState(() {
                                        daemonURL = newDaemon;
                                      });
                                    } else {
                                      setState(() {
                                        daemonURL = null;
                                      });
                                    }
                                  }));
                            },
                          ),
                          // Manage text
                          Container(
                            alignment: Alignment(-1, 0),
                            margin: EdgeInsetsDirectional.only(
                                start: 24, end: 24, top: 18, bottom: 8),
                            child: AutoSizeText(
                              "Manage",
                              style: AppStyles.settingsHeader(context),
                              maxLines: 1,
                              stepGranularity: 0.1,
                            ),
                          ),
                          // Divider
                          Container(
                            width: double.maxFinite,
                            height: 1,
                            color:
                                StateContainer.of(context).curTheme.textDark10,
                          ),
                          SettingsListItem(
                            header: "Contacts",
                            icon: AppIcons.contacts,
                            onPressed: () {
                              Navigator.pushNamed(context, '/contacts',
                                  arguments: widget.account);
                            },
                          ),
                          SettingsListItem(
                            header: "Backup Private Key",
                            icon: AppIcons.backupprivatekey,
                            onPressed: () {
                              AppSheets.showBottomSheet(
                                  context: context,
                                  widget: BackupPrivateKeySheet());
                            },
                          ),
                          SettingsListItem(
                            header: "View Public Key",
                            icon: Icons.public,
                            onPressed: () {
                              AppSheets.showBottomSheet(
                                  context: context, widget: PublicKeySheet());
                            },
                          ),
                          SettingsListItem(
                              header: "Share Blaise",
                              icon: AppIcons.share,
                              onPressed: () {
                                UIUtil.cancelLockEvent();
                                Share.share(
                                    "Check out Blaise - Pascal Wallet for iOS and Android");
                              }),
                          SettingsListItem(
                            header: "Logout",
                            icon: AppIcons.logout,
                            onPressed: () {
                              logoutPressed();
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(versionString,
                                    style: AppStyles.textStyleVersion(context)),
                                Text(" | ",
                                    style: AppStyles.textStyleVersion(context)),
                                GestureDetector(
                                    onTap: () {
                                      AppWebView.showWebView(context,
                                          AppConstants.PRIVACY_POLICY_URL);
                                    },
                                    child: Text("Privacy Policy",
                                        style:
                                            AppStyles.textStyleVersionUnderline(
                                                context))),
                                Text(" | ",
                                    style: AppStyles.textStyleVersion(context)),
                                GestureDetector(
                                    onTap: () {
                                      AppWebView.showWebView(context,
                                          AppConstants.PRIVACY_POLICY_URL);
                                    },
                                    child: Text("EULA",
                                        style:
                                            AppStyles.textStyleVersionUnderline(
                                                context))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void logoutPressed() {
    showAppDialog(
        context: context,
        builder: (_) => DialogOverlay(
              title: 'WARNING',
              warningStyle: true,
              confirmButtonText: "DELETE PRIVATE KEY\nAND LOGOUT",
              body: TextSpan(
                children: [
                  TextSpan(
                    text:
                        "Are you sure that you’ve backed up your private key? ",
                    style: AppStyles.paragraph(context),
                  ),
                  TextSpan(
                    text:
                        "As long as you’ve backed up your private key, you have nothing to worry about.",
                    style: AppStyles.paragraphDanger(context),
                  ),
                ],
              ),
              onConfirm: () {
                Navigator.of(context).pop();
                showAppDialog(
                    context: context,
                    builder: (_) => DialogOverlay(
                        title: 'ARE YOU SURE?',
                        warningStyle: true,
                        confirmButtonText: "YES, I'M SURE",
                        body: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "Logging out will remove your private key and all Blaise related data from this device. ",
                              style: AppStyles.paragraphDanger(context),
                            ),
                            TextSpan(
                              text:
                                  "If your private key is not backed up, you will never be able to access your funds again. If your private key is backed up, you have nothing to worry about.",
                              style: AppStyles.paragraph(context),
                            ),
                          ],
                        ),
                        onConfirm: () {
                          // Handle logging out
                          walletState.reset();
                          sl.get<Vault>().deleteAll().then((_) {
                            sl.get<SharedPrefsUtil>().deleteAll().then((_) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/', (Route<dynamic> route) => false);
                            });
                          });
                        }));
              },
            ));
  }
}
