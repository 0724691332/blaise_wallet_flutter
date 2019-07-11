import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:blaise_wallet_flutter/appstate_container.dart';
import 'package:blaise_wallet_flutter/service_locator.dart';
import 'package:blaise_wallet_flutter/ui/util/text_styles.dart';
import 'package:blaise_wallet_flutter/ui/widgets/buttons.dart';
import 'package:blaise_wallet_flutter/ui/widgets/svg_repaint.dart';
import 'package:blaise_wallet_flutter/util/pascal_util.dart';
import 'package:blaise_wallet_flutter/util/vault.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntroSecurityFirstPage extends StatefulWidget {
  @override
  _IntroSecurityFirstPageState createState() => _IntroSecurityFirstPageState();
}

class _IntroSecurityFirstPageState extends State<IntroSecurityFirstPage> {
  var _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // The main scaffold that holds everything
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      key: _scaffoldKey,
      backgroundColor: StateContainer.of(context).curTheme.backgroundPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
              children: <Widget>[
                //A widget that holds welcome animation + paragraph
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Container for the header
                      Container(
                        padding: EdgeInsetsDirectional.only(
                          top: (MediaQuery.of(context).padding.top) +
                              (24 - (MediaQuery.of(context).padding.top) / 2),
                        ),
                        decoration: BoxDecoration(
                          gradient: StateContainer.of(context)
                              .curTheme
                              .gradientPrimary,
                        ),
                        // Row for back button and the header
                        child: Row(
                          children: <Widget>[
                            // The header
                            Container(
                              width: MediaQuery.of(context).size.width - 60,
                              margin: EdgeInsetsDirectional.fromSTEB(
                                  30, 24, 30, 24),
                              child: AutoSizeText(
                                "Security First!",
                                style: AppStyles.header(context),
                                maxLines: 1,
                                stepGranularity: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // Container for the illustration
                            Container(
                              child: SvgRepaintAsset(
                                asset: StateContainer.of(context)
                                    .curTheme
                                    .illustrationSecurity,
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: MediaQuery.of(context).size.width *
                                    0.5 *
                                    (213 / 230),
                              ),
                            ),
                            //Container for the paragraph
                            Container(
                              alignment: Alignment(-1, 0),
                              margin:
                                  EdgeInsetsDirectional.fromSTEB(30, 30, 30, 0),
                              child: AutoSizeText(
                                "In the next screen, you'll see your new private key. It is a password access your funds. It is crucial that you back it up and never share it with anyone.",
                                maxLines: 4,
                                stepGranularity: 0.1,
                                style: AppStyles.paragraph(context),
                              ),
                            ),
                            //Container for the paragraph
                            Container(
                              alignment: Alignment(-1, 0),
                              margin:
                                  EdgeInsetsDirectional.fromSTEB(30, 10, 30, 0),
                              child: AutoSizeText(
                                "If you lose your device or uninstall Blaise, you'll need your private key to recover your funds.",
                                maxLines: 3,
                                stepGranularity: 0.1,
                                style: AppStyles.paragraphPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                //"I've Backed It Up" and "Go Back" buttons
                Row(
                  children: <Widget>[
                    AppButton(
                      type: AppButtonType.Primary,
                      text: "Got It!",
                      buttonTop: true,
                      onPressed: () {
                        sl
                            .get<Vault>()
                            .setPrivateKey(sl
                                .get<PascalUtil>()
                                .generateKeyPair()
                                .privateKey)
                            .then((key) {
                          Navigator.of(context)
                              .pushNamed('/intro_new_private_key');
                        });
                      },
                    ),
                  ],
                ),
                // "Go Back" button
                Row(
                  children: <Widget>[
                    AppButton(
                      type: AppButtonType.PrimaryOutline,
                      text: "Go Back",
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}
