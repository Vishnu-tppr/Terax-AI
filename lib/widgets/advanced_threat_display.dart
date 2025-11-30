import 'package:flutter/material.dart';

/// Advanced Threat Display Widget - Shows comprehensive threat analysis results
class AdvancedThreatDisplay extends StatelessWidget {
  final Map<String, dynamic> analysisResult;
  final VoidCallback? onSendAlert;
  final VoidCallback? onDismiss;

  const AdvancedThreatDisplay({
    super.key,
    required this.analysisResult,
    this.onSendAlert,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final situationAssessment = analysisResult['situation_assessment'] as Map<String, dynamic>?;
    final voiceAnalysis = analysisResult['voice_analysis'] as Map<String, dynamic>?;
    final recommendation = analysisResult['recommendation'] as Map<String, dynamic>?;
    final preventiveAlert = analysisResult['preventive_alert'] as Map<String, dynamic>?;
    final advancedAnalytics = analysisResult['advanced_analytics'] as Map<String, dynamic>?;
    
    final threatLevel = situationAssessment?['threat_level'] as String? ?? 'LOW';
    final threatType = situationAssessment?['threat_type'] as String? ?? 'none';
    final confidence = (analysisResult['confidence_overall_percent'] as num?)?.toInt() ?? 0;
    
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _getThreatGradient(threatLevel),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(threatLevel, threatType, confidence),
              const SizedBox(height: 16),
              _buildThreatAnalysis(situationAssessment),
              const SizedBox(height: 12),
              _buildVoiceAnalysis(voiceAnalysis),
              const SizedBox(height: 12),
              _buildRecommendations(recommendation),
              const SizedBox(height: 12),
              _buildSafetyInformation(preventiveAlert),
              if (advancedAnalytics != null) ...[
                const SizedBox(height: 12),
                _buildAdvancedAnalytics(advancedAnalytics),
              ],
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String threatLevel, String threatType, int confidence) {
    return Row(
      children: [
        Icon(
          _getThreatIcon(threatLevel),
          color: _getThreatColor(threatLevel),
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TeraxAI Elite Analysis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 10, 10, 10),
                ),
              ),
              Text(
                'Threat Level: $threatLevel • Type: ${_formatThreatType(threatType)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(179, 10, 10, 10),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 4, 4, 4).withValues(alpha: (0.2 * 255).toDouble()),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$confidence%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 4, 4, 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreatAnalysis(Map<String, dynamic>? situationAssessment) {
    if (situationAssessment == null) return const SizedBox.shrink();
    
    final escalationProbability = (situationAssessment['escalation_probability'] as num?)?.toDouble();
    final timeToIntervention = situationAssessment['time_to_intervention_minutes'] as int?;
    final behavioralAnomalies = situationAssessment['behavioral_anomalies'] as Map<String, dynamic>?;
    final geospatialRisk = situationAssessment['geospatial_risk'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 5, 5).withValues(alpha: (0.1 * 255).toDouble()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Threat Assessment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 254, 250, 1),
            ),
          ),
          const SizedBox(height: 8),
          if (escalationProbability != null)
            _buildAnalysisRow('Escalation Risk', '${(escalationProbability * 100).toInt()}%'),
          if (timeToIntervention != null)
            _buildAnalysisRow('Intervention Window', '$timeToIntervention minutes'),
          if (behavioralAnomalies != null) ...[
            _buildAnalysisRow('Location Deviation', 
                '${((behavioralAnomalies['location_deviation'] as num? ?? 0) * 100).toInt()}%'),
            _buildAnalysisRow('Timing Unusual', 
                behavioralAnomalies['timing_unusual'] == true ? 'Yes' : 'No'),
          ],
          if (geospatialRisk != null) ...[
            _buildAnalysisRow('Area Risk Level', 
                '${((geospatialRisk['crime_index'] as num? ?? 0) * 100).toInt()}%'),
            _buildAnalysisRow('Safe Zone Distance', 
                '${geospatialRisk['safe_zone_distance_km'] ?? 'Unknown'} km'),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceAnalysis(Map<String, dynamic>? voiceAnalysis) {
    if (voiceAnalysis == null) return const SizedBox.shrink();
    
    final distressPercent = voiceAnalysis['distress_percent'] as int?;
    final primaryEmotion = voiceAnalysis['primary_emotion'] as String?;
    final threatIndicators = voiceAnalysis['threat_indicators'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 7, 7, 7).withValues(alpha: (0.1 * 255).toDouble()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎤 Voice Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 179, 250, 1),
            ),
          ),
          const SizedBox(height: 8),
          if (distressPercent != null)
            _buildAnalysisRow('Distress Level', '$distressPercent%'),
          if (primaryEmotion != null)
            _buildAnalysisRow('Primary Emotion', _formatEmotion(primaryEmotion)),
          if (threatIndicators != null) ...[
            if (threatIndicators['coercion_detected'] == true)
              _buildAnalysisRow('Coercion Detected', '⚠️ Yes'),
            if (threatIndicators['duress_code_used'] == true)
              _buildAnalysisRow('Duress Code', '🚨 Detected'),
            if ((threatIndicators['social_engineering'] as num? ?? 0) > 0.5)
              _buildAnalysisRow('Social Engineering', '⚠️ Possible'),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations(Map<String, dynamic>? recommendation) {
    if (recommendation == null) return const SizedBox.shrink();
    
    final action = recommendation['action'] as String?;
    final priorityLevel = recommendation['priority_level'] as String?;
    final responseTime = recommendation['response_time_required'] as String?;
    final specializedResponse = recommendation['specialized_response'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 5, 5).withValues(alpha: (0.1 * 255).toDouble()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 AI Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (action != null)
            _buildAnalysisRow('Recommended Action', _formatAction(action)),
          if (priorityLevel != null)
            _buildAnalysisRow('Priority Level', priorityLevel),
          if (responseTime != null)
            _buildAnalysisRow('Response Time', responseTime),
          if (specializedResponse != null) ...[
            ...specializedResponse.entries
                .where((e) => e.value == true)
                .map((e) => _buildAnalysisRow('Specialized Response', _formatSpecializedResponse(e.key))),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyInformation(Map<String, dynamic>? preventiveAlert) {
    if (preventiveAlert == null) return const SizedBox.shrink();
    
    final safetyActions = preventiveAlert['safety_actions'] as List<dynamic>?;
    final escapeRoutes = preventiveAlert['escape_routes'] as List<dynamic>?;
    final nearbyHelp = preventiveAlert['nearby_help'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 3, 3, 3).withValues(alpha: (0.1 * 255).toDouble()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛡️ Safety Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (safetyActions != null && safetyActions.isNotEmpty) ...[
            _buildAnalysisRow('Safety Actions', safetyActions.cast<String>().join(', ')),
          ],
          if (escapeRoutes != null && escapeRoutes.isNotEmpty) ...[
            _buildAnalysisRow('Escape Routes', escapeRoutes.cast<String>().join(', ')),
          ],
          if (nearbyHelp != null && nearbyHelp.isNotEmpty) ...[
            ...nearbyHelp.entries.map((e) => _buildAnalysisRow(e.key, e.value.toString())),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedAnalytics(Map<String, dynamic> advancedAnalytics) {
    final patternRecognition = advancedAnalytics['pattern_recognition'] as Map<String, dynamic>?;
    final predictiveModeling = advancedAnalytics['predictive_modeling'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: (0.1 * 255).toDouble()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠 Advanced Analytics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (patternRecognition != null) ...[
            if ((patternRecognition['stalking_score'] as num? ?? 0) > 0.5)
              _buildAnalysisRow('Stalking Pattern', '${((patternRecognition['stalking_score'] as num) * 100).toInt()}%'),
            if ((patternRecognition['routine_deviation'] as num? ?? 0) > 0.5)
              _buildAnalysisRow('Routine Deviation', '${((patternRecognition['routine_deviation'] as num) * 100).toInt()}%'),
          ],
          if (predictiveModeling != null) ...[
            if (predictiveModeling['escalation_timeline'] != null)
              _buildAnalysisRow('Escalation Timeline', predictiveModeling['escalation_timeline'].toString()),
            if (predictiveModeling['intervention_window'] != null)
              _buildAnalysisRow('Intervention Window', predictiveModeling['intervention_window'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSendAlert,
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text(
              'Send Alert',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text(
              'Dismiss',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for formatting and styling
  LinearGradient _getThreatGradient(String threatLevel) {
    switch (threatLevel.toUpperCase()) {
      case 'CRITICAL':
        return const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFDC143C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'HIGH':
        return const LinearGradient(
          colors: [Color(0xFFFF4500), Color(0xFFFF6347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'MEDIUM':
        return const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF4169E1), Color(0xFF6495ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getThreatColor(String threatLevel) {
    switch (threatLevel.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade900;
      case 'HIGH':
        return Colors.red.shade600;
      case 'MEDIUM':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getThreatIcon(String threatLevel) {
    switch (threatLevel.toUpperCase()) {
      case 'CRITICAL':
        return Icons.dangerous;
      case 'HIGH':
        return Icons.warning;
      case 'MEDIUM':
        return Icons.info;
      default:
        return Icons.security;
    }
  }

  String _formatThreatType(String threatType) {
    return threatType.replaceAll('_', ' ').split(' ').map((word) => 
        word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatEmotion(String emotion) {
    final emotionMap = {
      'panic': '😰 Panic',
      'fear': '😨 Fear',
      'anger': '😠 Anger',
      'sad': '😢 Sadness',
      'neutral': '😐 Neutral',
      'uncertain': '🤔 Uncertain',
    };
    return emotionMap[emotion] ?? emotion;
  }

  String _formatAction(String action) {
    final actionMap = {
      'auto_send': '🚨 Auto Send Alert',
      'confirm_send': '❓ Confirm Before Sending',
      'monitor': '👁️ Monitor Situation',
      'preventive_alert': '⚠️ Preventive Warning',
      'escalate_authorities': '🚔 Contact Authorities',
      'stealth_mode': '🤫 Stealth Mode',
      'lockdown_mode': '🔒 Lockdown Protocol',
      'safe_word_protocol': '🔑 Safe Word Protocol',
    };
    return actionMap[action] ?? action;
  }

  String _formatSpecializedResponse(String responseType) {
    final responseMap = {
      'law_enforcement': '🚔 Law Enforcement',
      'medical_emergency': '🚑 Medical Emergency',
      'child_protective_services': '👶 Child Protection',
      'domestic_violence_hotline': '🏠 Domestic Violence',
      'mental_health_crisis': '🧠 Mental Health Crisis',
      'school_security': '🏫 School Security',
    };
    return responseMap[responseType] ?? responseType;
  }
}
