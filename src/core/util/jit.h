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

#ifndef CORE_UTIL_JIT_H_
#define CORE_UTIL_JIT_H_

#include <functional>
#include <string>
#include <vector>

#include <TClass.h>
#include <TDataMember.h>

namespace bdm {

class Agent;

/// Iterates over all entries in `TClassTable` and returns a vector of candidate
/// TClass* that match the given class name.
/// \param class_name does not have to be fully qualified
///        (e.g. `Cell` instead of `bdm::Cell`). \n
///        However, `Cell` will also match e.g "bdm::foo::Cell"
/// \return multiple values if class_name is ambigous and multiple classes
///         were found in different namespaces
std::vector<TClass*> FindClassSlow(const std::string& class_name);

/// Iterates over all data members of `tclass` and its base classes and returns
/// TClass* that match the given class name.
/// \param tclass TClass for which the data members should be determined
/// \param data_member name of the data_member
///        (e.g. `position_` or  `bdm::Cell::position_`). \n
/// \return multiple values if data_member name is ambigous and multiple
///         instances were found in `tclass` and its base classes
std::vector<TDataMember*> FindDataMemberSlow(TClass* tclass,
                                             const std::string& data_member);

// -----------------------------------------------------------------------------
class JitForEachDataMemberFunctor {
 public:
  JitForEachDataMemberFunctor(
      TClass* tclass, const std::vector<std::string>& dm_names,
      const std::string& functor_name,
      const std::function<std::string(const std::string&,
                                      const std::vector<TDataMember*>&)>&
          code_generation);

  void Compile();

  void* New(const std::string& parameter = "");

  template <typename TFunctor>
  TFunctor* New(const std::string& parameter = "") {
    return static_cast<TFunctor*>(New(parameter));
  }

 private:
  /// The counter value is appended to the functor_name to obtain unique names
  static std::atomic<int> counter_;
  std::string functor_name_;
  std::vector<TDataMember*> data_members_;
  std::function<std::string(const std::string&,
                            const std::vector<TDataMember*>&)>
      code_generator_;
};

// -----------------------------------------------------------------------------
class JitHeaders {
 public:
  /// Header must be an absolute path or relative to one of the include
  /// directories known to cling.
  static void Register(const std::string& header);
  /// Include headers from `JitHeaders::headers_` into cling and
  /// removes them from the vector.
  static void IncludeIntoCling();

 private:
  static std::vector<std::string> headers_;
};

}  // namespace bdm

#endif  // CORE_UTIL_JIT_H_
