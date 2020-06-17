#include <iostream>
#include <fstream>
#include <sstream>
#include "ns3/core-module.h"
#include "ns3/mobility-module.h"
#include "ns3/ns2-mobility-helper.h"
#include "ns3/lte-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/applications-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/config-store.h"
#include <cfloat>
#include <cmath>
#include "ns3/ndnSIM-module.h"

#include "ns3/ndnSIM/model/directed-geocast-strategy.hpp"
using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("MobilityTrace");

static void
CourseChange (std::ostream *os, std::string foo, Ptr<const MobilityModel> mobility)
{
  Vector pos = mobility->GetPosition (); // Get position
  Vector vel = mobility->GetVelocity (); // Get velocity

  // Prints position and velocities
  *os << Simulator::Now () << " POS: x=" << pos.x << ", y=" << pos.y
      << ", z=" << pos.z << "; VEL:" << vel.x << ", y=" << vel.y
      << ", z=" << vel.z << std::endl;
}

int main(int argc, char *argv[])
{
  std::string traceFile;
  std::string logFile;

  int    nodeNum;
  double duration;
  Time simTime = Seconds (15);
  bool enableNsLogs = false;
  bool useIPv6 = false;
  double tMin = 0.02;
  double tMax = 0.2;

  // Enable logging from the ns2 helper
  LogComponentEnable ("Ns2MobilityHelper",LOG_LEVEL_DEBUG);

  // Parse command line attribute
  CommandLine cmd;
  cmd.AddValue ("traceFile", "Ns2 movement trace file", traceFile);
  cmd.AddValue ("nodeNum", "Number of nodes", nodeNum);
  cmd.AddValue ("duration", "Duration of Simulation", duration);
  cmd.AddValue ("logFile", "Log file", logFile);
  cmd.AddValue("tmin", "", tMin);
  cmd.AddValue("tmax", "", tMax);
  
  cmd.Parse (argc,argv);

  Config::SetDefault ("ns3::LteUeMac::SlGrantMcs", UintegerValue (16));
  Config::SetDefault ("ns3::LteUeMac::SlGrantSize", UintegerValue (5)); //The number of RBs allocated per UE for Sidelink
  Config::SetDefault ("ns3::LteUeMac::Ktrp", UintegerValue (1));
  Config::SetDefault ("ns3::LteUeMac::UseSetTrp", BooleanValue (true)); //use default Trp index of 0

  //Set the frequency
  uint32_t ulEarfcn = 18100;
  uint16_t ulBandwidth = 75;

  // Set error models
  Config::SetDefault ("ns3::LteSpectrumPhy::SlCtrlErrorModelEnabled", BooleanValue (true));
  Config::SetDefault ("ns3::LteSpectrumPhy::SlDataErrorModelEnabled", BooleanValue (true));
  Config::SetDefault ("ns3::LteSpectrumPhy::DropRbOnCollisionEnabled", BooleanValue (false));

  ConfigStore inputConfig;
  inputConfig.ConfigureDefaults ();
  // parse again so we can override input file default values via command line
  cmd.Parse (argc, argv);

  if (enableNsLogs)
    {
      LogLevel logLevel = (LogLevel)(LOG_PREFIX_FUNC | LOG_PREFIX_TIME | LOG_PREFIX_NODE | LOG_LEVEL_ALL);

      LogComponentEnable ("LteUeRrc", logLevel);
      LogComponentEnable ("LteUeMac", logLevel);
      LogComponentEnable ("LteSpectrumPhy", logLevel);
      LogComponentEnable ("LteUePhy", logLevel);
    }

  //Set the UEs power in dBm
  Config::SetDefault ("ns3::LteUePhy::TxPower", DoubleValue (23.0));
  Config::SetDefault ("ns3::LteUePowerControl::Pcmax", DoubleValue (23.0));
  Config::SetDefault ("ns3::LteUePowerControl::PscchTxPower", DoubleValue (23.0));
 // Config::SetDefault ("ns3::LteUePowerControl::PsschTxPower", DoubleValue (15.0));
  //Sidelink bearers activation time
  Time slBearersActivationTime = Seconds (2.0);

   //Create the helpers
  Ptr<LteHelper> lteHelper = CreateObject<LteHelper> ();

  //Create and set the EPC helper
  Ptr<PointToPointEpcHelper>  epcHelper = CreateObject<PointToPointEpcHelper> ();
  lteHelper->SetEpcHelper (epcHelper);

  ////Create Sidelink helper and set lteHelper
  Ptr<LteSidelinkHelper> proseHelper = CreateObject<LteSidelinkHelper> ();
  proseHelper->SetLteHelper (lteHelper);

  //Enable Sidelink
  lteHelper->SetAttribute ("UseSidelink", BooleanValue (true));

  //Set pathloss model
  lteHelper->SetAttribute ("PathlossModel", StringValue ("ns3::Cost231PropagationLossModel"));
  lteHelper->SetPathlossModelAttribute ("BSAntennaHeight", DoubleValue(1.5));
  lteHelper->SetPathlossModelAttribute ("SSAntennaHeight", DoubleValue(1.5));
  // channel model initialization
  lteHelper->Initialize ();

  double ulFreq = LteSpectrumValueHelper::GetCarrierFrequency (ulEarfcn);
  NS_LOG_LOGIC ("UL freq: " << ulFreq);
  Ptr<Object> uplinkPathlossModel = lteHelper->GetUplinkPathlossModel ();
  Ptr<PropagationLossModel> lossModel = uplinkPathlossModel->GetObject<PropagationLossModel> ();
  NS_ABORT_MSG_IF (lossModel == NULL, "No PathLossModel");
  bool ulFreqOk = uplinkPathlossModel->SetAttributeFailSafe ("Frequency", DoubleValue (ulFreq));
  if (!ulFreqOk)
    {
      NS_LOG_WARN ("UL propagation model does not have a Frequency attribute");
    }

  NS_LOG_INFO ("Deploying UE's...");

  Ns2MobilityHelper ns2 = Ns2MobilityHelper (traceFile);

  // open log file for output
  std::ofstream os;
  os.open (logFile.c_str ());

  // Create all nodes.
  NodeContainer ueNodes;
  ueNodes.Create (nodeNum);

  ns2.Install (); // configure movements for each node, while reading trace file

  //Install LTE UE devices to the nodes
  NetDeviceContainer ueDevs = lteHelper->InstallUeDevice (ueNodes);

  //Sidelink pre-configuration for the UEs
  Ptr<LteSlUeRrc> ueSidelinkConfiguration = CreateObject<LteSlUeRrc> ();
  ueSidelinkConfiguration->SetSlEnabled (true);

  LteRrcSap::SlPreconfiguration preconfiguration;

  preconfiguration.preconfigGeneral.carrierFreq = ulEarfcn;
  preconfiguration.preconfigGeneral.slBandwidth = ulBandwidth;
  preconfiguration.preconfigComm.nbPools = 1;

  LteSlPreconfigPoolFactory pfactory;

  //Control
  pfactory.SetControlPeriod ("sf40");
  pfactory.SetControlBitmap (0x00000000FF); //8 subframes for PSCCH
  pfactory.SetControlOffset (0);
  pfactory.SetControlPrbNum (22);
  pfactory.SetControlPrbStart (0);
  pfactory.SetControlPrbEnd (49);

  //Data
  pfactory.SetDataBitmap (0xFFFFFFFFFF);
  pfactory.SetDataOffset (8); //After 8 subframes of PSCCH
  pfactory.SetDataPrbNum (25);
  pfactory.SetDataPrbStart (0);
  pfactory.SetDataPrbEnd (49);

  preconfiguration.preconfigComm.pools[0] = pfactory.CreatePool ();

  ueSidelinkConfiguration->SetSlPreconfiguration (preconfiguration);
  lteHelper->InstallSidelinkConfiguration (ueDevs, ueSidelinkConfiguration);

  InternetStackHelper internet;
  internet.Install (ueNodes);
  uint32_t groupL2Address = 255;
  Ipv4Address groupAddress4 ("225.63.63.1");     //use multicast address as destination

  Ipv4InterfaceContainer ueIpIface;
  ueIpIface = epcHelper->AssignUeIpv4Address (NetDeviceContainer (ueDevs));

  // set the default gateway for the UE
  Ipv4StaticRoutingHelper ipv4RoutingHelper;
  for (uint32_t u = 0; u < ueNodes.GetN (); ++u) {
    Ptr<Node> ueNode = ueNodes.Get(u);
    // Set the default gateway for the UE
    Ptr<Ipv4StaticRouting> ueStaticRouting = ipv4RoutingHelper.GetStaticRouting(ueNode->GetObject<Ipv4>());
    ueStaticRouting->SetDefaultRoute (epcHelper->GetUeDefaultGatewayAddress(), 1);
  }

  Address remoteAddress = InetSocketAddress (groupAddress4, 8000);
  Address localAddress = InetSocketAddress (Ipv4Address::GetAny (), 8000);
  Ptr<LteSlTft> tft = Create<LteSlTft> (LteSlTft::BIDIRECTIONAL, groupAddress4, groupL2Address);

  ///*** Configure applications ***///

  //Set Sidelink bearers
  proseHelper->ActivateSidelinkBearer (slBearersActivationTime, ueDevs, tft);

  ///*** End of application configuration ***///
  ::ns3::ndn::StackHelper helper;
  helper.SetDefaultRoutes(true);
  helper.InstallAll();

  //* Choosing forwarding strategy *//
  ns3::ndn::StrategyChoiceHelper::InstallAll("/", "/localhost/nfd/strategy/directed-geocast/%FD%01/" +
                                             std::to_string(tMin) + "/" + std::to_string(tMax));

 //Will add cost231Propagationloss model loss here f
  std::cout<< ueNodes.Get(0) <<std::endl;
  ::ns3::ndn::AppHelper consumerHelper("ns3::ndn::ConsumerBatches");
  consumerHelper.SetPrefix("/v2safety/8thStreet/0,0,0/,0,0/100");
  consumerHelper.SetAttribute("Batches", StringValue("2s 1 3s 1 4s 1 5s 1 6s 1")); // 10 interests a second
  consumerHelper.SetAttribute("RetxTimer", StringValue("1000s"));
  consumerHelper.SetAttribute("LifeTime", StringValue("15s"));
  consumerHelper.Install(ueNodes.Get(0));

  // Producer
  ::ns3::ndn::AppHelper producerHelper("ns3::ndn::Producer");
  // Producer will reply to all requests starting with /prefix
  producerHelper.SetPrefix("/v2safety/8thStreet");
  producerHelper.SetAttribute("PayloadSize", StringValue("50"));
  producerHelper.Install(ueNodes.Get(nodeNum-1));


  Config::Connect ("/NodeList/*/$ns3::MobilityModel/CourseChange",
                   MakeBoundCallback (&CourseChange, &os));
  
  Simulator::Stop(Seconds(duration));

  std::ofstream of("results/sumo-trace.csv");
  of << "Node,Time,Name,Action,X,Y" << std::endl;
  nfd::fw::DirectedGeocastStrategy::onAction.connect([&of] (const ::ndn::Name& name, int type, double x, double y) {
      auto context = Simulator::GetContext();
      auto time = Simulator::Now().ToDouble(Time::S);
      std::string action;
      if (type == 0)
        action = "Broadcast";
      else if (type == 1)
        action = "Received";
      else if (type == 2)
        action = "Duplicate";
      else
        action = "Suppressed";
      of << context << "," << time << "," << name.get(-1).toSequenceNumber() << "," << action << ","<< x << "," << y <<std::endl;
    });
  
  Simulator::Run ();
  Simulator::Destroy ();

  os.close (); // close log file
  return 0;

}
