import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'drawer_widget.dart'; // Import the AppDrawer

class BattlePage extends StatefulWidget {
  final String apiKey;

  const BattlePage({super.key, required this.apiKey});

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  List<Map<String, dynamic>> userDeck = [];
  List<Map<String, dynamic>> botDeck = [];
  Set<int> bannedCardIds = {}; // Ban list to store used card IDs
  bool isLoadingDeck = false;
  bool decksReady = false;
  bool isLoadingAdditionalCards =
      false; // Flag to track additional card loading

  String currentPage = "Home"; // Track the current page for highlighting

  Map<String, dynamic>? selectedUserCard;
  Map<String, dynamic>? selectedBotCard;
  String? battleResult;
  int userScore = 0;
  int botScore = 0;

  bool showDice = false;
  bool isUserTurn = false; // To track whose turn it is to spin the dice
  int diceResult = 0; // Result of the dice roll
  bool isDiceSpinning = false; // Add a flag to track dice spinning state

  @override
  void initState() {
    super.initState();
    _loadGameState();
  }

  Future<void> _loadGameState() async {
    final gameState = await DatabaseHelper.instance.loadGameState();

    setState(() {
      userDeck = List<Map<String, dynamic>>.from(gameState['userDeck'] ?? []);
      botDeck = List<Map<String, dynamic>>.from(gameState['botDeck'] ?? []);
      userScore = gameState['userScore'] ?? 0;
      botScore = gameState['botScore'] ?? 0;
      decksReady = userDeck.isNotEmpty && botDeck.isNotEmpty;
    });

    // If decks are empty or invalid, reset the game state to show the distribution button
    if (userDeck.isEmpty || botDeck.isEmpty) {
      setState(() {
        userDeck = [];
        botDeck = [];
        userScore = 0;
        botScore = 0;
        decksReady = false;
      });
    }
  }

  Future<void> _saveGameState() async {
    await DatabaseHelper.instance.saveGameState(
      userDeck: userDeck,
      botDeck: botDeck,
      userScore: userScore,
      botScore: botScore,
    );
  }

  Future<void> _generateDeck() async {
    setState(() {
      isLoadingDeck = true;
      decksReady = false;
    });

    try {
      generateValidCards() async {
        final List<Map<String, dynamic>> validCards = [];
        final Set<int> usedIds = {};

        while (validCards.length < 5) {
          final id = Random().nextInt(731) + 1;
          if (usedIds.contains(id)) continue;
          usedIds.add(id);

          try {
            final response = await http.get(
              Uri.parse('https://superheroapi.com/api/${widget.apiKey}/$id'),
            );
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data['response'] == 'success' &&
                  data['powerstats']['power'] != 'null' &&
                  data['image']?['url'] != null) {
                validCards.add(data);
              }
            }
          } catch (e) {
            debugPrint('Error fetching hero $id: $e');
          }
        }

        return validCards;
      }

      final userCards = await generateValidCards();
      final botCards = await generateValidCards();

      await DatabaseHelper.instance.saveActiveCards(
        userCards, // Pass user cards
        botCards, // Pass bot cards
      ); // Save to active_cards and bot_active_cards

