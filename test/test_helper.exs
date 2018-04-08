ExUnit.start()
Mox.defmock(MockCollector, for: Station.CollectorBehaviour)
Mox.defmock(MockRegister, for: Station.RegistryBehaviour)
Mox.defmock(MockStation, for: Station.StationBehaviour)
Mox.defmock(MockItinerary, for: Util.ItineraryBehaviour)
Mox.defmock(MockUQC, for: Station.UQCBehaviour)
#ExUnit.configure exclude: [:slow]
