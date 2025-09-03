import 'package:app_settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';

// import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/attendance.dart';
import '../models/paymentDatabase.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';
import '../pages/login.dart';
import 'elements.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var user,
      note = new TextEditingController(),
      clockInTime = DateTime.now(),
      selectedLanguage;
  LatLng? currentLoc;

  String businessSymbol = '',
      businessLogo = '',
      defaultImage = 'assets/images/default_product.png',
      businessName = '',
      userName = '';

  double totalSalesAmount = 0.00,
      totalReceivedAmount = 0.00,
      totalDueAmount = 0.00,
      byCash = 0.00,
      byCard = 0.00,
      byCheque = 0.00,
      byBankTransfer = 0.00,
      byOther = 0.00,
      byCustomPayment_1 = 0.00,
      byCustomPayment_2 = 0.00,
      byCustomPayment_3 = 0.00;

  bool accessExpenses = false,
      attendancePermission = false,
      notPermitted = false,
      syncPressed = false;
  bool? checkedIn;

  // List sells;
  Map<String, dynamic>? paymentMethods;
  int? totalSales;
  List<Map> method = [], payments = [];

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getPermission();
    homepageData();
    Helper().syncCallLogs();
  }

  //function to set homepage details
  homepageData() async {
    var prefs = await SharedPreferences.getInstance();
    user = await System().get('loggedInUser');
    userName = ((user['surname'] != null) ? user['surname'] : "") +
        ' ' +
        user['first_name'];
    await loadPaymentDetails();
    await Helper().getFormattedBusinessDetails().then((value) {
      businessSymbol = value['symbol'];
      businessLogo = value['logo'] ?? Config().defaultBusinessImage;
      businessName = value['name'];
      Config.quantityPrecision = value['quantityPrecision'] ?? 2;
      Config.currencyPrecision = value['currencyPrecision'] ?? 2;
    });
    selectedLanguage =
        prefs.getString('language_code') ?? Config().defaultLanguage;
    setState(() {});
  }

  //permission for displaying Attendance Button
  checkIOButtonDisplay() async {
    try {
      await Attendance().getCheckInTime(USERID).then((value) {
        if (value != null) {
          clockInTime = DateTime.parse(value);
        }
      });
      //if someone has forget to check-in
      //check attendance status
      var activeSubscriptionDetails = await System().get('active-subscription');
      if (activeSubscriptionDetails != null && activeSubscriptionDetails.length > 0 &&
          activeSubscriptionDetails[0].containsKey('package_details')) {
        Map<String, dynamic> packageDetails =
            activeSubscriptionDetails[0]['package_details'];
        if (packageDetails.containsKey('essentials_module') &&
            packageDetails['essentials_module'].toString() == '1') {
          //get attendance status(check-In/check-Out)
          checkedIn = await Attendance().getAttendanceStatus(USERID);
          setState(() {});
        } else {
          setState(() {
            checkedIn = null;
          });
        }
      } else {
        setState(() {
          checkedIn = null;
        });
      }
    } catch (e) {
      print('Error in checkIOButtonDisplay: $e');
      setState(() {
        checkedIn = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: homePageDrawer(),
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('home'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                  fontWeight: 600)),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                (await Helper().checkConnectivity())
                    ? await sync()
                    : Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)
                            .translate('check_connectivity'));
              },
              child: Text(
                AppLocalizations.of(context).translate('sync'),
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface, fontWeight: 600),
              ),
            ),
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await SellDatabase().getNotSyncedSells().then((value) {
                  if (value.isEmpty) {
                    //saving userId in disk
                    prefs.setInt('prevUserId', USERID!);
                    prefs.remove('userId');
                    Navigator.pushReplacementNamed(context, '/login');
                  } else {
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)
                            .translate('sync_all_sales_before_logout'));
                  }
                });
              },
              child: Text(
                AppLocalizations.of(context).translate('logout'),
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface, fontWeight: 600),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Card(
                child: Container(
                  padding: EdgeInsets.all(MySize.size10!),
                  child: Text(
                      AppLocalizations.of(context).translate('welcome') +
                          ' $userName',
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          letterSpacing: -0.2)),
                ),
              ),
              statistics(),
              checkIO(),
              paymentDetails(),
            ],
          ),
        ),
        bottomNavigationBar: posBottomBar('home', context));
  }

