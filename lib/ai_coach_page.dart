import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AICoachPage extends StatefulWidget {
  const AICoachPage({super.key});

  @override
  State<AICoachPage> createState() => _AICoachPageState();
}

class _AICoachPageState extends State<AICoachPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> chatHistory = [];

  final TextEditingController _customGoalController = TextEditingController();
  final TextEditingController _favoriteFoodsController =
      TextEditingController();
  final TextEditingController _avoidFoodsController = TextEditingController();

  bool loading = false;
  bool _initialized = false;
  bool _onboarding = false;

  late final String _uid;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _initialized = true;
        _onboarding = false;
      });
      return;
    }

    _uid = user.uid;

    final profileDoc = await FirebaseFirestore.instance
        .collection("ai_profiles")
        .doc(_uid)
        .get();

    if (profileDoc.exists) {
      final data = profileDoc.data() ?? {};

      _userProfile = {
        "goal": data["goal"] ?? "",
        "favoriteFoods": data["favoriteFoods"] ?? "",
        "avoidFoods": data["avoidFoods"] ?? "",
      };

      _onboarding = false;

      await _loadChatFromFirestore();
    } else {
      _onboarding = true;
    }

    setState(() {
      _initialized = true;
    });
  }

  Future<void> _loadChatFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("ai_chat")
        .doc(_uid)
        .collection("history")
        .orderBy("createdAt")
        .get();

    final loaded = snapshot.docs.map((doc) {
      return {
        "role": doc["role"],
        "parts": [
          {"text": doc["text"]}
        ]
      };
    }).toList();

    chatHistory
      ..clear()
      ..addAll(loaded);
  }

  Future<void> _saveMessageToFirestore(String role, String text) async {
    await FirebaseFirestore.instance
        .collection("ai_chat")
        .doc(_uid)
        .collection("history")
        .add({
      "role": role,
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _saveProfile() async {
    final goal = _selectedGoal?.trim() ?? "";
    if (goal.isEmpty) return;

    final profileData = {
      "goal": goal,
      "favoriteFoods": _favoriteFoodsController.text.trim(),
      "avoidFoods": _avoidFoodsController.text.trim(),
    };

    await FirebaseFirestore.instance.collection("ai_profiles").doc(_uid).set({
      ...profileData,
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      _userProfile = profileData;
      _onboarding = false;
    });

    await _loadChatFromFirestore();
    setState(() {});
  }

  Widget _quickButtons() {
    final quickItems = [
      "저녁 메뉴 추천해줘",
      "건강한 디저트 요리 레시피 알려줘",
      "가벼운 야식 추천해줘",
      "당 적은 디저트",
      "식단 관리 팁"
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickItems.length,
        itemBuilder: (context, index) {
          final text = quickItems[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                _controller.text = text;
                askAI();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 246, 142, 178),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.pink.shade300),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> askAI() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      loading = true;
      chatHistory.add({
        "role": "user",
        "parts": [
          {"text": userText}
        ]
      });
    });

    _saveMessageToFirestore("user", userText);

    _controller.clear();

    final apiKey = dotenv.env["GEMINI_API_KEY"];
    if (apiKey == null || apiKey.isEmpty) {
      const msg = "⚠️ .env에 GEMINI_API_KEY 없음";
      setState(() {
        chatHistory.add({
          "role": "model",
          "parts": [
            {"text": msg}
          ]
        });
        loading = false;
      });
      _saveMessageToFirestore("model", msg);
      return;
    }

    String systemPrompt =
        "너는 따뜻하고 친절한 식단/요리 코치야. 현실적인 상황을 고려해서 조언해줘.그리고 답변은너무 길게 말고 500자 이하로 대답해줘. 근데 대답할 때 500자 이하로 대답해줄게 라는 말은 하지마.";
    if (_userProfile != null) {
      systemPrompt +=
          "\n\n다음은 사용자의 식단/건강 프로필이야. 이걸 꼭 반영해서 답변해줘:\n${jsonEncode(_userProfile)}";
    }

    final List<Map<String, dynamic>> copiedHistory = chatHistory.map((msg) {
      return {
        "role": msg["role"],
        "parts": [
          {"text": String.fromCharCodes(msg["parts"][0]["text"].codeUnits)}
        ]
      };
    }).toList();

    final List<Map<String, dynamic>> contents = [
      {
        "role": "user",
        "parts": [
          {"text": systemPrompt}
        ]
      },
      ...copiedHistory
    ];

    final body = {"contents": contents};

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      final aiText =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "응답 없음";

      setState(() {
        chatHistory.add({
          "role": "model",
          "parts": [
            {"text": aiText}
          ]
        });
        loading = false;
      });

      _saveMessageToFirestore("model", aiText);
    } catch (e) {
      final errText = "⚠️ 오류 발생: $e";
      setState(() {
        chatHistory.add({
          "role": "model",
          "parts": [
            {"text": errText}
          ]
        });
        loading = false;
      });
      _saveMessageToFirestore("model", errText);
    }
  }

  String _decorateText(String text, bool isUser) {
    return text;
  }

  Widget _bubble(String text, bool isUser) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.local_florist,
                color: const Color.fromARGB(255, 236, 132, 174),
              ),
            ),
          ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser ? Colors.pink[300] : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(1, 3),
                )
              ],
            ),
            child: Text(
              _decorateText(text, isUser),
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyStateWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          "assets/healthy_or_junk.json",
          width: 230,
          height: 230,
        ),
        const SizedBox(height: 20),
        const Text(
          "안녕? 난 너만의 AI코치야! 뭐든 나에게 물어봐~",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        )
      ],
    );
  }

  Widget _inputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "메시지를 입력하세요...",
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : askAI,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String? _selectedGoal;

  Future<void> _selectCustomGoal() async {
    final text = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("직접 입력"),
          content: TextField(
            controller: _customGoalController,
            decoration: const InputDecoration(
              hintText: "예: 혈당 관리 + 근력 증가",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _customGoalController.text.trim());
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );

    if (text != null && text.isNotEmpty) {
      setState(() {
        _selectedGoal = text;
      });
    }
  }

  Widget _buildOnboarding() {
    final presetGoals = [
      "다이어트",
      "체중 유지",
      "벌크업(근육 증가)",
      "전반적인 건강 관리",
      "그 외 (직접 입력)",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 코치 프로필 설정"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "너를 더 잘 도와주기 위해\n먼저 간단한 정보를 알려줘!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              "1. 식단/건강 목표는 뭐야?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetGoals.map((g) {
                final isCustom = g.startsWith("그 외");
                final selected = _selectedGoal == g ||
                    (isCustom &&
                        _selectedGoal != null &&
                        !presetGoals.contains(_selectedGoal));
                return ChoiceChip(
                  label: Text(g),
                  selected: selected,
                  onSelected: (on) async {
                    if (!on) return;
                    if (isCustom) {
                      await _selectCustomGoal();
                    } else {
                      setState(() {
                        _selectedGoal = g;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_selectedGoal != null && !presetGoals.contains(_selectedGoal))
              Text(
                "선택한 목표: $_selectedGoal",
                style: const TextStyle(fontSize: 13, color: Colors.pink),
              ),
            const SizedBox(height: 24),
            const Text(
              "2. 좋아하는 음식 (쉼표로 구분해서 적어줘)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _favoriteFoodsController,
              decoration: const InputDecoration(
                hintText: "예: 샐러드, 연어, 닭가슴살, 김치찌개",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "3. 피하고 싶거나 못 먹는 음식이 있어?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _avoidFoodsController,
              decoration: const InputDecoration(
                hintText: "예: 우유, 매우 매운 음식, 튀김류, 견과류",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedGoal == null || _selectedGoal!.isEmpty)
                    ? null
                    : () async {
                        await _saveProfile();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "완료하고 AI 코치 만나기",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_onboarding) {
      return _buildOnboarding();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 코치"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatHistory.isEmpty
                ? _emptyStateWidget()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final item = chatHistory[index];
                      final isUser = item["role"] == "user";
                      final text = item["parts"][0]["text"];
                      return _bubble(text, isUser);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: _quickButtons(),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(),
            ),
          _inputArea(),
        ],
      ),
    );
  }
}
