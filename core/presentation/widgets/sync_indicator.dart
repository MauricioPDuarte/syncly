import '../../entities/sync_data.dart';
import '../../interfaces/i_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controllers/sync_indicator_controller.dart';
import '../utils/sync_status_helpers.dart';
import '../utils/sync_icon_builder.dart';

class SyncIndicator extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showText;

  const SyncIndicator({
    super.key,
    this.onTap,
    this.showText = true,
  });

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  late final SyncIndicatorController _controller;
  late final ISyncService syncService;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance.get<SyncIndicatorController>();
    syncService = GetIt.instance.get<ISyncService>();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setContext(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa a preferência do controller se carregada, senão usa o parâmetro widget.compact
    final isCompact = _controller.compactMode;

    return ValueListenableBuilder<SyncData>(
      valueListenable: syncService.syncData,
      builder: (context, syncData, child) {
        final isOnline = syncService.isOnline.value;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: isCompact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SyncStatusHelpers.getBackgroundColor(
                  syncData.status, isOnline),
              borderRadius: BorderRadius.circular(isCompact ? 60 : 7),
              border: Border.all(
                color:
                    SyncStatusHelpers.getBorderColor(syncData.status, isOnline),
                width: 1,
              ),
            ),
            child: isCompact
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SyncIconBuilder.buildIcon(
                          syncData.status, isOnline, isCompact),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SyncIconBuilder.buildIcon(
                              syncData.status, isOnline, isCompact),
                          if (widget.showText) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                SyncStatusHelpers.getStatusText(
                                    syncData.status, isOnline),
                                style: TextStyle(
                                  color: SyncStatusHelpers.getTextColor(
                                      syncData.status, isOnline),
                                  fontSize:
                                      14, // Aumentado para melhor visibilidade em campo
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (syncData.lastSync != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Última sincronização: ${SyncStatusHelpers.formatDateTime(syncData.lastSync!)}',
                          style: TextStyle(
                            color: SyncStatusHelpers.getTextColor(
                                    syncData.status, isOnline)
                                .withValues(alpha: 0.7),
                            fontSize:
                                12, // Aumentado para melhor visibilidade em campo
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}
