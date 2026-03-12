import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/providers/websocket_provider.dart';
import 'package:pda_handheld/services/storage_service.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:provider/provider.dart';

const double kRobotBodyWidth = 0.96;
const double kRobotBodyHeight = 0.68;

const double kRobotIdMaxWidth = 110;
const double kRobotLabelGap = 4;
const double kRobotNameGap = 2;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final StorageService _storageService = StorageService();
  final TransformationController _transformationController =
      TransformationController();

  SMapData? _mapData;
  bool _isMapLoading = false;
  String? _mapError;

  static const double _minScale = 0.5;
  static const double _maxScale = 5.0;
  static const double _scaleStep = 1.2;

  Size? _lastViewportSize;

  bool _showStatusCard = true;
  bool _showLegendCard = true;
  Offset _legendOffset = const Offset(16, 80);

  final GlobalKey _stackKey = GlobalKey();
  Size? _stackSize;

  Timer? _robotPollingTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadRobots();
      await _fetchMapData();
      _startRobotPolling();
    });
  }

  @override
  void dispose() {
    _robotPollingTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  void _startRobotPolling() {
    _robotPollingTimer?.cancel();

    final wsProvider = context.read<WebsocketProvider>();

    // wsProvider.sendCommand(1004);

    _robotPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      wsProvider.sendCommand(1004);
    });
  }

  Future<void> _loadRobots() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobots();
  }

  Future<void> _fetchMapData() async {
    setState(() {
      _isMapLoading = true;
      _mapError = null;
    });

    try {
      final serverConfig = _storageService.getServerConfig();
      final user = _storageService.getUser();

      if (serverConfig == null) {
        throw Exception('Server config not found');
      }

      final response = await http.get(
        Uri.parse('${serverConfig.baseUrl}/api/v1/core/current-map'),
        headers: {
          'Content-Type': 'application/json',
          if (user?.token != null && user!.token.isNotEmpty)
            'Authorization': 'Bearer ${user.token}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load map (${response.statusCode})');
      }

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> smapJson = _unwrapSMap(decoded);

      setState(() {
        _mapData = SMapData.fromJson(smapJson);
      });
    } catch (e) {
      setState(() {
        _mapError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _unwrapSMap(dynamic raw) {
    return raw['data']['mapData'] as Map<String, dynamic>;
  }

  void _zoomIn() {
    _applyScaleStep(_scaleStep);
  }

  void _zoomOut() {
    _applyScaleStep(1 / _scaleStep);
  }

  void _fitView() {
    _transformationController.value = Matrix4.identity();
  }

  void _applyScaleStep(double factor) {
    final currentMatrix = _transformationController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(_minScale, _maxScale);

    final effectiveFactor = targetScale / currentScale;
    if (effectiveFactor == 1.0) return;

    final viewportSize = _lastViewportSize;
    if (viewportSize == null) return;

    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

    final nextMatrix = currentMatrix.clone()
      ..translate(center.dx, center.dy)
      ..scale(effectiveFactor)
      ..translate(-center.dx, -center.dy);

    _transformationController.value = nextMatrix;
  }

  void _toggleStatusCard() {
    setState(() {
      _showStatusCard = !_showStatusCard;
    });
  }

  void _toggleLegendCard() {
    setState(() {
      _showLegendCard = !_showLegendCard;
    });
  }

  void _updateLegendPosition(DragUpdateDetails details) {
    final stackSize = _stackSize;
    if (stackSize == null) return;

    const double legendWidth = 170;
    const double legendHeight = 150;

    final double nextDx = (_legendOffset.dx + details.delta.dx)
        .clamp(0.0, math.max(0.0, stackSize.width - legendWidth))
        .toDouble();

    final double nextDy = (_legendOffset.dy + details.delta.dy)
        .clamp(0.0, math.max(0.0, stackSize.height - legendHeight))
        .toDouble();

    setState(() {
      _legendOffset = Offset(nextDx, nextDy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Consumer2<RobotViewModel, WebsocketProvider>(
        builder: (context, robotViewModel, wsProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              _stackSize = Size(constraints.maxWidth, constraints.maxHeight);

              return Stack(
                key: _stackKey,
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey.shade100,
                      child: _buildMapContent(
                        robotViewModel.robotSettingList,
                        wsProvider,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 10,
                    child: _MapControls(
                      onZoomIn: _zoomIn,
                      onZoomOut: _zoomOut,
                      onFitView: _fitView,
                      onToggleStatus: _toggleStatusCard,
                      onToggleLegend: _toggleLegendCard,
                      isStatusVisible: _showStatusCard,
                      isLegendVisible: _showLegendCard,
                    ),
                  ),
                  if (_showStatusCard)
                    Positioned(
                      top: 5,
                      left: 72,
                      right: 16,
                      child: Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _buildStatusText(robotViewModel, wsProvider),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_showLegendCard)
                    Positioned(
                      left: _legendOffset.dx,
                      top: _legendOffset.dy,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: _updateLegendPosition,
                        child: const _DraggableLegendCard(),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _fetchMapData();
          await _loadRobots();
          context.read<WebsocketProvider>().sendCommand(1006);
        },
        child: _isMapLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildMapContent(
    List<RobotInfo> robots,
    WebsocketProvider wsProvider,
  ) {
    if (_isMapLoading && _mapData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mapError != null && _mapData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _mapError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_mapData == null) {
      return const Center(child: Text('Press refresh to load map'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastViewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        final viewport = _MapViewport(
          minX: _mapData!.header.minPos.x,
          minY: _mapData!.header.minPos.y,
          maxX: _mapData!.header.maxPos.x,
          maxY: _mapData!.header.maxPos.y,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: 24,
        );

        return ClipRect(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minScale,
            maxScale: _maxScale,
            boundaryMargin: const EdgeInsets.all(300),
            constrained: true,
            panEnabled: true,
            scaleEnabled: true,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SMapPainter(
                        mapData: _mapData!,
                        viewport: viewport,
                      ),
                    ),
                  ),
                  ..._buildRobotMarkers(
                    robots: robots,
                    viewport: viewport,
                    wsProvider: wsProvider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRobotMarkers({
    required List<RobotInfo> robots,
    required _MapViewport viewport,
    required WebsocketProvider wsProvider,
  }) {
    if (_mapData == null) return [];

    final markers = <Widget>[];

    for (final robot in robots) {
      final pose = wsProvider.getRobotPose(robot.id);

      if (pose == null) continue;

      final offset = viewport.toOffset(pose.x, pose.y);

      final scaledRobotWidth = kRobotBodyWidth * viewport.scale;
      final scaledRobotHeight = kRobotBodyHeight * viewport.scale;

      markers.add(
        Positioned(
          left: offset.dx - (scaledRobotWidth / 2),
          top: offset.dy - (scaledRobotHeight / 2),
          child: _RobotMarker(
            robot: robot,
            theta: pose.theta,
            isOnline: pose.online,
            posX: pose.x,
            posY: pose.y,
            bodyWidth: scaledRobotWidth,
            bodyHeight: scaledRobotHeight,
          ),
        ),
      );
    }

    return markers;
  }

  String _buildStatusText(
    RobotViewModel robotViewModel,
    WebsocketProvider wsProvider,
  ) {
    final mapName = _mapData?.header.mapName ?? '-';
    final robotCount = robotViewModel.robotSettingList.length;
    final liveCount = wsProvider.robotPoses.length;

    if (_isMapLoading) {
      return 'Loading map "$mapName"...';
    }

    if (_mapError != null) {
      return 'Map error: $_mapError';
    }

    return 'Map: $mapName • Robots: $robotCount • Live pose: $liveCount • WebSocket 1006 / 1s';
  }
}

class _RobotMarker extends StatelessWidget {
  final RobotInfo robot;
  final double? theta;
  final bool isOnline;
  final double? posX;
  final double? posY;
  final double bodyWidth;
  final double bodyHeight;

  const _RobotMarker({
    required this.robot,
    this.theta,
    required this.isOnline,
    this.posX,
    this.posY,
    required this.bodyWidth,
    required this.bodyHeight,
  });

  Color _getBodyColor() {
    return isOnline ? const Color(0xFFE83E9C) : Colors.grey;
  }

  Color _getArrowColor() {
    return isOnline ? Colors.greenAccent : Colors.grey;
  }

  Color _getTextColor() {
    return isOnline ? Colors.greenAccent : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final angleRad = theta ?? 0.0;

    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: bodyWidth,
        height: bodyHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -angleRad,
              child: SizedBox(
                width: bodyWidth,
                height: bodyHeight,
                child: CustomPaint(
                  painter: _RobotShapePainter(
                    bodyColor: _getBodyColor().withValues(alpha: 0.8),
                    arrowColor: _getArrowColor(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: bodyHeight + 4,
              left: -40,
              width: 96,
              child: Column(
                children: [
                  Text(
                    robot.id,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(),
                    ),
                  ),
                  Text(
                    robot.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotShapePainter extends CustomPainter {
  final Color bodyColor;
  final Color arrowColor;

  const _RobotShapePainter({required this.bodyColor, required this.arrowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, size.width * 0.03);

    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.04)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final bodyWidth = w;
    // final bodyWidth = w * 0.78;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyWidth, h),
      Radius.circular(h * 0.22),
    );

    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    final cy = h / 2;
    final arrowStart = Offset(bodyWidth, cy);
    final arrowTip = Offset(w, cy);
    final arrowWingTop = Offset(w - w * 0.14, cy - h * 0.22);
    final arrowWingBottom = Offset(w - w * 0.14, cy + h * 0.22);

    canvas.drawLine(arrowStart, arrowTip, arrowPaint);
    canvas.drawLine(arrowWingTop, arrowTip, arrowPaint);
    canvas.drawLine(arrowWingBottom, arrowTip, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _RobotShapePainter oldDelegate) {
    return oldDelegate.bodyColor != bodyColor ||
        oldDelegate.arrowColor != arrowColor;
  }
}

class _LegendPoint extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendPoint({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendLine({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 18, height: 2, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitView;
  final VoidCallback onToggleStatus;
  final VoidCallback onToggleLegend;
  final bool isStatusVisible;
  final bool isLegendVisible;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitView,
    required this.onToggleStatus,
    required this.onToggleLegend,
    required this.isStatusVisible,
    required this.isLegendVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.grey.withOpacity(0.65),
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
              icon: const Icon(Icons.add),
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            IconButton(
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove),
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            IconButton(
              tooltip: 'Fit view',
              onPressed: onFitView,
              icon: const Icon(Icons.fit_screen),
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            IconButton(
              tooltip: isStatusVisible ? 'Hide status' : 'Show status',
              onPressed: onToggleStatus,
              icon: Icon(
                isStatusVisible ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            IconButton(
              tooltip: isLegendVisible ? 'Hide legend' : 'Show legend',
              onPressed: onToggleLegend,
              icon: Icon(
                isLegendVisible ? Icons.list_alt : Icons.list_alt_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableLegendCard extends StatelessWidget {
  const _DraggableLegendCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 170,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Row(
                children: [
                  Icon(Icons.open_with, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              _LegendLine(color: Colors.black87, label: 'Route'),
              _LegendPoint(color: Colors.red, label: 'Traffic point'),
              _LegendPoint(color: Colors.black, label: 'Map points'),
              _LegendPoint(color: Colors.green, label: 'Robot online'),
              _LegendPoint(color: Colors.grey, label: 'Robot offline'),
            ],
          ),
        ),
      ),
    );
  }
}

class SMapPainter extends CustomPainter {
  final SMapData mapData;
  final _MapViewport viewport;

  const SMapPainter({required this.mapData, required this.viewport});

  @override
  void paint(Canvas canvas, Size size) {
    _drawRoutes(canvas);
    _drawNormalPoints(canvas);
    _drawAdvancedPoints(canvas);
  }

  void _drawNormalPoints(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (final point in mapData.normalPosList) {
      final offset = viewport.toOffset(point.x, point.y);
      canvas.drawPoints(PointMode.points, [offset], paint);
    }
  }

  void _drawAdvancedPoints(Canvas canvas) {
    final fillPaint = Paint()..color = Colors.redAccent;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final point in mapData.advancedPointList) {
      final offset = viewport.toOffset(point.pos.x, point.pos.y);
      canvas.drawCircle(offset, 6, fillPaint);
      canvas.drawCircle(offset, 6, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: point.instanceName,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(offset.dx - textPainter.width / 2, offset.dy + 8),
      );
    }
  }

  void _drawRoutes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final route in mapData.advancedRouteList) {
      final start = viewport.toOffset(
        route.startPos.pos.x,
        route.startPos.pos.y,
      );
      final end = viewport.toOffset(route.endPos.pos.x, route.endPos.pos.y);

      final hasControl1 = route.controlPos1 != null;
      final hasControl2 = route.controlPos2 != null;

      if (hasControl1 && hasControl2) {
        final c1 = viewport.toOffset(
          route.controlPos1!.x,
          route.controlPos1!.y,
        );
        final c2 = viewport.toOffset(
          route.controlPos2!.x,
          route.controlPos2!.y,
        );

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

        canvas.drawPath(path, paint);
      } else if (hasControl1) {
        final c1 = viewport.toOffset(
          route.controlPos1!.x,
          route.controlPos1!.y,
        );

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(c1.dx, c1.dy, end.dx, end.dy);

        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SMapPainter oldDelegate) {
    return oldDelegate.mapData != mapData || oldDelegate.viewport != viewport;
  }
}

class _MapViewport {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final double width;
  final double height;
  final double padding;

  const _MapViewport({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.width,
    required this.height,
    this.padding = 16,
  });

  double get scale {
    final usableWidth = math.max(1.0, width - padding * 2);
    final usableHeight = math.max(1.0, height - padding * 2);

    final mapWidth = math.max(0.0001, maxX - minX);
    final mapHeight = math.max(0.0001, maxY - minY);

    return math.min(usableWidth / mapWidth, usableHeight / mapHeight);
  }

  Offset toOffset(double x, double y) {
    final usableWidth = math.max(1.0, width - padding * 2);
    final usableHeight = math.max(1.0, height - padding * 2);

    final mapWidth = math.max(0.0001, maxX - minX);
    final mapHeight = math.max(0.0001, maxY - minY);

    final scale = math.min(usableWidth / mapWidth, usableHeight / mapHeight);

    final drawnWidth = mapWidth * scale;
    final drawnHeight = mapHeight * scale;

    final offsetX = (width - drawnWidth) / 2;
    final offsetY = (height - drawnHeight) / 2;

    final px = offsetX + (x - minX) * scale;
    final py = offsetY + (maxY - y) * scale;

    return Offset(px, py);
  }

  @override
  bool operator ==(Object other) {
    return other is _MapViewport &&
        other.minX == minX &&
        other.minY == minY &&
        other.maxX == maxX &&
        other.maxY == maxY &&
        other.width == width &&
        other.height == height &&
        other.padding == padding;
  }

  @override
  int get hashCode =>
      Object.hash(minX, minY, maxX, maxY, width, height, padding);
}

class SMapData {
  final SMapHeader header;
  final List<SMapPoint> normalPosList;
  final List<SMapAdvancedPoint> advancedPointList;
  final List<SMapRoute> advancedRouteList;

  const SMapData({
    required this.header,
    required this.normalPosList,
    required this.advancedPointList,
    required this.advancedRouteList,
  });

  factory SMapData.fromJson(Map<String, dynamic> json) {
    return SMapData(
      header: SMapHeader.fromJson(json['header'] as Map<String, dynamic>),
      normalPosList: (json['normalPosList'] as List<dynamic>? ?? [])
          .map((e) => SMapPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      advancedPointList: (json['advancedPointList'] as List<dynamic>? ?? [])
          .map((e) => SMapAdvancedPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      advancedRouteList: (json['advancedRouteList'] as List<dynamic>? ?? [])
          .map((e) => SMapRoute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SMapHeader {
  final String mapType;
  final String mapName;
  final SMapPoint minPos;
  final SMapPoint maxPos;
  final double resolution;
  final String version;

  const SMapHeader({
    required this.mapType,
    required this.mapName,
    required this.minPos,
    required this.maxPos,
    required this.resolution,
    required this.version,
  });

  factory SMapHeader.fromJson(Map<String, dynamic> json) {
    return SMapHeader(
      mapType: json['mapType']?.toString() ?? '',
      mapName: json['mapName']?.toString() ?? '',
      minPos: SMapPoint.fromJson(json['minPos'] as Map<String, dynamic>),
      maxPos: SMapPoint.fromJson(json['maxPos'] as Map<String, dynamic>),
      resolution: (json['resolution'] as num?)?.toDouble() ?? 0,
      version: json['version']?.toString() ?? '',
    );
  }
}

class SMapPoint {
  final double x;
  final double y;

  const SMapPoint({required this.x, required this.y});

  factory SMapPoint.fromJson(Map<String, dynamic> json) {
    return SMapPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SMapAdvancedPoint {
  final String className;
  final String instanceName;
  final String instanceId;
  final SMapPoint pos;
  final bool ignoreDir;

  const SMapAdvancedPoint({
    required this.className,
    required this.instanceName,
    required this.instanceId,
    required this.pos,
    required this.ignoreDir,
  });

  factory SMapAdvancedPoint.fromJson(Map<String, dynamic> json) {
    return SMapAdvancedPoint(
      className: json['className']?.toString() ?? '',
      instanceName: json['instanceName']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? '',
      pos: SMapPoint.fromJson(json['pos'] as Map<String, dynamic>),
      ignoreDir: json['ignoreDir'] as bool? ?? false,
    );
  }
}

class SMapRouteEndpoint {
  final String instanceName;
  final String instanceId;
  final SMapPoint pos;

  const SMapRouteEndpoint({
    required this.instanceName,
    required this.instanceId,
    required this.pos,
  });

  factory SMapRouteEndpoint.fromJson(Map<String, dynamic> json) {
    return SMapRouteEndpoint(
      instanceName: json['instanceName']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? '',
      pos: SMapPoint.fromJson(json['pos'] as Map<String, dynamic>),
    );
  }
}

class SMapRoute {
  final String className;
  final String instanceName;
  final String instanceId;
  final SMapRouteEndpoint startPos;
  final SMapRouteEndpoint endPos;
  final SMapPoint? controlPos1;
  final SMapPoint? controlPos2;

  const SMapRoute({
    required this.className,
    required this.instanceName,
    required this.instanceId,
    required this.startPos,
    required this.endPos,
    this.controlPos1,
    this.controlPos2,
  });

  factory SMapRoute.fromJson(Map<String, dynamic> json) {
    return SMapRoute(
      className: json['className']?.toString() ?? '',
      instanceName: json['instanceName']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? '',
      startPos: SMapRouteEndpoint.fromJson(
        json['startPos'] as Map<String, dynamic>,
      ),
      endPos: SMapRouteEndpoint.fromJson(
        json['endPos'] as Map<String, dynamic>,
      ),
      controlPos1: _tryParsePoint(json['controlPos1']),
      controlPos2: _tryParsePoint(json['controlPos2']),
    );
  }

  static SMapPoint? _tryParsePoint(dynamic value) {
    if (value is Map<String, dynamic> &&
        value.containsKey('x') &&
        value.containsKey('y')) {
      return SMapPoint.fromJson(value);
    }
    return null;
  }
}
