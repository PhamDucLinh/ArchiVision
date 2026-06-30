#include "skp_processor.h"

#include <string>

ProcessorResult ExportPerspectivePng(const std::string& input_path,
                                     const std::string& output_path) {
  (void)input_path;
  (void)output_path;

  return {
      ProcessorStatus::kUnsupported,
      "Perspective PNG export is not implemented with SketchUp C API alone. "
      "The C API can load models and inspect geometry headlessly, but it does "
      "not provide SketchUp's viewport renderer as a headless PNG export API. "
      "Implement this mode by triangulating faces from the C API and rendering "
      "them with your own OpenGL/EGL/OSMesa, Vulkan/Metal, or software renderer."};
}
