/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/**
 * Copyright (c) 2011-2015  Regents of the University of California.
 *
 * This file is part of ndnSIM. See AUTHORS for complete list of ndnSIM authors and
 * contributors.
 *
 * ndnSIM is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * ndnSIM is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * ndnSIM, e.g., in COPYING.md file.  If not, see <http://www.gnu.org/licenses/>.
 **/

#ifndef NDNSIM_EXAMPLES_NDN_CXX_SIMPLE_REAL_APP_HPP
#define NDNSIM_EXAMPLES_NDN_CXX_SIMPLE_REAL_APP_HPP

#include <ndn-cxx/face.hpp>
#include <ndn-cxx/interest.hpp>
#include <ndn-cxx/security/key-chain.hpp>
#include <ndn-cxx/util/scheduler.hpp>

#include <iostream>
#include "ns3/random-variable-stream.h"

namespace app {

class RealApp
{
public:
  RealApp(ndn::KeyChain& keyChain)
    : m_keyChain(keyChain)
    , m_faceProducer(m_faceConsumer.getIoService())
    , m_scheduler(m_faceConsumer.getIoService())
  {
    ndn::Interest::setDefaultCanBePrefix(true);
    m_randVar = ns3::CreateObject<ns3::UniformRandomVariable>();
    // m_randVar->SetAttribute ("Min", ns3::DoubleValue(0));
    // m_randVar->SetAttribute ("Max", ns3::DoubleValue(0.5));
  }

  void
  run(size_t count = 10);

  void
  setPrefix(const ndn::Name& prefix)
  {
    m_prefix = prefix;
  }

  ndn::Name
  getPrefix() const
  {
    return m_prefix;
  }

private:
  void
  respondToAnyInterest(const ndn::Interest& interest)
  {
    // auto data = std::make_shared<ndn::Data>(interest.getName());
    // m_keyChain.sign(*data);
    // m_faceProducer.put(*data);
  }

private:
  ndn::KeyChain& m_keyChain;
  ndn::Face m_faceConsumer;
  ndn::Face m_faceProducer;
  ndn::Scheduler m_scheduler;
  ndn::Name m_prefix;

  ns3::Ptr<ns3::UniformRandomVariable> m_randVar;
};

} // namespace app

#endif // NDNSIM_EXAMPLES_NDN_CXX_SIMPLE_REAL_APP_HPP
