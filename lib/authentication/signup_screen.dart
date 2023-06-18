// ignore_for_file: body_might_complete_normally_catch_error

import 'dart:io';
import 'package:car_pool_driver/authentication/verify_email.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../Constants/styles/colors.dart';
import '../global/global.dart';
import '../widgets/progress_dialog.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController confirmPasswordTextEditingController =
      TextEditingController();

  String imageUrl = "";

  File? _userImage;
  final _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _userImage = File(pickedImage.path);
      });
    }
  }

  validateForm() {
    if (nameTextEditingController.text.length < 3) {
      Fluttertoast.showToast(msg: "Name must be atleast 3 characters.");
    } else if (_userImage == null) {
      Fluttertoast.showToast(msg: "Image is required.");
    } else if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "Email not valid.");
    } else if (phoneTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Phone number required.");
    } else if (passwordTextEditingController.text.length < 8) {
      Fluttertoast.showToast(msg: "Password must be at least 8 characters.");
    } else if (passwordTextEditingController.text !=
        confirmPasswordTextEditingController.text) {
      Fluttertoast.showToast(msg: "Password must be at least 8 characters.");
    } else {
      saveDriverInfo();
    }
  }

  saveDriverInfo() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c) {
          return ProgressDialog(
            message: "Processing, Please wait...",
          );
        });

    final User? firebaseUser = (await fAuth
            .createUserWithEmailAndPassword(
      email: emailTextEditingController.text.trim(),
      password: passwordTextEditingController.text.trim(),
    )
            .catchError((msg) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error: $msg");
    }))
        .user;
    /* final ref = _storage.ref()
  /      .child('images')
        .child('${DateTime.now().toIso8601String() + }');
*/
    final imageUploadTask = await _storage
        .ref('userImages/${firebaseUser?.uid}.jpg')
        .putFile(_userImage!);
    final userImageUrl = await imageUploadTask.ref.getDownloadURL();

    if (firebaseUser != null) {
      Map userMap = {
        "id": firebaseUser.uid,
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
        "userImage": userImageUrl,
      };

      DatabaseReference driverRef = FirebaseDatabase.instance.ref("users");
      driverRef.child(firebaseUser.uid).set(userMap);

      currentFirebaseUser = firebaseUser;
      Fluttertoast.showToast(msg: "Account has been created!");
      // ignore: use_build_context_synchronously
      Navigator.push(
          context, MaterialPageRoute(builder: (c) => const VerifyEmailPage()));
    } else {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Account has not been created!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsConst.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Register as a user",
                  style: TextStyle(
                    fontSize: 24,
                    color: ColorsConst.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: showImage(),
                  /*_driverImage != null ? FileImage(_driverImage!) : null*/
                ),
                TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Add User Image')),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: nameTextEditingController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    hintText: "Full Name",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: emailTextEditingController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Email",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: phoneTextEditingController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 10,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    hintText: "Phone Number",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: passwordTextEditingController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  obscureText: true,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Password",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: confirmPasswordTextEditingController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  style: const TextStyle(color: ColorsConst.grey),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    hintText: "Confirm Password",
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: ColorsConst.grey),
                        borderRadius: BorderRadius.circular(10.0)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsConst.grey)),
                    hintStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 10,
                    ),
                    labelStyle: const TextStyle(
                      color: ColorsConst.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                      onPressed: () {
                        validateForm();

                        //Navigator.push(context, MaterialPageRoute(builder: (c)=> CarInfoScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsConst.greenAccent,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            //to set border radius to button
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          color: ColorsConst.white,
                          fontSize: 18,
                        ),
                      )),
                ),
                RichText(
                    text: TextSpan(children: <TextSpan>[
                  const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Poppins',
                          color: ColorsConst.black)),
                  TextSpan(
                      text: "Sign In",
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(context,
                            MaterialPageRoute(builder: (c) => LoginScreen())),
                      style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: Colors.lightBlue)),
                ])),
              ],
            ),
          ),
        ));
  }

  showImage() {
    if (_userImage != null) {
      return FileImage(_userImage!);
    } else {
      return const NetworkImage('images/user.png');
    }
  }
}
