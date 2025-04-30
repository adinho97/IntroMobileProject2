import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget{
    
    const LoginScreen({super.key});

    @override
    Widget build(BuildContext context){
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        

        return Scaffold(
            appBar: AppBar(title: const Text('Lendme Login')),
            body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                        TextField(
                            controller: emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height:16),
                        TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(labelText: "Password"),
                            obscureText: true,
                        ),
                        const SizedBox(height: 24),
                            ElevatedButton(
                                onPressed: () {
                                 // Hier komt later Firebase login
                                 ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Inloggen niet geïmplementeerd')),
                             );
                        },
                        child: const Text('Login'),
                     ),
                        const SizedBox(height: 12),
                        TextButton(
                            onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                            },
                             child: const Text('No account yet? Register here'),
                        )


                    ],
                ),
            ),
        );

    }
}