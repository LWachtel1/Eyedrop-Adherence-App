import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:eyedrop/tutorial/entry_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<EntryModel> entries = [];

  void _getEntries() {
    entries = EntryModel.getEntries();
  }

  @override
  void initState() {
    _getEntries();
  }

  @override
  Widget build(BuildContext context) {
    _getEntries();
    return Scaffold(
        appBar: appBar(),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _searchField(),
          SizedBox(height: 40),
          Column(children: [
            Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text('Entries',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold))),
            SizedBox(height: 15),
            Container(
                height: 150,
                color: Colors.green,
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return Container(
                          height: 50,
                          decoration:
                              BoxDecoration(color: entries[index].boxColor));
                    }))
          ])
        ]));
  }
}

AppBar appBar() {
  return AppBar(
      title: Text('Top Bar',
          style: TextStyle(
              color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.white,
      leading: GestureDetector(
          onTap: () {},
          child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: SvgPicture.asset('assets/icons/back.svg',
                  width: 50, height: 50))),
      actions: [
        Container(
            alignment: Alignment.center,
            width: 37,
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: SvgPicture.asset('assets/icons/back.svg',
                width: 50, height: 50))
      ]);
}

Container _searchField() {
  return Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(color: Colors.grey, blurRadius: 40, spreadRadius: 0.0)
      ]),
      child: TextField(
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(15),
              hintText: "Search here",
              prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icons/search.svg',
                      width: 5, height: 5)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none))));
}
