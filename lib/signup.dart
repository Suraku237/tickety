import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String _selectedRole = 'User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.blue)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 30),

            // Name Field
            _buildTextField("Full Name"),
            SizedBox(height: 15),

            // Email Field
            _buildTextField("Email Address"),
            SizedBox(height: 15),

            // Role Picker
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(30)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  items: ['User', 'Admin'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
              ),
            ),
            SizedBox(height: 15),

            // Password
            _buildTextField("Password", isObscure: true),
            SizedBox(height: 30),

            ElevatedButton(
            
              onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account Created! Please Login.")));
                 Navigator.pop(context);
              },
              
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: StadiumBorder(), minimumSize: Size(double.infinity, 50)),
              child: Text("Sign Up", style: TextStyle(color: Colors.white)),
              
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool isObscure = false}) {
    return TextField(
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}