import "dart:convert";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/picsum_image.dart";
import "package:flutter_lorem/flutter_lorem.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:intl/intl.dart";
import 'package:uniso_social_media_app/screens/auth/sign_in_screen.dart';
import 'package:uniso_social_media_app/screens/auth/sign_up_screen.dart';

/// Initializes Supabase with API URL and Anon Key from environment variables.
Future<void> initializeSupabase() async {
  var apiUrl = dotenv.env["API_URL"];
  var anonKey = dotenv.env["ANON_KEY"];

  if (apiUrl != null && anonKey != null) {
    await Supabase.initialize(url: apiUrl, anonKey: anonKey);
  }
}

void main() async {
  try {
    // Loads environment variables from the .env file located in the supabase folder.
    await dotenv.load(fileName: "supabase/.env", isOptional: true);
  } finally {}

  // Calls the Supabase initialization function.
  await initializeSupabase();

  runApp(App());
}

/// The root widget of the application.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _App();
}

class _App extends State<App> {
  int _selectedIndex = 0; // Tracks the currently selected tab in the bottom navigation.
  final PageController _controller = PageController(); // Controls the PageView for horizontal navigation.
  bool _isAuthenticated = true; // Temporary flag to bypass login and see the Home UI.

  /// Updates the selected index and animates the PageView to the corresponding page.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose controllers to free resources.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      // Home property determines whether to show the main app or the Sign In screen.
      home: _isAuthenticated
        ? Scaffold(
            body: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(), // Disables swiping to change pages manually.
              children: const [Home(), Unisons()], // The two main tabs: Home feed and Unisons (chat).
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: "Unisons"),
              ],
            ),
          )
        : const SignInScreen(), // Shows login if the user is not authenticated.
    );
  }
}

/// Displays a list of members, currently used in a side drawer or dialog.
class MemberList extends StatefulWidget {
  const MemberList({super.key});

  @override
  State<MemberList> createState() => _MemberList();
}

class _MemberList extends State<MemberList> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children:
            List.generate(50, (index) {
              return TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(lorem(paragraphs: 1, words: 1)), // Generates a random name for mock data.
                  ],
                ),
              );
            })
                .expand((widget) => [widget, const SizedBox(height: 8)])
                .toList()
              ..removeLast(),
          ),
        ),
      ),
    );
  }
}

/// Sidebar for navigating between different "Unisons" (groups/channels).
class UnisonsSidebar extends StatefulWidget {
  const UnisonsSidebar({super.key});

  @override
  State<UnisonsSidebar> createState() => _UnisonsSidebar();
}

class _UnisonsSidebar extends State<UnisonsSidebar> {
  int? _selectedUnisonIndex;
  var groups = List.generate(50, (index) => lorem(paragraphs: 1, words: 1));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColoredBox(
          color: Theme.of(context).canvasColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Unisons List", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Menu for creating a new Unison group.
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const CreateNewUnisonDialog(),
                          );
                        },
                        child: const Text("Create new Unison"),
                      ),
                    ],
                    builder: (context, controller, child) {
                      return IconButton(
                        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                        icon: const Icon(Icons.list),
                      );
                    },
                  ),
                ],
              ),
              // Search bar for filtering the list of Unisons.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search unions...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
        // Scrollable list of Unison groups.
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(groups[index]),
                selected: _selectedUnisonIndex == index,
                selectedTileColor: Theme.of(context).colorScheme.primary,
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                onTap: () => setState(() => _selectedUnisonIndex = index),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The main chat interface screen.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreen();
}

class _ChatScreen extends State<ChatScreen> {
  final TextEditingController _inputMessageController = TextEditingController();
  late RealtimeChannel roomChannel;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    // Subscribes to a Supabase Realtime channel for instant messaging.
    roomChannel = Supabase.instance.client.channel(
      "room:messages",
      opts: const RealtimeChannelConfig(self: true),
    );
  }

  @override
  void dispose() {
    _inputMessageController.dispose();
    roomChannel.unsubscribe(); // Ensure we stop listening to chat updates when leaving.
    super.dispose();
  }

  /// Sends the current input message to Supabase.
  void sendMessage() async {
    var content = _inputMessageController.text;
    _inputMessageController.text = "";
    if (content.isEmpty) return;

    try {
      setState(() => _isSending = true);

      // Insert message into the database.
      var data = await Supabase.instance.client
          .from("messages")
          .insert({"content": content})
          .select()
          .single();

      // Broadcast the new message to other clients on the same channel.
      roomChannel.sendBroadcastMessage(event: "message_sent", payload: data);

      setState(() => _isSending = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _inputMessageController.text = content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Button to open the list of members in the current chat.
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        child: SizedBox(
                          width: 200,
                          height: double.infinity,
                          child: const MemberList(),
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text("Members List"),
            ),
          ],
        ),
        const Divider(),
        // Component that renders the stream of chat messages.
        UnisonConversation(roomChannel: roomChannel),
        // Input bar for typing and sending messages.
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputMessageController,
                onSubmitted: (_) => sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Enter your message...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: _isSending ? null : sendMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

/// Layout for the Unisons tab, splitting the screen into a sidebar and a chat window.
class Unisons extends StatefulWidget {
  const Unisons({super.key});

  @override
  State<Unisons> createState() => _Unisons();
}

class _Unisons extends State<Unisons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SizedBox(width: 250, child: UnisonsSidebar()),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: ChatScreen(),
          ),
        ),
      ],
    );
  }
}

