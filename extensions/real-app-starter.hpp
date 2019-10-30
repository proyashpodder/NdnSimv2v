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

#ifndef NDNSIM_EXAMPLES_NDN_CXX_SIMPLE_REAL_APP_STARTER_HPP
#define NDNSIM_EXAMPLES_NDN_CXX_SIMPLE_REAL_APP_STARTER_HPP

#include "real-app.hpp"

#include "ns3/ndnSIM/helper/ndn-stack-helper.hpp"
#include "ns3/application.h"
#include "ns3/string.h"

namespace ns3 {

// Class inheriting from ns3::Application
class RealAppStarter : public Application
{
public:
  static TypeId
  GetTypeId()
  {
    static TypeId tid = TypeId("RealAppStarter")
      .SetParent<Application>()
      .AddConstructor<RealAppStarter>()
      .AddAttribute("Prefix", "Name of the Interest", StringValue("/default"),
                    ndn::MakeNameAccessor(&RealAppStarter::setPrefix, &RealAppStarter::getPrefix),
                    ndn::MakeNameChecker())
      ;

    return tid;
  }

protected:
  // inherited from Application base class.
  virtual void
  StartApplication()
  {
    // Create an instance of the app, and passing the dummy version of KeyChain (no real signing)
    m_instance.reset(new app::RealApp(ndn::StackHelper::getKeyChain()));
    m_instance->setPrefix(m_prefix);
    m_instance->run(); // can be omitted
  }

  virtual void
  StopApplication()
  {
    // Stop and destroy the instance of the app
    m_instance.reset();
  }

  void
  setPrefix(const ndn::Name& prefix)
  {
    m_prefix = prefix;
    if (m_instance) {
      m_instance->setPrefix(m_prefix);
    }
  }

  ndn::Name
  getPrefix() const
  {
    return m_prefix;
  }

private:
  std::unique_ptr<app::RealApp> m_instance;
  ndn::Name m_prefix = "/default";
};

} // namespace ns3

#endif // NDNSIM_EXAMPLES_NDN_CXX_SIMPLE_REAL_APP_STARTER_HPP
