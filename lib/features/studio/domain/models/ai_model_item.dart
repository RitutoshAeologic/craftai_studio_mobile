/// Represents an AI generation/editing model returned by `GET /api/v1/models`
/// or seeded locally for offline / cold-start resilience.
class AiModelItem {
  final String modelKey;
  final String displayName;
  final String providerKey;
  final List<String> tasks;
  final String tier;
  final double creditCost;
  final bool isAvailable;
  final String activeMode; // 'paid_api' | 'local_fallback'
  final Map<String, dynamic> capabilities;
  final String? description;
  final String? icon;

  const AiModelItem({
    required this.modelKey,
    required this.displayName,
    required this.providerKey,
    required this.tasks,
    required this.tier,
    required this.creditCost,
    required this.isAvailable,
    required this.activeMode,
    this.capabilities = const {},
    this.description,
    this.icon,
  });

  factory AiModelItem.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'];
    final parsedTasks = rawTasks is List
        ? rawTasks.map((e) => e.toString()).toList()
        : const <String>['text_to_image'];

    final rawCaps = json['capabilities'];
    final parsedCaps = rawCaps is Map
        ? Map<String, dynamic>.from(rawCaps)
        : const <String, dynamic>{};

    final key = (json['model_key'] ?? json['id'] ?? 'auto').toString();
    final mode = (json['active_mode'] ?? 'local_fallback').toString();

    return AiModelItem(
      modelKey: key,
      displayName: (json['display_name'] ?? json['name'] ?? key).toString(),
      providerKey: (json['provider_key'] ?? 'local').toString(),
      tasks: parsedTasks,
      tier: (json['tier'] ?? 'standard').toString(),
      creditCost: (json['credit_cost'] as num?)?.toDouble() ?? 2.0,
      isAvailable: json['is_available'] as bool? ?? true,
      activeMode: mode,
      capabilities: parsedCaps,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'model_key': modelKey,
        'display_name': displayName,
        'provider_key': providerKey,
        'tasks': tasks,
        'tier': tier,
        'credit_cost': creditCost,
        'is_available': isAvailable,
        'active_mode': activeMode,
        'capabilities': capabilities,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
      };

  /// Whether this model supports the given studio task
  /// (`text_to_image`, `image_edit`, `face_lock_remix`).
  bool supportsTask(String task) {
    if (modelKey == 'auto') return true;
    if (tasks.contains(task)) return true;
    // Allow capabilities boolean override for face_lock_remix
    if (task == 'face_lock_remix' && capabilities['supports_facelock'] == true) {
      return true;
    }
    return false;
  }

  /// Derives UI capability tags (`Fast`, `Face-Lock`, `Edit`, `HD`) for chips.
  List<String> get capabilityTags {
    final tags = <String>[];
    if (tier == 'economy' || modelKey.contains('schnell') || modelKey.contains('flash')) {
      tags.add('Fast');
    }
    if (tasks.contains('face_lock_remix') || capabilities['supports_facelock'] == true) {
      tags.add('Face-Lock');
    }
    if (tasks.contains('image_edit')) {
      tags.add('Edit');
    }
    if (tier == 'premium' || tier == 'standard' || activeMode == 'paid_api') {
      tags.add('HD');
    }
    return tags;
  }

  bool get isPaidCloud => activeMode == 'paid_api';

  String get modeBadgeLabel => isPaidCloud ? 'HD Cloud' : 'Local Engine';

  String get creditsLabel {
    if (creditCost == creditCost.roundToDouble()) {
      return '${creditCost.toInt()} Cr';
    }
    return '${creditCost.toStringAsFixed(1)} Cr';
  }

  String get resolvedIcon {
    if (icon != null && icon!.isNotEmpty) return icon!;
    if (modelKey == 'auto') return '✨';
    if (modelKey.contains('pulid') || tasks.contains('face_lock_remix')) return '🎭';
    if (providerKey == 'google' || modelKey.contains('gemini')) return '🎨';
    if (providerKey == 'openai' || modelKey.contains('gpt')) return '🤖';
    if (providerKey == 'fal' || modelKey.contains('flux')) return '⚡';
    return '🖥️';
  }

  /// Converts to legacy `Map<String, String>` shape for backward compatibility.
  Map<String, String> toLegacyMap() => {
        'id': modelKey,
        'name': displayName,
        'desc': description ?? '$modeBadgeLabel • ${capabilityTags.join(' • ')}',
        'badge': modeBadgeLabel,
        'credits': creditsLabel,
        'icon': resolvedIcon,
      };

  /// Hardcoded static fallback catalog so the picker never renders empty
  /// offline, on cold-start, or during tunnel reconnects.
  static const List<AiModelItem> defaultSeedCatalog = [
    AiModelItem(
      modelKey: 'auto',
      displayName: 'Auto (Recommended)',
      providerKey: 'auto',
      tasks: ['text_to_image', 'image_edit', 'face_lock_remix'],
      tier: 'standard',
      creditCost: 2.0,
      isAvailable: true,
      activeMode: 'local_fallback',
      capabilities: {
        'supports_facelock': true,
        'supports_negative_prompt': true,
      },
      description: 'Smart routing • Best available engine without overcharging',
      icon: '✨',
    ),
    AiModelItem(
      modelKey: 'local_sdxl',
      displayName: 'Local SDXL',
      providerKey: 'local',
      tasks: ['text_to_image', 'image_edit', 'face_lock_remix'],
      tier: 'economy',
      creditCost: 2.0,
      isAvailable: true,
      activeMode: 'local_fallback',
      capabilities: {
        'supports_facelock': true,
        'supports_negative_prompt': true,
      },
      description: 'Free local diffusion engine • Fast & reliable',
      icon: '🖥️',
    ),
    AiModelItem(
      modelKey: 'flux_schnell',
      displayName: 'FLUX.1 Schnell',
      providerKey: 'fal',
      tasks: ['text_to_image'],
      tier: 'standard',
      creditCost: 2.0,
      isAvailable: false,
      activeMode: 'paid_api',
      capabilities: {
        'supports_facelock': false,
        'supports_negative_prompt': false,
      },
      description: 'Ultra-fast photorealism (requires FAL_API_KEY in Supabase)',
      icon: '⚡',
    ),
  ];
}
