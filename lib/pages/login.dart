import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/api.dart';
import '../apis/system.dart';
import '../apis/user.dart';
import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/database.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';

// ignore: non_constant_identifier_names
int? USERID;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  final _formKey = GlobalKey<FormState>();
  Timer? timer;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    MySize().init(context);
    
    return Scaffold(
      backgroundColor: themeData.colorScheme.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                // Top section with logo and title
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/icon/pos.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  size: 60,
                                  color: themeData.colorScheme.primary,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: MySize.size24!),
                        // Sign In Title
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: MySize.size12!),
                        // Welcome subtitle
                        Text(
                          'Welcome back! Please enter your details',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Form section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: EdgeInsets.all(MySize.size24!),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: MySize.size16!),
                            
                            // Username field
                            Text(
                              'Username',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: MySize.size8!),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: usernameController,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: themeData.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    MdiIcons.emailOutline,
                                    color: themeData.colorScheme.primary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: MySize.size16!,
                                    vertical: MySize.size16!,
                                  ),
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter username';
                                  }
                                  return null;
                                },
                                autofocus: true,
                              ),
                            ),
                            
                            SizedBox(height: MySize.size20!),
                            
                            // Password field
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: MySize.size8!),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: !_passwordVisible,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: themeData.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    MdiIcons.lockOutline,
                                    color: themeData.colorScheme.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? MdiIcons.eyeOutline
                                          : MdiIcons.eyeOffOutline,
                                      color: themeData.colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: MySize.size16!,
                                    vertical: MySize.size16!,
                                  ),
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            SizedBox(height: MySize.size32!),
                            
                            // Login button
                            Container(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (await Helper().checkConnectivity()) {
                                    if (_formKey.currentState!.validate() &&
                                        !isLoading) {
                                      setState(() {
                                        isLoading = true;
                                      });

                                      Map? loginResponse = await Api().login(
                                          usernameController.text,
                                          passwordController.text);

                                      if (loginResponse != null && loginResponse['success']) {
                                        //schedule job for syncing callLogs
                                        Helper().jobScheduler();
                                        //Get current logged in user details and save it.

                                        showLoadingDialogue();
                                        await loadAllData(loginResponse, context);
                                        Navigator.of(context).pop();

                                        //Take to home page
                                        Navigator.of(context).pushNamed('/home');
                                      } else {
                                        setState(() {
                                          isLoading = false;
                                        });

                                        String errorMessage = 'Invalid credentials';
                                        if (loginResponse != null && loginResponse['error'] != null) {
                                          errorMessage = loginResponse['error'];
                                        }
                                        
                                        Fluttertoast.showToast(
                                            msg: errorMessage);
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeData.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            
                            Spacer(),
                            
                            // Sign up section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await launchUrl(Uri.parse('${Config.baseUrl}business/register'));
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: themeData.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: MySize.size16!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  loadAllData(loginResponse, context) async {
    timer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      (context != null)
          ? Fluttertoast.showToast(
              msg: AppLocalizations.of(context)
                  .translate('It_may_take_some_more_time_to_load'))
          : t.cancel();
      t.cancel();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map loggedInUser = await User().get(loginResponse['access_token']);

    USERID = loggedInUser['id'];
    Config.userId = USERID;
    //saving userId in disk
    prefs.setInt('userId', USERID!);
    DbProvider().initializeDatabase(loggedInUser['id']);

    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();

    //delete system table before saving data
    System().empty();
    //delete contact table
    Contact().emptyContact();
    //save user details
    await System().insertUserDetails(loggedInUser);
    //Insert token
    System().insertToken(loginResponse['access_token']);
    //save system data
    await SystemApi().store();
    await System().insertProductLastSyncDateTimeNow();
    //check previous userId
    if (prefs.getInt('prevUserId') == null ||
        prefs.getInt('prevUserId') != prefs.getInt('userId')) {
      SellDatabase().deleteSellTables();
      await Variations().refresh();
    } else {
      //save variations if last sync is greater than 10hrs
      if (lastSync == null ||
          (date2.difference(DateTime.parse(lastSync)).inHours > 10)) {
        if (await Helper().checkConnectivity()) {
          await Variations().refresh();
          await System().insertProductLastSyncDateTimeNow();
          SellDatabase().deleteSellTables();
        }
      }
    }
    //Take to home page
    Navigator.of(context).pushReplacementNamed('/home');
    Navigator.of(context).pop();
  }

  Future<void> showLoadingDialogue() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Text(
                      AppLocalizations.of(context).translate('loading_data'))),
            ],
          ),
        );
      },
    );
  }
}
