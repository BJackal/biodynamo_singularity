// -----------------------------------------------------------------------------
//
// Copyright (C) The BioDynaMo Project.
// All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// See the LICENSE file distributed with this work for details.
// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// -----------------------------------------------------------------------------

#ifndef T_CELL_H_
#define T_CELL_H_

#include "TH2I.h"

#include "core/sim_object/cell.h"

namespace bdm {

class Monocyte;

/// Define T-Cell type
class TCell : public Cell {
  BDM_SIM_OBJECT_HEADER(TCell, Cell, 1);

 public:
  TCell() {}
  explicit TCell(const Double3& position, double diameter, size_t color, int t)
      : Base(position), color_(color) {
    activation_histo_ = TH2I("", "", 30, 0, 49, 30, 0, t - 1);
    this->SetDiameter(diameter);
  }

  /// Default event constructor
  TCell(const Event& event, SimObject* other, uint64_t new_oid = 0)
      : Base(event, other, new_oid) {}

  /// Default event handler
  void EventHandler(const Event& event, SimObject* other1,
                    SimObject* other2 = nullptr) override {
    Base::EventHandler(event, other1, other2);
  }

  void IncreaseActivationIntensity(double val) {
    if (val > 0) {
      activation_intensity_ += val;
    }
  }

  void Activate() {
    auto* r = Simulation::GetActive()->GetRandom();
    auto val = r->Gaus(10 * mean_, 3 * sigma_);
    IncreaseActivationIntensity(val);
    is_activated_ = true;
    auto t = Simulation::GetActive()->GetScheduler()->GetSimulatedSteps();
    activation_histo_.Fill(activation_intensity_, t);
  }

  void Deactivate() { is_activated_ = false; }

  void ConnectTo(SoPointer<Monocyte> so) {
    connected_cell_ = so;
    color_ = 2;
  }

  // Set the initial activation energy. Initially the T-Cell is not activated
  // and has therefore a low value, following a normal distribution
  void SetInitialActivationIntensity(double mean, double sigma) {
    mean_ = mean;
    sigma_ = sigma;
    auto* r = Simulation::GetActive()->GetRandom();
    auto val = r->Gaus(mean, sigma);
    IncreaseActivationIntensity(val);
  }

  TH2I* GetActivationHistogram() { return &activation_histo_; }

  size_t GetActivationIntensity() { return activation_intensity_; }

  bool IsActivated() { return is_activated_; }

  bool IsConnected() { return connected_cell_ != nullptr; }

  SoPointer<Monocyte> GetConnectedCell() const { return connected_cell_; }

 private:
  // Is this T-Cell connected to a Monocyte
  bool is_connected_ = false;
  // The cell this T-Cell is connected to
  SoPointer<Monocyte> connected_cell_;
  // Is this T-Cell activated?
  bool is_activated_ = false;
  // The activation intensity (represents the number of PD-1 receptors)
  size_t activation_intensity_ = 0;
  // The color that will be used for visualization purposes
  size_t color_ = 1;
  // Mean for the normal distribution of the initial activation intensity
  double mean_ = 3;
  // Sigma for the normal distribution of the initial activation intensity
  double sigma_ = 1;
  TH2I activation_histo_;
};

}  // namespace bdm

#endif  // T_CELL_H_
