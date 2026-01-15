import 'package:flutter/material.dart';
import '../../domain/entities/home_data.dart';
import '../../../../core/constants/app_constants.dart';


class HomeContent extends StatelessWidget {
  final HomeData data;

  const HomeContent({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          _buildInfoCard(
            context,
            title: 'Status do Sistema',
            subtitle: 'Sistema operacional',
            icon: Icons.check_circle,
            iconColor: const Color(AppColors.successColor),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _buildInfoCard(
            context,
            title: 'Última Sincronização',
            subtitle: _formatDate(data.lastUpdated),
            icon: Icons.sync,
            iconColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _buildInfoCard(
            context,
            title: 'Dados Disponíveis',
            subtitle: 'Informações atualizadas',
            icon: Icons.data_usage,
            iconColor: const Color(AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
          size: AppSizes.iconSizeLarge,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}