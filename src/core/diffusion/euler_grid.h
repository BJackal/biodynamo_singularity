// -----------------------------------------------------------------------------
//
// Copyright (C) 2021 CERN & University of Surrey for the benefit of the
// BioDynaMo collaboration. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// See the LICENSE file distributed with this work for details.
// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// -----------------------------------------------------------------------------

#ifndef CORE_DIFFUSION_EULER_GRID_H_
#define CORE_DIFFUSION_EULER_GRID_H_

#include <utility>

#include "core/diffusion/diffusion_grid.h"

namespace bdm {

class EulerGrid : public DiffusionGrid {
 public:
  EulerGrid() {}
  EulerGrid(int substance_id, std::string substance_name, double dc, double mu,
            int resolution = 11)
      : DiffusionGrid(substance_id, std::move(substance_name), dc, mu,
                      resolution) {}

  void DiffuseWithClosedEdge(double dt) override;

  void DiffuseWithOpenEdge(double dt) override;

 private:
  BDM_CLASS_DEF_OVERRIDE(EulerGrid, 1);
};

}  // namespace bdm

#endif  // CORE_DIFFUSION_EULER_GRID_H_
