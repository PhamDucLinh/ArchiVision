#pragma once

#include <string>

enum class ProcessorStatus {
  kOk = 0,
  kInvalidArguments = 2,
  kSketchUpError = 3,
  kUnsupported = 4,
  kIoError = 5,
};

struct ProcessorResult {
  ProcessorStatus status;
  std::string message;
};

ProcessorResult ExtractThumbnailPng(const std::string& input_path,
                                    const std::string& output_path);

ProcessorResult ExportPerspectivePng(const std::string& input_path,
                                     const std::string& output_path);
