#include "ns3/lte-module.h"
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-module.h"
#include "ns3/applications-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/config-store.h"
#include <cfloat>
#include <sstream>
#include <cmath>
#include "ns3/ndnSIM-module.h"

#include "ns3/ndnSIM/model/directed-geocast-strategy.hpp"
using namespace ns3;


NS_LOG_COMPONENT_DEFINE ("LteSlOutOfCovrg");

int main (int argc, char *argv[])
{
  Ptr<UniformRandomVariable> uv = CreateObject<UniformRandomVariable> ();
  std::cout << uv->GetValue () << std::endl;
  Time simTime = Seconds (6);
  bool enableNsLogs = false;
  bool useIPv6 = false;
  //double distance=atoi(argv[1]);
  int nodeNumber = 20;
  double tMin = 0.02;
  double tMax = 0.1;

  CommandLine cmd;
  cmd.AddValue("simTime", "Total duration of the simulation", simTime);
  cmd.AddValue("enableNsLogs", "Enable ns-3 logging (debug builds)", enableNsLogs);
  cmd.AddValue("nodeNumber", "The total nodes will be", nodeNumber);

  cmd.AddValue("tmin", "", tMin);
  cmd.AddValue("tmax", "", tMax);

  cmd.Parse (argc, argv);

  //Configure the UE for UE_SELECTED scenario
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
  // channel model initialization
  lteHelper->Initialize ();

  // Since we are not installing eNB, we need to set the frequency attribute of pathloss model here
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

  //Create nodes (UEs)
  NodeContainer ueNodes;
  ueNodes.Create (nodeNumber);
  //NS_LOG_INFO ("UE 1 node id = [" << ueNodes.Get (0)->GetId () << "]");
  //NS_LOG_INFO ("UE 2 node id = [" << ueNodes.Get (1)->GetId () << "]");
  //NS_LOG_INFO ("UE 3 node id = [" << ueNodes.Get (2)->GetId () << "]");

  MobilityHelper mobility;
  Ptr<ListPositionAllocator> initialAlloc = CreateObject<ListPositionAllocator> ();
  //this node will generate the interest
  initialAlloc->Add(Vector(100.0,20.0,0.0));
  //these nodes will receive the interest in 1st hop
  /*initialAlloc->Add(Vector(200.0,0.0,0.0));
  //these nodes will receive the interest in first hop and drop it as they are in opposite direction from the destination
  initialAlloc->Add(Vector(500.0,0.0,0.0));
  //this is the producer node
  initialAlloc->Add(Vector(700.0,0.0,0.0));

  mobility.SetPositionAllocator(initialAlloc);
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.Install(ueNodes.Get (0));
  mobility.Install(ueNodes.Get (1));
  mobility.Install(ueNodes.Get (2));
  mobility.Install(ueNodes.Get (3));
  double inc = 600.0/nodeNumber;
  double xposition = inc;
  for( int i = 1; i< nodeNumber; i++ ){
    //initialAlloc->Add(Vector(xposition,0.0,0.0));
    //xposition = xposition + inc;
    if(i%2 == 0){
      initialAlloc->Add(Vector(xposition,50.0,0.0));
    }
    else{
     initialAlloc->Add(Vector(xposition,-50.0,0.0));
    }
    xposition = xposition + inc;
  }*/

  int full = 1;
  int check[400];
  for(int i=0;i<400;i++){
    check[i] = 0;
  }

  while(full < nodeNumber-1){
    Ptr<UniformRandomVariable> uvr = CreateObject<UniformRandomVariable> ();
    double uv = uvr->GetValue();
    double xCoordinate,yCoordinate;
    std::cout << uv<< std::endl;
    uv =ceil(uv*100);
    uv = uv/100*320;
    int no = (int) uv;
    if(check[no] == 0){
      full++;
      std::cout<< no << std::endl;
      xCoordinate = (no%80)*10;
      yCoordinate = (no/80)*4;
      initialAlloc->Add(Vector(xCoordinate,yCoordinate,0.0));
    }

  }
  initialAlloc->Add(Vector(750.0,0.0,0.0));

  mobility.SetPositionAllocator(initialAlloc);
  mobility.SetMobilityModel ("ns3::ConstantVelocityMobilityModel");
  //ueNodes.Get (0)->GetObject<ConstantVelocityMobilityModel> ()->SetVelocity (Vector (10, 0, 0));
  for(int i= 0;i<nodeNumber-1; i++){
    mobility.Install(ueNodes.Get (i));
    if(i%2 == 0 ){
      ueNodes.Get (i)->GetObject<ConstantVelocityMobilityModel> ()->SetVelocity (Vector (10, 0, 0));
    }
    else if(i%3 == 0){
      ueNodes.Get (i)->GetObject<ConstantVelocityMobilityModel> ()->SetVelocity (Vector (5, 0, 0));
    }
  }
  mobility.Install(ueNodes.Get (nodeNumber-1));
  


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

 //Will add cost231Propagationloss model loss here for and packet loss

  // // Consumer
  // ::ns3::ndn::AppHelper consumerHelper("ns3::ndn::ConsumerCbr");
  // // Consumer will request /prefix/0, /prefix/1, ...
  // //consumerHelper.SetPrefix("/v2safety/8thStreet/parking");
  // consumerHelper.SetPrefix("/v2safety/8thStreet/0,0,0/700,0,0/100");
  // consumerHelper.SetAttribute("Frequency", StringValue("1")); // 10 interests a second
  // consumerHelper.Install(ueNodes.Get(0)).Start(Seconds(2));                        // first node

  ::ns3::ndn::AppHelper consumerHelper("ns3::ndn::ConsumerBatches");
  consumerHelper.SetPrefix("/v2safety/8thStreet/100,20,0/750,0,0/100");
  consumerHelper.SetAttribute("Batches", StringValue("2s 1 3s 1 4s 1 5s 1 6s 1")); // 10 interests a second
  consumerHelper.SetAttribute("RetxTimer", StringValue("1000s"));
  consumerHelper.Install(ueNodes.Get(0));

  // Producer
  ::ns3::ndn::AppHelper producerHelper("ns3::ndn::Producer");
  // Producer will reply to all requests starting with /prefix
  producerHelper.SetPrefix("/v2safety/8thStreet");
  producerHelper.SetAttribute("PayloadSize", StringValue("1024"));
  producerHelper.Install(ueNodes.Get(nodeNumber-1));

  //ns3::ndn::L3RateTracer::InstallAll("trace.txt", Seconds(1));
  // Simulator::Stop(Seconds(2.9)); // expect 1 distinct request
  Simulator::Stop(Seconds(12.99)); // expect 10 distinct requests
  int no = (int) nodeNumber;
  std::ofstream of("results/" + std::to_string(no) +
                   "-tmin=" + std::to_string(tMin) +
                   "-tmax=" + std::to_string(tMax) +
                   "-2hops.csv");
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
  return 0;

}
