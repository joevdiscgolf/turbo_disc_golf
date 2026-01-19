// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_endpoints.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokensUsed _$TokensUsedFromJson(Map json) => TokensUsed(
  prompt: (json['prompt'] as num).toInt(),
  completion: (json['completion'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$TokensUsedToJson(TokensUsed instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'completion': instance.completion,
      'total': instance.total,
    };

ParseRoundDataRequest _$ParseRoundDataRequestFromJson(Map json) =>
    ParseRoundDataRequest(
      voiceTranscript: json['voiceTranscript'] as String,
      userBag: (json['userBag'] as List<dynamic>)
          .map((e) => DGDisc.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      courseName: json['courseName'] as String?,
    );

Map<String, dynamic> _$ParseRoundDataRequestToJson(
  ParseRoundDataRequest instance,
) => <String, dynamic>{
  'voiceTranscript': instance.voiceTranscript,
  'userBag': instance.userBag.map((e) => e.toJson()).toList(),
  'courseName': instance.courseName,
};

ParseRoundDataResponseMetadata _$ParseRoundDataResponseMetadataFromJson(
  Map json,
) => ParseRoundDataResponseMetadata(
  parsedAt: json['parsedAt'] as String,
  finishReason: json['finishReason'] as String?,
);

Map<String, dynamic> _$ParseRoundDataResponseMetadataToJson(
  ParseRoundDataResponseMetadata instance,
) => <String, dynamic>{
  'parsedAt': instance.parsedAt,
  'finishReason': instance.finishReason,
};

ParseRoundDataResponseData _$ParseRoundDataResponseDataFromJson(Map json) =>
    ParseRoundDataResponseData(
      rawResponse: json['rawResponse'] as String,
      model: json['model'] as String,
      tokensUsed: json['tokensUsed'] == null
          ? null
          : TokensUsed.fromJson(
              Map<String, dynamic>.from(json['tokensUsed'] as Map),
            ),
      metadata: ParseRoundDataResponseMetadata.fromJson(
        Map<String, dynamic>.from(json['metadata'] as Map),
      ),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ParseRoundDataResponseDataToJson(
  ParseRoundDataResponseData instance,
) => <String, dynamic>{
  'rawResponse': instance.rawResponse,
  'model': instance.model,
  'tokensUsed': instance.tokensUsed?.toJson(),
  'metadata': instance.metadata.toJson(),
  'error': instance.error,
};

ParseRoundDataResponse _$ParseRoundDataResponseFromJson(Map json) =>
    ParseRoundDataResponse(
      success: json['success'] as bool,
      data: ParseRoundDataResponseData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      ),
    );

Map<String, dynamic> _$ParseRoundDataResponseToJson(
  ParseRoundDataResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data.toJson(),
};

GenerateRoundStoryRequest _$GenerateRoundStoryRequestFromJson(Map json) =>
    GenerateRoundStoryRequest(
      round: DGRound.fromJson(Map<String, dynamic>.from(json['round'] as Map)),
      analysis: RoundAnalysis.fromJson(
        Map<String, dynamic>.from(json['analysis'] as Map),
      ),
    );

Map<String, dynamic> _$GenerateRoundStoryRequestToJson(
  GenerateRoundStoryRequest instance,
) => <String, dynamic>{
  'round': instance.round.toJson(),
  'analysis': instance.analysis.toJson(),
};

GenerateRoundStoryResponseMetadata _$GenerateRoundStoryResponseMetadataFromJson(
  Map json,
) => GenerateRoundStoryResponseMetadata(
  generatedAt: json['generatedAt'] as String,
  finishReason: json['finishReason'] as String?,
);

Map<String, dynamic> _$GenerateRoundStoryResponseMetadataToJson(
  GenerateRoundStoryResponseMetadata instance,
) => <String, dynamic>{
  'generatedAt': instance.generatedAt,
  'finishReason': instance.finishReason,
};

GenerateRoundStoryResponseData _$GenerateRoundStoryResponseDataFromJson(
  Map json,
) => GenerateRoundStoryResponseData(
  rawResponse: json['rawResponse'] as String,
  model: json['model'] as String,
  tokensUsed: json['tokensUsed'] == null
      ? null
      : TokensUsed.fromJson(
          Map<String, dynamic>.from(json['tokensUsed'] as Map),
        ),
  metadata: GenerateRoundStoryResponseMetadata.fromJson(
    Map<String, dynamic>.from(json['metadata'] as Map),
  ),
  error: json['error'] as String?,
);

Map<String, dynamic> _$GenerateRoundStoryResponseDataToJson(
  GenerateRoundStoryResponseData instance,
) => <String, dynamic>{
  'rawResponse': instance.rawResponse,
  'model': instance.model,
  'tokensUsed': instance.tokensUsed?.toJson(),
  'metadata': instance.metadata.toJson(),
  'error': instance.error,
};

GenerateRoundStoryResponse _$GenerateRoundStoryResponseFromJson(Map json) =>
    GenerateRoundStoryResponse(
      success: json['success'] as bool,
      data: GenerateRoundStoryResponseData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      ),
    );

Map<String, dynamic> _$GenerateRoundStoryResponseToJson(
  GenerateRoundStoryResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data.toJson(),
};

GenerateRoundJudgmentRequest _$GenerateRoundJudgmentRequestFromJson(Map json) =>
    GenerateRoundJudgmentRequest(
      round: DGRound.fromJson(Map<String, dynamic>.from(json['round'] as Map)),
      analysis: RoundAnalysis.fromJson(
        Map<String, dynamic>.from(json['analysis'] as Map),
      ),
      shouldGlaze: json['shouldGlaze'] as bool?,
    );

Map<String, dynamic> _$GenerateRoundJudgmentRequestToJson(
  GenerateRoundJudgmentRequest instance,
) => <String, dynamic>{
  'round': instance.round.toJson(),
  'analysis': instance.analysis.toJson(),
  'shouldGlaze': instance.shouldGlaze,
};

GenerateRoundJudgmentResponseMetadata
_$GenerateRoundJudgmentResponseMetadataFromJson(Map json) =>
    GenerateRoundJudgmentResponseMetadata(
      generatedAt: json['generatedAt'] as String,
      finishReason: json['finishReason'] as String?,
    );

Map<String, dynamic> _$GenerateRoundJudgmentResponseMetadataToJson(
  GenerateRoundJudgmentResponseMetadata instance,
) => <String, dynamic>{
  'generatedAt': instance.generatedAt,
  'finishReason': instance.finishReason,
};

GenerateRoundJudgmentResponseData _$GenerateRoundJudgmentResponseDataFromJson(
  Map json,
) => GenerateRoundJudgmentResponseData(
  rawResponse: json['rawResponse'] as String,
  model: json['model'] as String,
  tokensUsed: json['tokensUsed'] == null
      ? null
      : TokensUsed.fromJson(
          Map<String, dynamic>.from(json['tokensUsed'] as Map),
        ),
  metadata: GenerateRoundJudgmentResponseMetadata.fromJson(
    Map<String, dynamic>.from(json['metadata'] as Map),
  ),
  error: json['error'] as String?,
);

Map<String, dynamic> _$GenerateRoundJudgmentResponseDataToJson(
  GenerateRoundJudgmentResponseData instance,
) => <String, dynamic>{
  'rawResponse': instance.rawResponse,
  'model': instance.model,
  'tokensUsed': instance.tokensUsed?.toJson(),
  'metadata': instance.metadata.toJson(),
  'error': instance.error,
};

GenerateRoundJudgmentResponse _$GenerateRoundJudgmentResponseFromJson(
  Map json,
) => GenerateRoundJudgmentResponse(
  success: json['success'] as bool,
  data: GenerateRoundJudgmentResponseData.fromJson(
    Map<String, dynamic>.from(json['data'] as Map),
  ),
);

Map<String, dynamic> _$GenerateRoundJudgmentResponseToJson(
  GenerateRoundJudgmentResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data.toJson(),
};

AIEndpointError _$AIEndpointErrorFromJson(Map json) => AIEndpointError(
  code: json['code'] as String,
  message: json['message'] as String,
  details: json['details'],
);

Map<String, dynamic> _$AIEndpointErrorToJson(AIEndpointError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };

AIEndpointErrorResponse _$AIEndpointErrorResponseFromJson(Map json) =>
    AIEndpointErrorResponse(
      success: json['success'] as bool,
      error: AIEndpointError.fromJson(
        Map<String, dynamic>.from(json['error'] as Map),
      ),
    );

Map<String, dynamic> _$AIEndpointErrorResponseToJson(
  AIEndpointErrorResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'error': instance.error.toJson(),
};