      setState(() {
        userDeck = userCards;
        botDeck = botCards;
        decksReady = true;
        isLoadingDeck = false;
      });
    } catch (e) {
      debugPrint("Deck generation error: $e");
      setState(() => isLoadingDeck = false);

      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load decks. Please try again."),
          ),
        );
      }
    }
  }

  Future<void> _rollDice() async {
    setState(() {
      diceResult = 0; // Reset dice result before rolling
      isDiceSpinning = true; // Show the spinning dice GIF
      isLoadingAdditionalCards = true; // Set loading flag
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate spinning delay

    final result = Random().nextInt(3) + 1; // Roll a dice (1-3)

    setState(() {
      diceResult = result; // Update dice result after rolling
      isDiceSpinning = false; // Hide the spinning dice GIF
      showDice = false; // Hide dice button after rolling
    });

    if (diceResult > 0) {
      final additionalCards = await _generateAdditionalCards(diceResult);
      setState(() {
        if (isUserTurn) {
          userDeck.addAll(additionalCards); // Add cards to user deck
        } else {
          botDeck.addAll(additionalCards); // Add cards to bot deck
        }
        isLoadingAdditionalCards = false; // Reset loading flag
      });

      // Save the updated game state
      await _saveGameState();
    } else {
      setState(() {
        isLoadingAdditionalCards = false; // Reset loading flag
      });
    }
  }

  Future<void> _botRollDice() async {
    setState(() {
      diceResult = 0; // Reset dice result before rolling
      showDice = false; // Hide dice while bot is spinning
      isLoadingAdditionalCards = true; // Set loading flag for bot
    });

    await Future.delayed(const Duration(seconds: 2)); // Add delay for bot spin
    final result = Random().nextInt(3) + 1; // Bot rolls a dice (1-6)

    setState(() {
      diceResult = result; // Update dice result after rolling
    });

    if (diceResult > 0) {
      final additionalCards = await _generateAdditionalCards(diceResult);
      setState(() {
        botDeck.addAll(additionalCards); // Add cards to bot deck
        isLoadingAdditionalCards = false; // Reset loading flag
      });

      // Save the updated game state
      await _saveGameState();
    } else {
      setState(() {
        isLoadingAdditionalCards = false; // Reset loading flag
      });
    }
  }

  Future<List<Map<String, dynamic>>> _generateAdditionalCards(int count) async {
    final List<Map<String, dynamic>> additionalCards = [];
    final Set<int> usedIds = {
      ...bannedCardIds,
    }; // Include banned IDs in the exclusion list

    while (additionalCards.length < count) {
      final id = Random().nextInt(731) + 1;
      if (usedIds.contains(id)) continue; // Skip if the card ID is banned
      usedIds.add(id);

      try {
        final response = await http.get(
          Uri.parse('https://superheroapi.com/api/${widget.apiKey}/$id'),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['response'] == 'success' &&
              data['powerstats']['power'] != 'null' &&
              data['image']?['url'] != null) {
            additionalCards.add(data);
          }
        }
      } catch (e) {
        debugPrint('Error fetching hero $id: $e');
      }
    }

    return additionalCards;
  }

  Future<void> _startBattle(Map<String, dynamic> userCard) async {
    if (isLoadingAdditionalCards) {
      // Alert the user to wait for additional cards to load
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please wait, additional cards are still being distributed.",
          ),
        ),
      );
      return;
    }

    if (showDice && isUserTurn) {
      // Alert the user to roll the dice first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please roll the dice before selecting another card."),
        ),
      );
      return;
    }

    selectedUserCard = userCard;
    selectedBotCard =
        botDeck.isNotEmpty ? botDeck[Random().nextInt(botDeck.length)] : null;

    // Initialize points
    int userPoints = 0;
    int botPoints = 0;

    // List of powerstats to compare
    final powerStats = [
      'intelligence',
      'strength',
      'speed',
      'durability',
      'power',
      'combat',
    ];

    for (final stat in powerStats) {
      final userStat =
          int.tryParse(selectedUserCard!['powerstats'][stat] ?? '0') ?? 0;
      final botStat =
          int.tryParse(selectedBotCard!['powerstats'][stat] ?? '0') ?? 0;

      if (userStat > botStat) {
        userPoints++;
      } else if (botStat > userStat) {
        botPoints++;
      }
    }

    // Determine the winner based on points
    if (userPoints > botPoints) {
      battleResult = "You Win this Round!";
      userScore++;
      diceResult = 0;
      showDice = true;
      isUserTurn = true;
    } else if (botPoints > userPoints) {
      battleResult = "Bot Wins this Round!";
      botScore++;
      diceResult = 0;
      showDice = true;
      isUserTurn = false;
      _botRollDice();
    } else {
      battleResult = "It's a Draw!";
      showDice = false;
    }

    // Move the used cards to the used_cards table
    await DatabaseHelper.instance.addCardToUsed(selectedUserCard!);
    if (selectedBotCard != null) {
      await DatabaseHelper.instance.addCardToUsed(selectedBotCard!);
    }

    // Remove the used cards from the in-memory decks
    setState(() {
      userDeck.remove(selectedUserCard);
      botDeck.remove(selectedBotCard);
    });

    _saveGameState();

    if (userDeck.isEmpty || botDeck.isEmpty) {
      if (userDeck.isEmpty) {
        battleResult = "Bot Wins the Game!";
      } else if (botDeck.isEmpty) {
        battleResult = "You Win the Game!";
      }
      decksReady = false;
    }

    // Finally update UI
    setState(() {});
  }

  void _restartGame() async {
    await DatabaseHelper.instance.clearMatchData(); // Clear match-related data
    bannedCardIds.clear(); // Clear the ban list when restarting the game
    setState(() {
      userDeck = [];
      botDeck = [];
      selectedUserCard = null;
      selectedBotCard = null;
      battleResult = null;
      userScore = 0;
      botScore = 0;
      decksReady = false;
      showDice = false; // Reset dice visibility
      isUserTurn = false; // Reset turn tracking
    });
  }

  Widget _buildEndScreen() {
    return Center(
      // Wrap the entire column with Center
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            battleResult ?? "Game Over",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (userDeck.isEmpty || botDeck.isEmpty) ...[
            Text(
              userDeck.isEmpty ? "The Winner is Bot!" : "The Winner is You!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
          ],
          Text("Your Score: $userScore", style: const TextStyle(fontSize: 18)),
          Text("Bot's Score: $botScore", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _restartGame, child: const Text("Restart")),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _generateDeck,
            child: const Text("Distribute Cards Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeck(
    String label,
    List<Map<String, dynamic>> deck, {
    bool isUserDeck = false,
    int score = 0, // Add score parameter
  }) {
    final ScrollController scrollController = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$label (Score: $score)", // Display score beside the label
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "${deck.length} Cards", // Display the number of cards remaining
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () {
                scrollController.animateTo(
                  scrollController.offset - 200,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            Expanded(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: deck.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, index) {
                    final hero = deck[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: GestureDetector(
                        onTap:
                            isUserDeck && decksReady
                                ? () => _startBattle(hero)
                                : null,
                        child: MouseRegion(
                          onEnter:
                              isUserDeck
                                  ? (_) => setState(() => hero['hover'] = true)
                                  : null,
                          onExit:
                              isUserDeck
                                  ? (_) => setState(() => hero['hover'] = false)
                                  : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.grey.withOpacity(
                                    hero['hover'] == true ? 0.8 : 0.5,
                                  ),
                                  spreadRadius: hero['hover'] == true ? 4 : 2,
                                  blurRadius: hero['hover'] == true ? 10 : 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      isUserDeck
                                          ? Image.network(
                                            hero['image']['url'],
                                            width: 160,
                                            height: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => const Icon(
                                                  Icons.broken_image,
                                                  size: 100,
                                                ),
                                          )
                                          : const Icon(
                                            Icons.question_mark,
                                            size: 160,
                                          ),
                                ),
                                const SizedBox(width: 60),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUserDeck ? hero['name'] : "???",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Intelligence: ${isUserDeck ? hero['powerstats']['intelligence'] ?? 'N/A' : '???'}",
                                    ),
                                    Text(
                                      "Strength: ${isUserDeck ? hero['powerstats']['strength'] ?? 'N/A' : '???'}",
                                    ),
                                    Text(
                                      "Speed: ${isUserDeck ? hero['powerstats']['speed'] ?? 'N/A' : '???'}",
                                    ),
                                    Text(
                                      "Durability: ${isUserDeck ? hero['powerstats']['durability'] ?? 'N/A' : '???'}",
                                    ),
                                    Text(
                                      "Power: ${isUserDeck ? hero['powerstats']['power'] ?? 'N/A' : '???'}",
                                    ),
                                    Text(
                                      "Combat: ${isUserDeck ? hero['powerstats']['combat'] ?? 'N/A' : '???'}",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () {
                scrollController.animateTo(
                  scrollController.offset + 200,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiceSpinner() {
    return Center(
      child: Image.asset(
        'assets/dice-game.gif', // Path to the dice GIF
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildDiceOrResult() {
    if (isDiceSpinning) {
      return Image.asset(
        'assets/dice-game.gif', // Path to the dice GIF
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (diceResult > 0) {
      return Text(
        "Additional Cards: $diceResult",
        style: const TextStyle(fontSize: 16),
      );
    } else {
      return const SizedBox.shrink(); // Empty widget if no result
    }
  }

  Widget _buildHighlightedStat(String label, int? userStat, int? botStat) {
    final isUserHigher =
        userStat != null && botStat != null && userStat > botStat;

    return Text(
      "$label: ${userStat ?? 'N/A'}",
      style: TextStyle(
        color: isUserHigher ? Colors.green : Colors.black,
        fontWeight: isUserHigher ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBotHighlightedStat(String label, int? userStat, int? botStat) {
    final isBotHigher =
        userStat != null && botStat != null && botStat > userStat;

    return Text(
      "$label: ${botStat ?? 'N/A'}",
      style: TextStyle(
        color: isBotHigher ? Colors.green : Colors.black,
        fontWeight: isBotHigher ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Battle Page")),
      drawer: AppDrawer(
        currentPage: currentPage,
        apiKey: widget.apiKey,
      ),
      body:
          isDiceSpinning
              ? _buildDiceSpinner() // Show the dice spinner if spinning
              : Padding(
                padding: const EdgeInsets.all(16),
                child:
                    isLoadingDeck
                        ? const Center(child: CircularProgressIndicator())
                        : (userDeck.isEmpty || botDeck.isEmpty) &&
                            battleResult != null
                        ? _buildEndScreen()
                        : decksReady
                        ? SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDeck(
                                "Your Deck",
                                userDeck,
                                isUserDeck: true,
                                score: userScore,
                              ),
                              const SizedBox(height: 20),
                              if (selectedUserCard == null &&
                                  selectedBotCard == null)
                                const Text(
                                  "Choose Your Hero",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 20),
                              if (selectedUserCard != null &&
                                  selectedBotCard != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // User's selected card on the left
                                    SizedBox(
                                      width:
                                          380, // Set the desired width for the container
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              // ignore: deprecated_member_use
                                              color: Colors.grey.withOpacity(
                                                0.5,
                                              ),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          8,
                                          8,
                                        ), // Adjusted left padding to move right
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                selectedUserCard!['image']['url'],
                                                width:
                                                    160, // Adjusted image width
                                                height:
                                                    160, // Adjusted image height
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => const Icon(
                                                      Icons.broken_image,
                                                      size: 80,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width:
                                                  60, // Increased spacing between image and text
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedUserCard!['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                _buildHighlightedStat(
                                                  "Intelligence",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['intelligence'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['intelligence'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildHighlightedStat(
                                                  "Strength",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['strength'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['strength'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildHighlightedStat(
                                                  "Speed",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['speed'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['speed'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildHighlightedStat(
                                                  "Durability",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['durability'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['durability'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildHighlightedStat(
                                                  "Power",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['power'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['power'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildHighlightedStat(
                                                  "Combat",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['combat'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['combat'] ??
                                                        '0',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Result in the center
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "Result: $battleResult",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _buildDiceOrResult(), // Show dice GIF or result
                                          if (showDice && isUserTurn)
                                            ElevatedButton(
                                              onPressed: _rollDice,
                                              child: const Icon(
                                                Icons.casino,
                                              ), // Changed text to dice icon
                                            ),
                                          if (showDice && !isUserTurn)
                                            const Text(
                                              "Bot is spinning...",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Bot's selected card on the right
                                    SizedBox(
                                      width:
                                          360, // Set the desired width for the bot's selected card container
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              // ignore: deprecated_member_use
                                              color: Colors.grey.withOpacity(
                                                0.5,
                                              ),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedBotCard!['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                _buildBotHighlightedStat(
                                                  "Intelligence",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['intelligence'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['intelligence'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildBotHighlightedStat(
                                                  "Strength",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['strength'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['strength'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildBotHighlightedStat(
                                                  "Speed",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['speed'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['speed'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildBotHighlightedStat(
                                                  "Durability",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['durability'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['durability'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildBotHighlightedStat(
                                                  "Power",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['power'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['power'] ??
                                                        '0',
                                                  ),
                                                ),
                                                _buildBotHighlightedStat(
                                                  "Combat",
                                                  int.tryParse(
                                                    selectedUserCard!['powerstats']['combat'] ??
                                                        '0',
                                                  ),
                                                  int.tryParse(
                                                    selectedBotCard!['powerstats']['combat'] ??
                                                        '0',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              width:
                                                  70, // Increased spacing between text and image
                                            ),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                selectedBotCard!['image']['url'],
                                                width:
                                                    160, // Adjusted image width
                                                height:
                                                    160, // Adjusted image height
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => const Icon(
                                                      Icons.broken_image,
                                                      size: 80,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                              const SizedBox(
                                height: 20,
                              ), // Reduced spacing above bot deck
                              _buildDeck("Bot Deck", botDeck, score: botScore),
                            ],
                          ),
                        )
                        : Center(
                          child: ElevatedButton(
                            onPressed: _generateDeck,
                            child: const Text("Distribute Cards"),
                          ),
                        ),
              ),
    );
  }
}
