import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit_square, color: AppColors.primaryBlue), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search, color: AppColors.iconColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Conversation List
          Expanded(
            child: ListView.separated(
              itemCount: 10,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                final names = ['Rahul Singh', 'Neha Gupta', 'Vikram Joshi', 'Priya Sharma', 'Amit Patel'];
                final agencies = ['Singh Realty', 'Gupta Estates', 'Joshi Properties', 'Sharma Homes', 'Patel Associates'];
                final name = names[index % names.length];
                final agency = agencies[index % agencies.length];
                final isUnread = index < 2;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.2),
                        child: Text(name.substring(0, 1), style: TextStyle(color: Colors.primaries[index % Colors.primaries.length], fontWeight: FontWeight.bold)),
                      ),
                      if (index % 3 != 0) // some are online
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 16)),
                      Text(isUnread ? '10:42 AM' : 'Yesterday', style: TextStyle(color: isUnread ? AppColors.primaryBlue : AppColors.textSecondary, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agency, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isUnread ? 'I sent you the documents for the Bandra property. Please review.' : 'Okay, sounds good. Let\'s meet tomorrow.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isUnread ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/chat/chat_${index + 1}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
