ExUnit.start()
Mox.defmock(MockCollector, for: Station.Collector)
Mox.defmock(MockRegister, for: Station.Registry)
Mox.defmock(MockStation, for: Station.StationBehaviour)
#ExUnit.configure exclude: [:slow]