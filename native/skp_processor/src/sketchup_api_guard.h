#pragma once

class SketchUpApiGuard {
 public:
  SketchUpApiGuard();
  ~SketchUpApiGuard();

  SketchUpApiGuard(const SketchUpApiGuard&) = delete;
  SketchUpApiGuard& operator=(const SketchUpApiGuard&) = delete;
};
