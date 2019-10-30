/* -*- Mode:C++; c-file-style:"gnu"; indent-tabs-mode:nil; -*- */
/**
 * Copyright (c) 2019  Regents of the University of California.
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

#include "real-app.hpp"

#include "ns3/node-list.h"
#include "ns3/mobility-model.h"
#include "ns3/node.h"

namespace app {

void
RealApp::run(size_t count)
{
  for (size_t i = 0; i < count; ++i) {
    m_scheduler.schedule(ndn::time::seconds(i) +
                         ndn::time::duration_cast<ndn::time::nanoseconds>(ndn::time::duration<double>(m_randVar->GetValue())),
                         [this, i] {
                           auto node = ns3::NodeList::GetNode(ns3::Simulator::GetContext());
                           auto foobar = node->GetObject<ns3::MobilityModel>()->GetPosition();

                           std::ostringstream pos;
                           pos << foobar.x << "," << foobar.y << "," << foobar.z;

                           ndn::Name name;
                           for (const auto& comp : m_prefix) {
                             if (comp == ndn::Name::Component("@COORD@")) {
                               name.append(pos.str());
                             }
                             else {
                               name.append(comp);
                             }
                           }
                           name.appendSequenceNumber(i);

                           std::cerr << ns3::Simulator::Now().ToDouble(ns3::Time::S) << std::endl;
                           std::cerr << name << std::endl;
                           m_faceConsumer.expressInterest(ndn::Interest(name),
                                                          std::bind([] { std::cerr << "Got data" << std::endl; }),
                                                          std::bind([] { std::cerr << "Ignore NACK" << std::endl; }),
                                                          std::bind([] { std::cerr << "Ignore timeout" << std::endl; }));
                         });
  }

  m_faceConsumer.processEvents(); // ok (will not block and do nothing)
}

} // namespace app
