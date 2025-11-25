import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'product_detail_page.dart';
import 'product_add_page.dart';
import 'profile_page.dart';

import 'package:provider/provider.dart';
import 'wishlist_provider.dart';
import 'wishlist_page.dart';
import 'user_provider.dart';
import 'login_provider.dart';
import 'DropDownProvider.dart';
import 'signup_page.dart';
import 'searchpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => DropDownProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth & Products',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthHome(),
    );
  }
}

class AuthHome extends StatefulWidget {
  const AuthHome({super.key});

  @override
  State<AuthHome> createState() => _AuthHomeState();
}

class _AuthHomeState extends State<AuthHome> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const String defaultMsg =
      "I promise to take the test honestly before God.";

  Future<void> _createUserDocIfNeeded(User u) async {
    final userDoc = FirebaseFirestore.instance.collection('user').doc(u.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        "name": u.displayName ?? "",
        "email": u.email ?? "",
        "uid": u.uid,
        "status_message": defaultMsg,
      });
    } else {
      await userDoc.set({
        "name": u.displayName ?? "",
        "email": u.email ?? "",
        "uid": u.uid,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final loginProvider = context.watch<LoginProvider>();

        // 1️⃣ 아직 로그인 안 됐을 때 → 로그인 화면
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Welcome to the app"),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await GoogleSignIn().signOut();
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Login failed: $e")),
                            );
                          }
                        },
                        child: const Text("Login"),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text(
                          "Sign in with Google",
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          await GoogleSignIn().signOut();

                          final googleUser = await GoogleSignIn().signIn();
                          if (googleUser == null) return;

                          final googleAuth = await googleUser.authentication;
                          final credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );

                          final userCredential = await FirebaseAuth.instance
                              .signInWithCredential(credential);

                          final u = userCredential.user;
                          if (u != null) {
                            context
                                .read<LoginProvider>()
                                .setGoogleUser(u.displayName ?? "");
                            await _createUserDocIfNeeded(u);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpPage()),
                              );
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 2️⃣ 로그인 된 상태 → 상품 리스트 화면
        final title = loginProvider.userName.isNotEmpty
            ? "Welcome ${loginProvider.userName}!"
            : "Welcome ${user.email ?? ''}!";

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthHome()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductAddPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () async {
                    final provider = context.read<UserProvider>();
                    provider.uid = user.uid;
                    await provider.loadUser(user.uid);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfilePage(user: user)),
                    );
                  },
                ),
              ],
            ),
          ),
          body: ProductsList(user: user),
        );
      },
    );
  }
}

class ProductsList extends StatelessWidget {
  final User user;
  const ProductsList({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final dropdown = context.watch<DropDownProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text("Sort: "),
              DropdownButton<String>(
                value: dropdown.sortOption,
                items: const [
                  DropdownMenuItem(
                    value: "asc",
                    child: Text("ASC"),
                  ),
                  DropdownMenuItem(
                    value: "desc",
                    child: Text("DESC"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    dropdown.setSortOption(value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy(
                  "price",
                  descending: dropdown.sortOption == "desc",
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data!.docs;

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final data = product.data() as Map<String, dynamic>;
                  final docId = product.id;

                  final rawUrl = data['imageUrl']?.toString() ?? '';
                  final imageUrl = rawUrl
                      .replaceAll('\n', '')
                      .replaceAll('\r', '')
                      .replaceAll(' ', '')
                      .trim();

                  final wishlist = context.watch<WishlistProvider>();
                  final isInWishlist = wishlist.isInWishlist(docId);

                  final name = data['name'] ?? "No name";
                  final price = data['price'] ?? 0;

                  return Stack(
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text("₩$price"),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailPage(
                                                docId: product.id),
                                          ),
                                        );
                                      },
                                      child: const Text('More'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isInWishlist)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 24,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