//homepage drawer
  Widget homePageDrawer() {
    return Drawer(
      child: Container(
        color: themeData.colorScheme.surface,
        child: Column(
          children: <Widget>[
            Container(
              height: MySize.scaleFactorHeight! * 250,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.white),
                child: CachedNetworkImage(
                    fit: BoxFit.fill,
                    errorWidget: (context, url, error) =>
                        Image.asset(defaultImage),
                    placeholder: (context, url) => Image.asset(defaultImage),
                    imageUrl: businessLogo),
              ),
            ),
            Expanded(
              flex: 9,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Visibility(
                    child: GestureDetector(
                      onTap: () {
                        AppSettings.openAppSettings();
                      },
                      child: Text(
                        "Allow permissions",
                        textAlign: TextAlign.center,
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.titleSmall,
                            color: themeData.colorScheme.error,
                            fontWeight: 600),
                      ),
                    ),
                    visible: (notPermitted),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: themeData.colorScheme.onSurface,
                    ),
                    title: changeAppLanguage(),
                  ),
                  Visibility(
                    visible: accessExpenses,
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.googleSpreadsheet,
                        color: themeData.colorScheme.onSurface,
                      ),
                      onTap: () async {
                        if (await Helper().checkConnectivity()) {
                          Navigator.pushNamed(context, '/expense');
                        } else {
                          Fluttertoast.showToast(
                              msg: AppLocalizations.of(context)
                                  .translate('check_connectivity'));
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context).translate('expenses'),
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.titleSmall,
                            fontWeight: 600),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.cardAccountDetailsOutline,
                      color: themeData.colorScheme.onSurface,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('contact_payment'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleSmall,
                          fontWeight: 600),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/contactPayment');
                      } else {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.faceAgent,
                      color: themeData.colorScheme.onSurface,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('follow_ups'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleSmall,
                          fontWeight: 600),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/followUp');
                        // await CallLog.get().then((value) =>
                        //     Navigator.pushNamed(context, '/followUp'));
                      } else {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  Visibility(
                    visible: Config().showFieldForce,
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.humanMale,
                        color: themeData.colorScheme.onSurface,
                      ),
                      onTap: () async {
                        if (await Helper().checkConnectivity()) {
                          Navigator.pushNamed(context, '/fieldForce');
                        } else {
                          Fluttertoast.showToast(
                              msg: AppLocalizations.of(context)
                                  .translate('check_connectivity'));
                        }
                      },
                      title: Text(
                        AppLocalizations.of(context)
                            .translate('field_force_visits'),
                        style: AppTheme.getTextStyle(
                            themeData.textTheme.titleSmall,
                            fontWeight: 600),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.contact_phone_outlined,
                      color: themeData.colorScheme.onSurface,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('contacts'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleSmall,
                          fontWeight: 600),
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        Navigator.pushNamed(context, '/leads');
                        // await CallLog.get().then(
                        //         (value) =>
                        //         Navigator.pushNamed(context, '/leads'));
                      } else {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.local_shipping_outlined,
                      color: themeData.colorScheme.onSurface,
                    ),
                    title: Text(
                      AppLocalizations.of(context).translate('shipment'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleSmall,
                          fontWeight: 600),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/shipment');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      MdiIcons.syncIcon,
                      color: themeData.colorScheme.onSurface,
                    ),
                    onTap: () async {
                      if (await Helper().checkConnectivity()) {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  Container(
                                      margin: EdgeInsets.only(left: 5),
                                      child: Text(AppLocalizations.of(context)
                                          .translate('loading_data'))),
                                ],
                              ),
                            );
                          },
                        );
                        await Variations().refresh();
                        System().refresh().then((value) {
                          Navigator.popUntil(
                              context, ModalRoute.withName('/home'));
                        });
                      } else {
                        Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('check_connectivity'));
                      }
                    },
                    title: Text(
                      AppLocalizations.of(context).translate('refresh'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleSmall,
                          fontWeight: 600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.all(10),
                    child: Text(
                      Config().copyright +
                          "  " +
                          Config().appName +
                          "  " +
                          Config().version,
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyMedium,
                          fontWeight: 400,
                          letterSpacing: -0.2),
                    )))
          ],
        ),
      ),
    );
  }

  //multi language option
  Widget changeAppLanguage() {
    var appLanguage = Provider.of<AppLanguage>(context);
    return Container(
      child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
        dropdownColor: themeData.colorScheme.onPrimary,
        onChanged: (String? newValue) {
          appLanguage.changeLanguage(Locale(newValue!), newValue);
          selectedLanguage = newValue;
          Navigator.pop(context);
        },
        value: selectedLanguage,
        items: Config().lang.map<DropdownMenuItem<String>>((Map locale) {
          return DropdownMenuItem<String>(
            value: locale['languageCode'],
            child: Text(
              locale['name'],
              style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                  fontWeight: 600),
            ),
          );
        }).toList(),
      )),
    );
  }

  //on sync
  sync() async {
    if (!syncPressed) {
      syncPressed = true;
      showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(AppLocalizations.of(context)
                        .translate('sync_in_progress'))),
              ],
            ),
          );
        },
      );
      await Sell().createApiSell(syncAll: true).then((value) async {
        await Variations().refresh().then((value) {
          Navigator.pop(context);
        });
      });
    }
  }

  block({Color? backgroundColor, String? subject, amount, IconData? icon}) {
    ThemeData themeData = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySize.size12!),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MySize.size12!),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundColor == Colors.blue 
                ? [Color(0xFF2196F3), Color(0xFF1976D2)] // Professional Blue
                : backgroundColor == Colors.red
                    ? [Color(0xFFF44336), Color(0xFFD32F2F)] // Professional Red
                    : backgroundColor == Colors.green
                        ? [Color(0xFF4CAF50), Color(0xFF388E3C)] // Professional Green
                        : [Color(0xFFFF9800), Color(0xFFF57C00)], // Professional Orange
          ),
        ),
        height: MySize.size140,
        child: Container(
          padding: EdgeInsets.all(MySize.size16!),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Large Icon at the top
              Row(
                children: [
                  Icon(
                    icon ?? Icons.analytics,
                    color: Colors.white,
                    size: 32, // Bigger icon
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(height: MySize.size12!),
              // Smaller, professional font for title
              Text(subject!,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodySmall,
                      fontWeight: 500, color: Colors.white, fontSize: 12)),
              SizedBox(height: MySize.size4!),
              // Larger, bold font for amount
              Text("$amount",
                  style: AppTheme.getTextStyle(themeData.textTheme.titleMedium,
                      fontWeight: 700, color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  //widget statistics
  Widget statistics() {
    if (totalSales.toString() == 'null') {
      setState(() {
        totalSales = 0;
      });
    }
    return Container(
      child: GridView.count(
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
          crossAxisCount: 2,
          padding: EdgeInsets.only(
              left: MySize.size16!, right: MySize.size16!, top: MySize.size16!),
          mainAxisSpacing: MySize.size16!,
          childAspectRatio: 1.1, // Slightly taller cards for better icon display
          crossAxisSpacing: MySize.size16!,
          children: <Widget>[
            block(
              amount: Helper().formatQuantity(totalSales),
              subject: AppLocalizations.of(context).translate('number_of_sales'),
              backgroundColor: Colors.blue,
              icon: Icons.shopping_cart, // Professional shopping cart icon
            ),
            block(
              amount: '$businessSymbol ' + Helper().formatCurrency(totalSalesAmount),
              subject: AppLocalizations.of(context).translate('sales_amount'),
              backgroundColor: Colors.red,
              icon: Icons.attach_money, // Professional money icon
            ),
            block(
              amount: '$businessSymbol ' + Helper().formatCurrency(totalReceivedAmount),
              subject: AppLocalizations.of(context).translate('paid_amount'),
              backgroundColor: Colors.green,
              icon: Icons.credit_card, // Professional credit card icon
            ),
            block(
              amount: '$businessSymbol ' + Helper().formatCurrency(totalDueAmount),
              subject: AppLocalizations.of(context).translate('due_amount'),
              backgroundColor: Colors.orange,
              icon: Icons.money_off, // Professional money-off icon
            ),
          ]),
    );
  }

  //widget for payment details
  Widget paymentDetails() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: MySize.size16!),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: MySize.size16!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MySize.size12!),
          ),
          elevation: 0,
        ),
        onPressed: () {
          // Payment details action
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MySize.size12!),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)], // Professional Blue gradient
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: MySize.size16!),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment,
                color: Colors.white,
                size: 24, // Professional icon size
              ),
              SizedBox(width: MySize.size8!),
              Text(
                AppLocalizations.of(context).translate('payment_details'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // Smaller, professional font
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //get permission
  getPermission() async {
    List<PermissionStatus> status = [
      await Permission.location.status,
      await Permission.storage.status,
      await Permission.camera.status,
      // await Permission.phone.status,
    ];
    notPermitted = status.contains(PermissionStatus.denied);
    await Helper()
        .getPermission('essentials.allow_users_for_attendance_from_api')
        .then((value) {
      if (value == true) {
        checkIOButtonDisplay();
        setState(() {
          attendancePermission = true;
        });
      } else {
        setState(() {
          checkedIn = null;
        });
      }
    });

    if (await Helper().getPermission('all_expense.access') ||
        await Helper().getPermission('view_own_expense')) {
      setState(() {
        accessExpenses = true;
      });
    }
  }

  //checkIn and checkOut button
  Widget checkIO() {
    if (checkedIn != null) {
      return Padding(
        padding: EdgeInsets.only(top: MySize.size10!),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: MySize.size16!),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: MySize.size16!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MySize.size12!),
                  ),
                  elevation: 0,
                ),
                onPressed: syncPressed ? null : () async {
                  Helper().syncCallLogs();
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              (!checkedIn!) ? Icons.login : Icons.logout,
                              color: (!checkedIn!) ? Colors.green : Colors.red,
                            ),
                            SizedBox(width: MySize.size8!),
                            Expanded(
                              child: Text(
                                (!checkedIn!)
                                    ? AppLocalizations.of(context)
                                        .translate('check_in_note')
                                    : AppLocalizations.of(context)
                                        .translate('check_out_note'),
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleMedium,
                                  fontWeight: 600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (!checkedIn!)
                                  ? 'Please add a note for your check-in'
                                  : 'Please add a note for your check-out',
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyMedium,
                                color: themeData.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: MySize.size16!),
                            TextFormField(
                              controller: note,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Enter your note here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(MySize.size8!),
                                ),
                                filled: true,
                                fillColor: themeData.colorScheme.surface,
                              ),
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: themeData.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              note.clear();
                            },
                            child: Text(
                              AppLocalizations.of(context).translate('cancel'),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (!checkedIn!) ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              if (note.text.trim().isEmpty) {
                                Fluttertoast.showToast(
                                  msg: 'Please enter a note before proceeding',
                                );
                                return;
                              }
                              
                              Navigator.pop(context);
                              setState(() {
                                syncPressed = true;
                              });
                              
                              if (await Helper().checkConnectivity()) {
                                try {
                                  await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high,
                                  ).then((Position position) {
                                    currentLoc = LatLng(position.latitude, position.longitude);
                                  });
                                } catch (e) {
                                  print('Location error: $e');
                                }
                                
                                if (checkedIn == false) {
                                  //get ip address
                                  var ipAddress = IpAddress(type: RequestType.json);
                                  dynamic data = await ipAddress.getIpAddress();
                                  String iP = data.toString();

                                  //get current location
                                  try {
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    ).then((Position position) {
                                      currentLoc = LatLng(position.latitude, position.longitude);
                                    });
                                  } catch (e) {
                                    print('Location error: $e');
                                  }

                                  var checkInMap = await Attendance().doCheckIn(
                                    checkInNote: note.text,
                                    iPAddress: iP,
                                    latitude: (currentLoc != null) ? currentLoc!.latitude : '',
                                    longitude: (currentLoc != null) ? currentLoc!.longitude : '',
                                  );
                                  Fluttertoast.showToast(msg: checkInMap);
                                  note.clear();
                                } else {
                                  //get current location
                                  try {
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    ).then((Position position) {
                                      currentLoc = LatLng(position.latitude, position.longitude);
                                    });
                                  } catch (e) {
                                    print('Location error: $e');
                                  }

                                  var checkOutMap = await Attendance().doCheckOut(
                                    latitude: (currentLoc != null) ? currentLoc!.latitude : '',
                                    longitude: (currentLoc != null) ? currentLoc!.longitude : '',
                                    checkOutNote: note.text,
                                  );
                                  Fluttertoast.showToast(msg: checkOutMap);
                                  note.clear();
                                }
                                
                                checkedIn = await Attendance().getAttendanceStatus(USERID);
                                await Attendance().getCheckInTime(USERID).then((value) {
                                  if (value != null) {
                                    clockInTime = DateTime.parse(value);
                                  }
                                });
                                setState(() {
                                  syncPressed = false;
                                });
                              } else {
                                Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context).translate('check_connectivity'),
                                );
                                setState(() {
                                  syncPressed = false;
                                });
                              }
                            },
                            child: Text(
                              AppLocalizations.of(context).translate('ok'),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MySize.size12!),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: (!checkedIn!) 
                          ? [Color(0xFF4CAF50), Color(0xFF388E3C)] // Professional Green
                          : [Color(0xFFF44336), Color(0xFFD32F2F)], // Professional Red
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: MySize.size16!),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (syncPressed)
                        Container(
                          width: 20,
                          height: 20,
                          margin: EdgeInsets.only(right: MySize.size8!),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      Icon(
                        (!checkedIn!) ? Icons.login : Icons.logout,
                        color: Colors.white,
                        size: 24, // Professional icon size
                      ),
                      SizedBox(width: MySize.size8!),
                      Text(
                        (!checkedIn!)
                            ? AppLocalizations.of(context).translate('check_in')
                            : AppLocalizations.of(context).translate('check_out'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Smaller, professional font
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (checkedIn == true)
              Container(
                margin: EdgeInsets.only(top: MySize.size8!),
                padding: EdgeInsets.symmetric(
                  horizontal: MySize.size16!,
                  vertical: MySize.size8!,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MySize.size12!),
                  border: Border.all(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: MySize.size8!),
                    Text(
                      'Checked in: ${_formatDuration(DateTime.now().difference(clockInTime))}',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else
      return Container();
  }

  // Helper method to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }

//load statistics
  Future<List> loadStatistics() async {
    List result = await SellDatabase().getSells();
    totalSales = result.length;
    setState(() {
      result.forEach((sell) async {
        List payment =
            await PaymentDatabase().get(sell['id'], allColumns: true);
        var paidAmount = 0.0;
        var returnAmount = 0.0;
        payment.forEach((element) {
          if (element['is_return'] == 0) {
            paidAmount += element['amount'];
            payments
                .add({'key': element['method'], 'value': element['amount']});
          } else {
            returnAmount += element['amount'];
          }
        });
        totalSalesAmount = (totalSalesAmount + sell['invoice_amount']);
        totalReceivedAmount =
            (totalReceivedAmount + (paidAmount - returnAmount));
        totalDueAmount = (totalDueAmount + sell['pending_amount']);
      });
    });
    return result;
  }

//load payment details
  loadPaymentDetails() async {
    var paymentMethod = [];
    //fetch different payment methods
    await System().get('payment_methods').then((value) {
      //Add all PaymentMethods into a List according to key value pair
      value.forEach((element) {
        element.forEach((k, v) {
          paymentMethod.add({'key': '$k', 'value': '$v'});
        });
      });
    });

    await loadStatistics().then((value) {
      Future.delayed(Duration(seconds: 1), () {
        payments.forEach((row) {
          if (row['key'] == 'cash') {
            byCash += row['value'];
          }

          if (row['key'] == 'card') {
            byCard += row['value'];
          }

          if (row['key'] == 'cheque') {
            byCheque += row['value'];
          }

          if (row['key'] == 'bank_transfer') {
            byBankTransfer += row['value'];
          }

          if (row['key'] == 'other') {
            byOther += row['value'];
          }

          if (row['key'] == 'custom_pay_1') {
            byCustomPayment_1 += row['value'];
          }

          if (row['key'] == 'custom_pay_2') {
            byCustomPayment_2 += row['value'];
          }
          if (row['key'] == 'custom_pay_3') {
            byCustomPayment_3 += row['value'];
          }
        });
        paymentMethod.forEach((row) {
          if (byCash > 0 && row['key'] == 'cash')
            method.add({'key': row['value'], 'value': byCash});
          if (byCard > 0 && row['key'] == 'card')
            method.add({'key': row['value'], 'value': byCard});
          if (byCheque > 0 && row['key'] == 'cheque')
            method.add({'key': row['value'], 'value': byCheque});
          if (byBankTransfer > 0 && row['key'] == 'bank_transfer')
            method.add({'key': row['value'], 'value': byBankTransfer});
          if (byOther > 0 && row['key'] == 'other')
            method.add({'key': row['value'], 'value': byOther});
          if (byCustomPayment_1 > 0 && row['key'] == 'custom_pay_1')
            method.add({'key': row['value'], 'value': byCustomPayment_1});
          if (byCustomPayment_2 > 0 && row['key'] == 'custom_pay_2')
            method.add({'key': row['value'], 'value': byCustomPayment_2});
          if (byCustomPayment_3 > 0 && row['key'] == 'custom_pay_3')
            method.add({'key': row['value'], 'value': byCustomPayment_3});
        });
        if (this.mounted) {
          setState(() {});
        }
      });
    });
  }
}
