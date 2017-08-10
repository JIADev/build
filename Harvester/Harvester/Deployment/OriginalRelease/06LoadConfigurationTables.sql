DELETE FROM [dbo].[CustomerRepository]

DELETE FROM [dbo].[Customer]
DBCC CHECKIDENT (Customer, RESEED, 0)

DELETE FROM [dbo].[Repository]
DBCC CHECKIDENT (Repository, RESEED, 0)

-- Customers
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2085', N'Arbonne', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2083', N'Aviance', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2087', N'Beachbody', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST043', N'Blessings', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2081', N'Creative Memories', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2086', N'ENJO', N'source.jenkon.com/hg/hgwebdir.cgi/feature/customers/CUST2086', 1)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST068', N'Essen', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2082', N'Just Jewelry', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST069', N'RBC Life Sciences', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST000', N'Start Account', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST065', N'The Chef''s Toolbox', N'source.jenkon.com/hg/hgwebdir.cgi/feature/customers/CUST065', 1)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST2088', N'TriVita', NULL, NULL)
INSERT [dbo].[Customer] ([Code], [Description], [URL], [HarvestFlag]) VALUES (N'CUST077', N'Viridian', NULL, 1)

-- 7.2.11 Repositories
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Analytics', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Analytics', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Communication', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Communication', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'CommunicationEngine', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/CommunicationEngine', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'CommunicationEvent', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/CommunicationEvent', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'CommunicationSalesOrder', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/CommunicationSalesOrder', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Contact', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Contact', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Core', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Core', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'CUST077', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/CUST077', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'DashBoard', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/DashBoard', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Demo', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Demo', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Earning', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Earning', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Employee', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Employee', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Engine', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Engine', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Event', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Event', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'FrameworkCore', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/FrameworkCore', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'FrameworkPayment', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/FrameworkPayment', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'FrameworkWeb', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/FrameworkWeb', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'GeneViz', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/GeneViz', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Genealogy', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Genealogy', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'GraphicGenealogy', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/GraphicGenealogy', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'ImportExport', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/ImportExport', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Jcoach', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Jcoach', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Jenkon.Feature', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Jenkon.Feature', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Payment', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Payment', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'PlanBuilder', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/PlanBuilder', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Realtime', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Realtime', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'SalesOrder', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/SalesOrder', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Summit', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Summit', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'Web', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/Web', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'WebConsultant', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/WebConsultant', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'WebEmployee', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/WebEmployee', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'WebPersonal', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/WebPersonal', 1)
INSERT [dbo].[Repository] ([Branch], [Feature], [URL], [HarvestFlag]) VALUES (N'releases/7.2.11', N'WebService', N'source.jenkon.com/hg/hgwebdir.cgi/feature/releases/7.2.11/WebService', 1)

-- Configure Viridian.
EXEC DeleteCustomerRepositoryMap @customerCode = N'CUST077'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Communication'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'CommunicationSalesOrder'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Contact'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Core'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'CUST077'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'DashBoard'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Earning'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Engine'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Genealogy'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'GraphicGenealogy'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'ImportExport'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Jcoach'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Payment'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'PlanBuilder'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'SalesOrder'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'Web'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'WebConsultant'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'WebEmployee'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'WebPersonal'
EXEC AddCustomerRepositoryMap @customerCode = N'CUST077', @branch = N'releases/7.2.11', @feature = N'WebService'
