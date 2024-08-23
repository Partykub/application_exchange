import 'package:exchange/screen/Admin/profile_user.dart';
import 'package:exchange/screen/profile/post_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReport extends StatelessWidget {
  const AdminReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const Report();
  }
}

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _updateStatus(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Reports')
          .doc(docId)
          .update({'status': 'Handled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สถานะถูกอัปเดตเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.white,
          // title: const Text("ข้อมูลการรายงาน",
          //     style: TextStyle(color: Colors.black, fontSize: 16)),
          bottom: TabBar(
            controller: _tabController,
            // labelColor: Colors.black,
            indicatorColor: Colors.black87, // สีของ indicator
            indicatorWeight: 3.0, // ความหนาของ indicator
            labelColor: Colors.black87, // สีของข้อความใน Tab เมื่อถูกเลือก
            unselectedLabelColor:
                Colors.grey, // สีของข้อความใน Tab เมื่อไม่ถูกเลือก
            tabs: const [
              Tab(text: 'รอจัดการ'),
              Tab(text: 'จัดการแล้ว'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('Reports')
                .where('status', isEqualTo: 'Pending')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('เกิดข้อผิดพลาด'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('ไม่มีข้อมูลการรายงานที่รอจัดการ'));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var report = snapshot.data!.docs[index];
                  var reportData = report.data() as Map<String, dynamic>;
                  // ตรวจสอบว่ามีฟิลด์ postID อยู่ในเอกสารหรือไม่
                  bool hasPostID = reportData.containsKey('postID');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Container(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => hasPostID
                                  ? PostDetailPage(postId: report['postID'])
                                  : ProfileUser(userId: report['userID']),
                            )),
                        title: Text("เหตุผล: ${report['reason']}"),
                        subtitle: Text("รายละเอียด: ${report['details']}"),
                        trailing: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.black54),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            fixedSize:
                                MaterialStateProperty.all(const Size(120, 30)),
                          ),
                          onPressed: () => _updateStatus(report.id),
                          child: const Text('จัดการแล้ว',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // แท็บสำหรับข้อมูลที่จัดการแล้ว
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('Reports')
                .where('status', isEqualTo: 'Handled')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('เกิดข้อผิดพลาด'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('ไม่มีข้อมูลการรายงานที่จัดการแล้ว'));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var report = snapshot.data!.docs[index];
                  var reportData = report.data() as Map<String, dynamic>;
                  // ตรวจสอบว่ามีฟิลด์ postID อยู่ในเอกสารหรือไม่
                  bool hasPostID = reportData.containsKey('postID');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Container(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => hasPostID
                                  ? PostDetailPage(postId: report['postID'])
                                  : ProfileUser(userId: report['userID']),
                            )),
                        title: Text("เหตุผล: ${report['reason']}"),
                        subtitle: Text("รายละเอียด: ${report['details']}"),
                        trailing: const Text("สถานะ: จัดการเรียบร้อยแล้ว"),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ));
  }
}
