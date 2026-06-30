#include "sketchup_api_guard.h"
#include "skp_processor.h"

#include <iostream>
#include <string>

namespace {

void PrintUsage() {
  std::cerr
      << "Usage:\n"
      << "  skp_processor <input.skp|input.skb> <output.png>\n"
      << "  skp_processor --mode thumbnail <input.skp|input.skb> <output.png>\n"
      << "  skp_processor --mode render <input.skp|input.skb> <output.png>\n\n"
      << "Modes:\n"
      << "  thumbnail  Extract the embedded SKP preview image. This is the default.\n"
      << "  render     Reserved for a custom headless renderer implementation.\n";
}

int StatusToExitCode(ProcessorStatus status) {
  return static_cast<int>(status);
}

}  // namespace

int main(int argc, char** argv) {
  std::string mode = "thumbnail";
  std::string input_path;
  std::string output_path;

  if (argc == 3) {
    input_path = argv[1];
    output_path = argv[2];
  } else if (argc == 5 && std::string(argv[1]) == "--mode") {
    mode = argv[2];
    input_path = argv[3];
    output_path = argv[4];
  } else {
    PrintUsage();
    return StatusToExitCode(ProcessorStatus::kInvalidArguments);
  }

  SketchUpApiGuard sketchup_api;

  ProcessorResult result;
  if (mode == "thumbnail") {
    result = ExtractThumbnailPng(input_path, output_path);
  } else if (mode == "render") {
    result = ExportPerspectivePng(input_path, output_path);
  } else {
    PrintUsage();
    return StatusToExitCode(ProcessorStatus::kInvalidArguments);
  }

  if (result.status == ProcessorStatus::kOk) {
    std::cout << result.message << '\n';
  } else {
    std::cerr << result.message << '\n';
  }

  return StatusToExitCode(result.status);
}
