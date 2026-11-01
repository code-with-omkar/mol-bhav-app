import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';

/// Debug builds only: which server the app talks to, with a way to change it
/// and to test it. The usual "No internet connection" on a phone is the PC's
/// address having changed (another Wi-Fi), and this fixes it without a rebuild.
class ServerAddressTile extends StatefulWidget {
  const ServerAddressTile({super.key, this.onChanged});

  /// Called after a new address is saved, so the screen can retry its calls.
  final VoidCallback? onChanged;

  @override
  State<ServerAddressTile> createState() => _ServerAddressTileState();
}

class _ServerAddressTileState extends State<ServerAddressTile> {
  Future<void> _edit() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _ServerDialog(),
    );
    if (saved ?? false) {
      setState(() {});
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Padding(
      padding: const EdgeInsets.only(top: MbSpacing.s3),
      child: InkWell(
        onTap: _edit,
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s2),
          child: Text(
            'Server: ${Uri.parse(ApiConfig.baseUrl).authority}'
            '${ApiConfig.isOverridden ? ' (changed)' : ''} · change',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: c.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _ServerDialog extends StatefulWidget {
  const _ServerDialog();

  @override
  State<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<_ServerDialog> {
  late final _controller = TextEditingController(text: ApiConfig.baseUrl);
  String? _result;
  bool _ok = false;
  bool _testing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = normalizeServerAddress(_controller.text);
    if (url == null) {
      setState(() {
        _ok = false;
        _result = 'That is not a valid address.';
      });
      return;
    }
    setState(() {
      _testing = true;
      _result = null;
    });
    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      ).get<void>('$url/auth/methods');
      if (!mounted) return;
      setState(() {
        _ok = response.statusCode == 200;
        _result = _ok ? 'Connected.' : 'Answered with ${response.statusCode}.';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _ok = false;
        _result =
            'Can\'t reach $url — is the API running, and is this the PC\'s '
            'current address? (${e.type.name})';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _apply(String? url) async {
    await ApiConfig.save(getIt<SharedPreferences>(), url);
    // The client was created with the old address.
    getIt<Dio>().options.baseUrl = ApiConfig.baseUrl;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final url = normalizeServerAddress(_controller.text);
    return AlertDialog(
      title: const Text('Server address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: '192.168.1.14:5189',
              helperText: 'The PC running the API. Same Wi-Fi as this phone.',
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() => _result = null),
          ),
          if (_testing)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _result!,
                style: TextStyle(
                  color: _ok ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : _test,
          child: const Text('Test'),
        ),
        TextButton(
          onPressed: ApiConfig.isOverridden ? () => _apply(null) : null,
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: url == null ? null : () => _apply(url),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
