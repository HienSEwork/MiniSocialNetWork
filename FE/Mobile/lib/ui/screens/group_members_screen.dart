
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/group_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/community_provider.dart';
import '../widgets/common.dart';

class GroupMembersScreen extends StatefulWidget {
const GroupMembersScreen({
super.key,
required this.groupId,
});

final String groupId;

@override
State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
late Future<SocialGroup> _group;

@override
void initState() {
super.initState();
_group = context.read<CommunityProvider>().getGroup(widget.groupId);
}

Future<void> _reload() async {
setState(() {
_group = context.read<CommunityProvider>().getGroup(widget.groupId);
});

await _group;
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text("Group Members"),
),
body: RefreshIndicator(
onRefresh: _reload,
child: FutureBuilder<SocialGroup>(
future: _group,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Text(snapshot.error.toString()),
);
}

if (!snapshot.hasData) {
return const Center(
child: Text("Cannot load group."),
);
}

final group = snapshot.data!;
final members = group.members;

final currentUserId =
context.read<AuthProvider>().session?.userId;

final isOwner = currentUserId == group.ownerId;

if (members.isEmpty) {
return const Center(
child: Text("No members."),
);
}

return ListView.separated(
physics: const AlwaysScrollableScrollPhysics(),
itemCount: members.length,
separatorBuilder: (_, __) => const Divider(height: 1),
itemBuilder: (context, index) {
final member = members[index];
final owner = member.userId == group.ownerId;

return ListTile(
leading: UserAvatar(
label: member.displayName,
imageUrl: member.avatarUrl,
radius: 24,
),
title: Text(
member.displayName,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
subtitle: Text(
owner ? "Owner" : "Member",
),
trailing: owner
? const Icon(
Icons.workspace_premium,
color: Colors.orange,
)
    : isOwner
? PopupMenuButton<String>(
onSelected: (value) async {
final provider =
context.read<CommunityProvider>();

String? error;

switch (value) {
case 'owner':
final confirm =
await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text(
"Transfer ownership"),
content: Text(
"Transfer ownership to ${member.displayName}?\n\n"
"You will become a normal member.",
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(
context, false),
child:
const Text("Cancel"),
),
FilledButton(
onPressed: () =>
Navigator.pop(
context, true),
child:
const Text("Confirm"),
),
],
),
);

if (confirm != true) return;

error =
await provider.transferOwnership(
widget.groupId,
member.userId,
);
break;

case 'kick':
final confirm =
await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text(
"Kick member"),
content: Text(
"Remove ${member.displayName} from this group?",
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(
context, false),
child:
const Text("Cancel"),
),
FilledButton(
onPressed: () =>
Navigator.pop(
context, true),
child: const Text("Kick"),
),
],
),
);

if (confirm != true) return;

error =
await provider.kickMember(
widget.groupId,
member.userId,
);
break;
}

if (!mounted) return;

ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content:
Text(error ?? "Success"),
),
);

if (error == null) {
await _reload();
}
},
itemBuilder: (_) => const [
PopupMenuItem(
value: "owner",
child: Row(
children: [
Icon(
Icons.workspace_premium),
SizedBox(width: 8),
Text(
"Transfer ownership"),
],
),
),
PopupMenuDivider(),
PopupMenuItem(
value: "kick",
child: Row(
children: [
Icon(
Icons.person_remove,
color: Colors.red,
),
SizedBox(width: 8),
Text("Kick Member"),
],
),
),
],
)
    : null,
);
},
);
},
),
),
);
}
}

