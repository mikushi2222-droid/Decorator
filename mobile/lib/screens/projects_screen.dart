import 'package:flutter/material.dart';
import '../main.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Проекты'),
        backgroundColor: kBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Скоро: создание проектов')),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kGoldLight,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: kGold.withOpacity(0.4)),
                ),
                child: const Icon(Icons.folder_outlined, size: 48, color: kBronze),
              ),
              const SizedBox(height: 24),
              const Text(
                'Проекты',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kGraphite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Раздел проектов появится в следующей версии.\n\nЗдесь будут объекты, фото работ, история изменений и смета по каждому заказчику.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: kGraphite.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Уведомим, когда будет готово!')),
                ),
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Уведомить о выходе'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
