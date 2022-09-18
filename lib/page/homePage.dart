import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_share/page/aboutPage.dart';
import 'package:quick_share/page/chatsPage.dart';
import 'package:quick_share/page/contactsPage.dart';
import 'package:quick_share/util/dataUtil.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  final List<String> _titles = ['Chats', 'Contacts'];
  final List<Widget> _pages = const [ChatsPage(), ContactsPage()];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    DataUtil.init(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles.elementAt(_selectedIndex)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.chat), label: _titles.elementAt(0)),
          BottomNavigationBarItem(icon: const Icon(Icons.people_alt), label: _titles.elementAt(1)),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
      ),
    );
  }
}
