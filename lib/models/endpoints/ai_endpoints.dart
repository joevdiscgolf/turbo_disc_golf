import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

part 'ai_endpoints.g.dart';

/* ============================
   Common Nested Types
   ============================ */

@JsonSerializable(anyMap: true, explicitToJson: true)
class TokensUsed {
  final int prompt;
  final int completion;
  final int total;

  TokensUsed({
    required this.prompt,
    required this.completion,
    required this.total,
  });

  factory TokensUsed.fromJson(Map<String, dynamic> json) =>
      _$TokensUsedFromJson(json);

  Map<String, dynamic> toJson() => _$TokensUsedToJson(this);
}

/* ============================
   Parse Round Data Endpoint
   ============================ */

@JsonSerializable(anyMap: true, explicitToJson: true)
class ParseRoundDataRequest {
  final String voiceTranscript;
  final List<DGDisc> userBag;
  final String? courseName;

  ParseRoundDataRequest({
    required this.voiceTranscript,
    required this.userBag,
    this.courseName,
  });

  factory ParseRoundDataRequest.fromJson(Map<String, dynamic> json) =>
      _$ParseRoundDataRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ParseRoundDataRequestToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class ParseRoundDataResponseMetadata {
  final String parsedAt;
  final String? finishReason;

  ParseRoundDataResponseMetadata({
    required this.parsedAt,
    this.finishReason,
  });

  factory ParseRoundDataResponseMetadata.fromJson(Map<String, dynamic> json) =>
      _$ParseRoundDataResponseMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ParseRoundDataResponseMetadataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class ParseRoundDataResponseData {
  /// Raw YAML response from LLM (for backward compatibility).
  /// Use this if `parsedData` is null.
  final String rawResponse;

  final String model;
  final TokensUsed? tokensUsed;
  final ParseRoundDataResponseMetadata metadata;
  final String? error;

  /// Parsed round data as JSON map (ready to convert to PotentialDGRound).
  /// When present, use this directly instead of parsing rawResponse.
  /// This field is populated when backend handles YAML parsing.
  @JsonKey(name: 'parsedRound')
  final Map<String, dynamic>? parsedData;

  ParseRoundDataResponseData({
    required this.rawResponse,
    required this.model,
    this.tokensUsed,
    required this.metadata,
    this.error,
    this.parsedData,
  });

  factory ParseRoundDataResponseData.fromJson(Map<String, dynamic> json) =>
      _$ParseRoundDataResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$ParseRoundDataResponseDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class ParseRoundDataResponse {
  final bool success;
  final ParseRoundDataResponseData data;

  ParseRoundDataResponse({
    required this.success,
    required this.data,
  });

  factory ParseRoundDataResponse.fromJson(Map<String, dynamic> json) =>
      _$ParseRoundDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ParseRoundDataResponseToJson(this);
}

/* ============================
   Generate Round Story Endpoint
   ============================ */

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundStoryRequest {
  final DGRound round;
  final RoundAnalysis analysis;

  GenerateRoundStoryRequest({
    required this.round,
    required this.analysis,
  });

  factory GenerateRoundStoryRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoundStoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoundStoryRequestToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundStoryResponseMetadata {
  final String generatedAt;
  final String? finishReason;

  GenerateRoundStoryResponseMetadata({
    required this.generatedAt,
    this.finishReason,
  });

  factory GenerateRoundStoryResponseMetadata.fromJson(
      Map<String, dynamic> json) =>
      _$GenerateRoundStoryResponseMetadataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GenerateRoundStoryResponseMetadataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundStoryResponseData {
  /// Raw YAML response from LLM (for backward compatibility).
  /// Use this if `aiContent` is null.
  final String rawResponse;

  final String model;
  final TokensUsed? tokensUsed;
  final GenerateRoundStoryResponseMetadata metadata;
  final String? error;

  /// Complete AIContent object with parsed story data.
  /// When present, use this directly instead of parsing rawResponse.
  /// This field is populated when backend handles YAML parsing.
  final AIContent? aiContent;

  GenerateRoundStoryResponseData({
    required this.rawResponse,
    required this.model,
    this.tokensUsed,
    required this.metadata,
    this.error,
    this.aiContent,
  });

  factory GenerateRoundStoryResponseData.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoundStoryResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoundStoryResponseDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundStoryResponse {
  final bool success;
  final GenerateRoundStoryResponseData data;

  GenerateRoundStoryResponse({
    required this.success,
    required this.data,
  });

  factory GenerateRoundStoryResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoundStoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoundStoryResponseToJson(this);
}

/* ============================
   Generate Round Judgment Endpoint
   ============================ */

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundJudgmentRequest {
  final DGRound round;
  final RoundAnalysis analysis;
  final bool? shouldGlaze;

  GenerateRoundJudgmentRequest({
    required this.round,
    required this.analysis,
    this.shouldGlaze,
  });

  factory GenerateRoundJudgmentRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoundJudgmentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoundJudgmentRequestToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundJudgmentResponseMetadata {
  final String generatedAt;
  final String? finishReason;

  GenerateRoundJudgmentResponseMetadata({
    required this.generatedAt,
    this.finishReason,
  });

  factory GenerateRoundJudgmentResponseMetadata.fromJson(
      Map<String, dynamic> json) =>
      _$GenerateRoundJudgmentResponseMetadataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GenerateRoundJudgmentResponseMetadataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundJudgmentResponseData {
  /// Raw YAML response from LLM (for backward compatibility).
  /// Use this if `aiContent` is null.
  final String rawResponse;

  final String model;
  final TokensUsed? tokensUsed;
  final GenerateRoundJudgmentResponseMetadata metadata;
  final String? error;

  /// Complete AIContent object with parsed judgment data.
  /// When present, use this directly instead of parsing rawResponse.
  /// This field is populated when backend handles YAML parsing.
  final AIContent? aiContent;

  GenerateRoundJudgmentResponseData({
    required this.rawResponse,
    required this.model,
    this.tokensUsed,
    required this.metadata,
    this.error,
    this.aiContent,
  });

  factory GenerateRoundJudgmentResponseData.fromJson(
      Map<String, dynamic> json) =>
      _$GenerateRoundJudgmentResponseDataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GenerateRoundJudgmentResponseDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class GenerateRoundJudgmentResponse {
  final bool success;
  final GenerateRoundJudgmentResponseData data;

  GenerateRoundJudgmentResponse({
    required this.success,
    required this.data,
  });

  factory GenerateRoundJudgmentResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateRoundJudgmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateRoundJudgmentResponseToJson(this);
}

/* ============================
   Common Error Response
   ============================ */

@JsonSerializable(anyMap: true, explicitToJson: true)
class AIEndpointError {
  final String code;
  final String message;
  final dynamic details;

  AIEndpointError({
    required this.code,
    required this.message,
    this.details,
  });

  factory AIEndpointError.fromJson(Map<String, dynamic> json) =>
      _$AIEndpointErrorFromJson(json);

  Map<String, dynamic> toJson() => _$AIEndpointErrorToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class AIEndpointErrorResponse {
  final bool success;
  final AIEndpointError error;

  AIEndpointErrorResponse({
    required this.success,
    required this.error,
  });

  factory AIEndpointErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$AIEndpointErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AIEndpointErrorResponseToJson(this);
}
