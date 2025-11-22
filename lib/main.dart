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

class AuthHome extends StatelessWidget {
  const AuthHome({super.key});

  // 기본 메시지
  static const String defaultMsg =
      "I promise to take the test honestly before God.";

  Future<void> _createUserDocIfNeeded(User u) async {
    final userDoc = FirebaseFirestore.instance.collection('user').doc(u.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        "name": u.displayName ?? (u.isAnonymous ? "Guest" : ""),
        "email": u.email ?? "",
        "uid": u.uid,
        "status_message": defaultMsg,
      });
    } else {
      await userDoc.set({
        "name": u.displayName ?? (u.isAnonymous ? "Guest" : ""),
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

        String title = "Welcome to the app";

        if (user == null) {
          title = "Welcome to the app";
        } else {
          if (loginProvider.loginType == "google") {
            title = "Welcome ${loginProvider.userName}!";
          } else if (loginProvider.loginType == "anonymous") {
            title = "Welcome Guest!";
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: user != null
                ? IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () async {
                      final provider = context.read<UserProvider>();

                      provider.uid = user.uid;
                      await provider.loadUser(user.uid);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(user: user),
                        ),
                      );
                    },
                  )
                : null,
            actions: user != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WishlistPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductAddPage(),
                          ),
                        );
                      },
                    ),
                  ]
                : null,
          ),
          body: Center(
            child: user == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GOOGLE LOGIN
                      ElevatedButton(
                        onPressed: () async {
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
                        child: const Text('Sign in with Google'),
                      ),

                      // GUEST LOGIN
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signInAnonymously();
                          final u = FirebaseAuth.instance.currentUser;

                          if (u != null) {
                            context.read<LoginProvider>().setGuest();
                            await _createUserDocIfNeeded(u);
                          }
                        },
                        child: const Text('Sign in as Guest'),
                      ),
                    ],
                  )
                : ProductsList(user: user),
          ),
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () async {
              context.read<LoginProvider>().reset();

              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthHome()),
              );
            },
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}
