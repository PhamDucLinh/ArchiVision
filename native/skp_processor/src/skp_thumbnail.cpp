#include "skp_processor.h"

#include <SketchUpAPI/sketchup.h>
#include <SketchUpAPI/model/image_rep.h>
#include <SketchUpAPI/model/model.h>

#include <chrono>
#include <filesystem>
#include <sstream>
#include <system_error>

namespace {

std::string ResultName(SUResult result) {
  std::ostringstream stream;
  stream << "SUResult(" << static_cast<int>(result) << ")";
  return stream.str();
}

bool IsSkpLikeFile(const std::filesystem::path& path) {
  const std::string ext = path.extension().string();
  return ext == ".skp" || ext == ".SKP" || ext == ".skb" || ext == ".SKB";
}

bool IsSkbFile(const std::filesystem::path& path) {
  const std::string ext = path.extension().string();
  return ext == ".skb" || ext == ".SKB";
}

std::filesystem::path MakeTemporarySkpPath(const std::filesystem::path& input) {
  const auto now = std::chrono::steady_clock::now().time_since_epoch().count();
  return std::filesystem::temp_directory_path() /
         ("skp_processor_" + input.stem().string() + "_" +
          std::to_string(now) + ".skp");
}

}  // namespace

ProcessorResult ExtractThumbnailPng(const std::string& input_path,
                                    const std::string& output_path) {
  const std::filesystem::path input(input_path);
  const std::filesystem::path output(output_path);

  if (!std::filesystem::exists(input)) {
    return {ProcessorStatus::kIoError,
            "Input file does not exist: " + input_path};
  }

  if (!IsSkpLikeFile(input)) {
    return {ProcessorStatus::kInvalidArguments,
            "Input must be a .skp or .skb file: " + input_path};
  }

  if (output.has_parent_path()) {
    std::filesystem::create_directories(output.parent_path());
  }

  std::filesystem::path model_path = input;
  std::filesystem::path temporary_skp;
  if (IsSkbFile(input)) {
    temporary_skp = MakeTemporarySkpPath(input);
    std::error_code copy_error;
    std::filesystem::copy_file(
        input, temporary_skp, std::filesystem::copy_options::overwrite_existing,
        copy_error);
    if (copy_error) {
      return {ProcessorStatus::kIoError,
              "Could not copy .skb to a temporary .skp file: " +
                  copy_error.message()};
    }
    model_path = temporary_skp;
  }

  SUModelRef model = SU_INVALID;
  SUResult result = SUModelCreateFromFile(&model, model_path.string().c_str());
  if (result != SU_ERROR_NONE) {
    if (!temporary_skp.empty()) {
      std::filesystem::remove(temporary_skp);
    }
    return {ProcessorStatus::kSketchUpError,
            "SUModelCreateFromFile failed: " + ResultName(result)};
  }

  SUImageRepRef image = SU_INVALID;
  result = SUImageRepCreate(&image);
  if (result != SU_ERROR_NONE) {
    SUModelRelease(&model);
    if (!temporary_skp.empty()) {
      std::filesystem::remove(temporary_skp);
    }
    return {ProcessorStatus::kSketchUpError,
            "SUImageRepCreate failed: " + ResultName(result)};
  }

  result = SUModelGetThumbnail(model, image);
  if (result != SU_ERROR_NONE) {
    SUImageRepRelease(&image);
    SUModelRelease(&model);
    if (!temporary_skp.empty()) {
      std::filesystem::remove(temporary_skp);
    }
    return {ProcessorStatus::kSketchUpError,
            "SUModelGetThumbnail failed. The SKP may not contain a thumbnail: " +
                ResultName(result)};
  }

  result = SUImageRepSaveToFile(image, output_path.c_str());
  SUImageRepRelease(&image);
  SUModelRelease(&model);
  if (!temporary_skp.empty()) {
    std::filesystem::remove(temporary_skp);
  }

  if (result != SU_ERROR_NONE) {
    return {ProcessorStatus::kSketchUpError,
            "SUImageRepSaveToFile failed: " + ResultName(result)};
  }

  return {ProcessorStatus::kOk, "Thumbnail written to: " + output_path};
}
