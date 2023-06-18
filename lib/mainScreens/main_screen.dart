import 'dart:convert';

import 'package:car_pool_driver/Views/tabPages/my_requests_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../Constants/styles/colors.dart';
import '../Models/request.dart';
import '../Views/tabPages/dashboard.dart';
import '../Views/tabPages/payment_web_view.dart';
import '../Views/tabPages/profile_tab.dart';
import '../Views/tabPages/trip_history_tab.dart';
import '../global/global.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  int selectedIndex = 0;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  onItemClicked(int index) {
    setState(() {
      selectedIndex = index;
      tabController!.index = selectedIndex;
    });
  }

  final CollectionReference collectionRef =
      FirebaseFirestore.instance.collection('tripStatus');
  Future<void> deleteTripCollection() async {
    final QuerySnapshot snapshot = await collectionRef.get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    for (DocumentSnapshot document in documents) {
      await document.reference.delete();
    }
  }

  final CollectionReference poolCollectionRef =
      FirebaseFirestore.instance.collection('poolStatus');
  Future<void> deletePoolCollection() async {
    final QuerySnapshot snapshot = await collectionRef.get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    for (DocumentSnapshot document in documents) {
      await document.reference.delete();
    }
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        deletePoolCollection();
        deleteTripCollection();
        showpaymentDialog();
      },
    );
    Stream<QuerySnapshot<Map<String, dynamic>>> notificationStream =
        FirebaseFirestore.instance.collection("poolStatus").snapshots();
    Stream<QuerySnapshot<Map<String, dynamic>>> tripStream =
        FirebaseFirestore.instance.collection("tripStatus").snapshots();

    notificationStream.listen((event) {
      if (event.docs.isEmpty) {
        return;
      }

      showStatusNotification(event.docs.first);
    });
    tripStream.listen((event) {
      if (event.docs.isEmpty) {
        return;
      }
      showTripNotification(event.docs.first);
    });
  }

  void showStatusNotification(
      QueryDocumentSnapshot<Map<String, dynamic>> event) {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails("ScheduleNotification001", "Notify me",
            importance: Importance.high);
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    flutterLocalNotificationsPlugin.show(
        01, event.get('title'), event.get('description'), notificationDetails);
  }

  void showTripNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> event,
  ) {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails("ScheduleNotification001", "Notify me",
            importance: Importance.high);
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    flutterLocalNotificationsPlugin.show(
        01, event.get('title'), event.get('description'), notificationDetails);
    showpaymentDialog();
  }

  Future<void> showpaymentDialog() {
    return showModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: ((context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  makePayment(context);
                },
                leading: const Icon(Icons.attach_money),
                title: const Text("Pay driver online"),
              ),
              const Divider(),
              ListTile(
                onTap: () {
                  rateDriver();
                },
                leading: const Icon(Icons.star),
                title: const Text("Rate your driver"),
              ),
              const Divider(),
              ListTile(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  leading: const Icon(Icons.check),
                  title: const Text("Done"))
            ],
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabController,
        children: const [
          Dashboard(),
          TripHistoryTabPage(),
          MyRequests(),
          ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_rental),
            label: "Trip History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        unselectedItemColor: ColorsConst.grey,
        selectedItemColor: ColorsConst.greenAccent,
        backgroundColor: ColorsConst.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 14),
        showUnselectedLabels: true,
        currentIndex: selectedIndex,
        onTap: onItemClicked,
      ),
    );
  }

  final requestRef = FirebaseDatabase.instance.ref('requests');
  Future<void> rateDriver() {
    return showDialog(
        context: context,
        builder: (builder) {
          return AlertDialog(
            title: const Center(
              child: Text(
                'Rate your driver',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder(
                  stream: requestRef
                      .orderByChild('userID')
                      .equalTo(currentFirebaseUser!.uid)
                      .onValue,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data?.snapshot?.value == null) {
                      return Container();
                    } else {
                      Map<dynamic, dynamic> requests =
                          snapshot.data.snapshot.value;
                      Request? item;
                      requests.forEach((key, value) {
                        if (value['status'] == 'accepted') {
                          item = Request(
                              tripID: value['tripID'],
                              driverID: value['driverID'],
                              requestID: value['requestID'],
                              userID: value['userID'],
                              status: value['status']);
                        }
                      });
                      return buildDriverRating(item);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text(
                  'Ok',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  double? _rating;
  IconData? _selectedIcon;
  final driverRef = FirebaseDatabase.instance.ref('drivers');
  Widget buildDriverRating(Request? req) => StreamBuilder(
        stream: driverRef.child(req!.driverID).onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData ||
              snapshot.data?.snapshot?.value == null) {
            return Container();
          } else {
            return RatingBar.builder(
              initialRating: _rating ?? 0.0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 25,
              itemPadding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, _) => Icon(
                _selectedIcon ?? Icons.star,
                color: ColorsConst.amber,
              ),
              onRatingUpdate: (rating) async {
                _rating = rating;
                double? avgRating;
                String? numberOfRatings;
                final ref = FirebaseDatabase.instance.ref('drivers');
                final snapshot =
                    await ref.child(req.driverID).child('averageRating').get();
                if (snapshot.exists) {
                  avgRating = double.parse(snapshot.value.toString());
                } else {
                  const AlertDialog(semanticLabel: 'No data available.');
                }

                final snapshot2 =
                    await ref.child(req.driverID).child('noOfRatings').get();
                numberOfRatings = snapshot2.value.toString();

                avgRating =
                    ((avgRating! * int.parse(numberOfRatings)) + _rating!) /
                        (int.parse(numberOfRatings) + 1);

                FirebaseDatabase.instance
                    .ref("drivers")
                    .child(req.driverID)
                    .update({"averageRating": avgRating.toString()});
                FirebaseDatabase.instance
                    .ref("drivers")
                    .child(req.driverID)
                    .update({
                  "noOfRatings": (int.parse(numberOfRatings) + 1).toString()
                });

                setState(() {});
              },
            );
          }
        },
      );
  Future<void> makePayment(BuildContext context) async {
    var headers = {
      'Authorization': 'Bearer CHASECK_TEST-NHFsyWe3Vt3pE9Ke4evqbvwvXzjTc0uA',
      'Content-Type': 'application/json'
    };
    var request = http.Request(
        'POST', Uri.parse('https://api.chapa.co/v1/transaction/initialize'));
    request.body = json.encode({
      "amount": "100",
      "currency": "ETB",
      "email": "tt@gmail.com",
      "first_name": "Samson",
      "last_name": "Sisay",
      "phone_number": "0911243697",
      "tx_ref": "Xzasda2213AZZZ23",
      "callback_url":
          "https://webhook.site/077164d6-29cb-40df-ba29-8a00e59a7e60",
      "return_url": "https://www.google.com/",
      "customization[title]": "Payment for carpooling",
      "customization[description]": "Payment for Samson Sisay for carpooling"
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final responseJson = json.decode(responseBody);
      final checkoutUrl = responseJson['data']['checkout_url'];
      // Navigate to the checkout URL
      // ignore: use_build_context_synchronously
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => WebViewScreen(checkoutUrl)));
    } else {
      Fluttertoast.showToast(
          msg: response.statusCode.toString() +
              response.reasonPhrase.toString());
    }
  }
}
