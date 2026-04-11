import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _rememberMe = false;
  String _role = 'User';
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Decorative Top Section with Circles
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                  ),
                ),
                Positioned(
                  top: -50, right: -50,
                  child: CircleAvatar(radius: 100, backgroundColor: Colors.deepPurple[400]?.withOpacity(0.4)),
                ),
                Positioned(
                  top: -30, left: -40,
                  child: CircleAvatar(radius: 80, backgroundColor: Colors.lightBlue[300]?.withOpacity(0.4)),
                ),
                // Profile Icon overlapping the bottom edge
                Positioned(
                  bottom: -50,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      padding: EdgeInsets.all(5),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.blue[50],
                        child: Icon(Icons.person, size: 60, color: Colors.blue[400]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 70),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                  SizedBox(height: 25),

                  // Role Selection
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(30)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _role,
                        isExpanded: true,
                        items: ['User', 'Admin'].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text("Login as $value"));
                        }).toList(),
                        onChanged: (val) => setState(() => _role = val!),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  // Username Field
                  _customField("Username", Icons.person_outline, controller: _userController),
                  SizedBox(height: 15),

                  // Password Field
                  _customField("Password", Icons.lock_outline, isPass: true, controller: _passController),

                  // Remember Me
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: Colors.blue,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                      ),
                      Text("Remember me", style: TextStyle(color: Colors.blue[700])),
                      Spacer(),
                      TextButton(onPressed: () {}, child: Text("Forgot Password?", style: TextStyle(color: Colors.blue[300]))),
                    ],
                  ),

                  SizedBox(height: 20),
                  
                  // Sign In Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                      print("Logging in as $_role");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      elevation: 5,
                    ),
                    child: Text("SIGN IN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customField(String hint, IconData icon, {bool isPass = false, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue),
        hintText: hint,
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}