/// Dialog for entering details to create a new chat group (Unison).
class CreateNewUnisonDialog extends StatefulWidget {
  const CreateNewUnisonDialog({super.key});

  @override
  State<CreateNewUnisonDialog> createState() => _CreateNewUnisonDialog();
}

class _CreateNewUnisonDialog extends State<CreateNewUnisonDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create new Unison"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Name",
                hintText: "Enter unison name",
              ),
              validator: (value) {
                if (value == null || value.length < 4) {
                  return "Name must be at least 4 characters";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop();
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}

/// Component that listens for and displays chat messages in real-time.
class UnisonConversation extends StatefulWidget {
  final RealtimeChannel roomChannel;
  const UnisonConversation({super.key, required this.roomChannel});

  @override
  State<UnisonConversation> createState() => _UnisonConversation();
}

class _UnisonConversation extends State<UnisonConversation> {
  final ScrollController _chatScrollController = ScrollController();
  List<Message> messages = [];
  double _currentOffset = 0;
  bool _loadingMessages = false;

  /// Fetches the message history from Supabase database.
  Future<List<Message>> fetchMessages() async {
    final messages = await Supabase.instance.client
        .from("messages")
        .select("content, created_at")
        .order("created_at", ascending: true);

    return Message.fromList(messages);
  }

  @override
  void initState() {
    super.initState();

    _chatScrollController.addListener(() {
      setState(() => _currentOffset = _chatScrollController.offset);
    });

    // Listens for "message_sent" events from other users in the same room.
    widget.roomChannel
        .onBroadcast(
          event: "message_sent",
          callback: (payload) {
            setState(() {
              messages.add(Message.fromMap(payload));
              _scrollToBottom();
            });
          },
        )
        .subscribe();
  }

  /// Automatically scrolls the chat to the newest message.
  void _scrollToBottom() {
    _chatScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            controller: _chatScrollController,
            itemCount: messages.length + 1,
            reverse: true, // Newest messages appear at the bottom.
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return Center(
                  child: _loadingMessages
                      ? const CircularProgressIndicator()
                      : TextButton(
                    onPressed: () {
                      // Trigger loading message history logic.
                    },
                    child: const Text("Load more messages"),
                  ),
                );
              }

              var message = messages[messages.length - index - 1];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("Username", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat("M/d/yy, h:mm a").format(message.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(message.content, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Scroll-to-bottom button when user has scrolled up.
          if (_currentOffset > 0)
            Positioned(
              bottom: 16,
              child: IconButton.filled(
                onPressed: _scrollToBottom,
                icon: const Icon(Icons.arrow_downward),
              ),
            ),
        ],
      ),
    );
  }
}

/// The main feed screen where users can scroll through vertically paginated posts.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  final _pageController = PageController(initialPage: 0);
  final List<PicsumImage> _images = [];

  int _currentPage = 0;
  int _currentPicsumPage = 0;
  bool _isLoading = false;

  /// Fetches a list of random images from the Picsum API.
  Future<List<PicsumImage>> fetchImages(int page, {int? limit = 4}) async {
    final response = await http.get(
      Uri.parse("https://picsum.photos/v2/list?page=$page&limit=$limit"),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PicsumImage.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load images");
    }
  }

  /// Automatically loads more images when the user reaches the end of the feed.
  Future<void> _fetchNextPage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      var newImages = await fetchImages(_currentPicsumPage);
      setState(() {
        _images.addAll(newImages);
        _currentPicsumPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
    _pageController.addListener(() {
      if (_currentPage > _images.length - 2) _fetchNextPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _images.isEmpty
            ? const CenteredCircularProgress()
            : PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical, // Scrolling vertical for a TikTok-like feed.
          itemCount: _images.length,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) => PostPage(image: _images[index]),
        ),
        // Overlay for navigation between Sign In and Sign Up.
        Positioned(
          top: 0.0,
          left: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // MenuAnchor triggers the dropdown menu when the profile avatar is clicked.
                MenuAnchor(
                  builder: (context, controller, child) {
                    return Pressable(
                      onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                      child: const CircleAvatar(
                        backgroundImage: NetworkImage("https://avatars.githubusercontent.com/u/64018564?v=4"),
                        radius: 24,
                      ),
                    );
                  },
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen())),
                      child: const Text('Sign In'),
                    ),
                    MenuItemButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Text("Your name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A custom wrapper to make any widget clickable with a hover cursor effect.
class Pressable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const Pressable({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onPressed, child: child),
    );
  }
}

/// A full-screen container that shows a loading indicator.
class CenteredCircularProgress extends StatelessWidget {
  const CenteredCircularProgress({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

/// Renders a single image post in the vertical Home feed.
class PostPage extends StatelessWidget {
  final PicsumImage image;
  const PostPage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: image.downloadUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const CenteredCircularProgress(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}
