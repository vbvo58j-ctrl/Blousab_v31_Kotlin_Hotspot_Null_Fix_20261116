import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Blousab-owned media browser. Assets stay on the phone; only the explicitly
/// tapped asset is copied by PhotoManager to a readable temporary path.
class BlousabDeviceGallery extends StatefulWidget {
  const BlousabDeviceGallery({super.key});

  @override
  State<BlousabDeviceGallery> createState() => _BlousabDeviceGalleryState();
}

class _BlousabDeviceGalleryState extends State<BlousabDeviceGallery> {
  final Map<RequestType, List<AssetEntity>> _items = {
    RequestType.image: <AssetEntity>[],
    RequestType.video: <AssetEntity>[],
  };
  final Map<RequestType, bool> _done = {
    RequestType.image: false,
    RequestType.video: false,
  };
  final Set<RequestType> _busy = <RequestType>{};
  bool _denied = false;

  @override
  void initState() { super.initState(); _prepare(); }

  Future<void> _prepare() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.hasAccess) { if (mounted) setState(() => _denied = true); return; }
      await Future.wait([_more(RequestType.image), _more(RequestType.video)]);
    } catch (_) { if (mounted) setState(() => _denied = true); }
  }

  Future<void> _more(RequestType type) async {
    if (_busy.contains(type) || _done[type] == true) return;
    _busy.add(type);
    try {
      final page = _items[type]!.length ~/ 80;
      final next = await PhotoManager.getAssetListPaged(type: type, page: page, pageCount: 80);
      if (!mounted) return;
      setState(() {
        _items[type]!.addAll(next);
        if (next.length < 80) _done[type] = true;
      });
    } finally { _busy.remove(type); }
  }

  Future<void> _select(AssetEntity asset) async {
    try {
      final File? file = await asset.file;
      if (file != null && mounted) Navigator.pop(context, (path: file.path, video: asset.type == AssetType.video));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر قراءة الوسائط المحددة')));
    }
  }

  Widget _gallery(RequestType type) {
    final assets = _items[type]!;
    if (_denied) return Center(child: TextButton.icon(onPressed: PhotoManager.openSetting,
      icon: const Icon(Icons.settings), label: const Text('السماح لبلوساب بقراءة المعرض من الإعدادات')));
    if (assets.isEmpty) return const Center(child: Text('لا توجد وسائط متاحة، أو جارٍ تحميلها'));
    return NotificationListener<ScrollNotification>(
      onNotification: (notice) {
        if (notice.metrics.pixels >= notice.metrics.maxScrollExtent - 600) _more(type);
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 5, mainAxisSpacing: 5),
        itemCount: assets.length,
        itemBuilder: (context, i) {
          final asset = assets[i];
          return InkWell(
            onTap: () => _select(asset),
            child: Stack(fit: StackFit.expand, children: [
              FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(const ThumbnailSize(220, 220)),
                builder: (context, snap) => snap.hasData && snap.data != null
                    ? Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true)
                    : Container(color: const Color(0xFF192440), child: const Icon(Icons.image)),
              ),
              if (type == RequestType.video) const Align(alignment: Alignment.bottomRight,
                child: Padding(padding: EdgeInsets.all(6), child: Icon(Icons.play_circle_fill, color: Colors.white))),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(title: const Text('معرض بلوساب'),
        bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.photo_library), text: 'الصور'),
          Tab(icon: Icon(Icons.video_library), text: 'الفيديوهات')])),
      body: TabBarView(children: [_gallery(RequestType.image), _gallery(RequestType.video)]),
    ),
  );
}
