import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';  // Ensure correct path

class ResetPasswordScreen extends ConsumerWidget {
  ResetPasswordScreen({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                hintText: "Enter your email",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Add logic to initiate password reset
                await ref.read(authControllerProvider.notifier).resetPassword(emailController.text.trim());
                // Optionally, show a confirmation message or handle errors
              },
              child: Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
