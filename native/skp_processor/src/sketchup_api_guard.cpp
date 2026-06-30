#include "sketchup_api_guard.h"

#include <SketchUpAPI/sketchup.h>

SketchUpApiGuard::SketchUpApiGuard() {
  SUInitialize();
}

SketchUpApiGuard::~SketchUpApiGuard() {
  SUTerminate();
}
