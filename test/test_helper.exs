ExUnit.start()
Mox.defmock(MockCollector, for: Station.CollectorBehaviour)
Mox.defmock(MockRegister, for: Station.RegistryBehaviour)
Mox.defmock(MockStation, for: Station.StationBehaviour)
#ExUnit.configure exclude: [:slow]
