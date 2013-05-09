ALTER TABLE [Redmine].[custom_values]  WITH CHECK ADD  CONSTRAINT [FK_custom_values_custom_fields] FOREIGN KEY([custom_field_id])
REFERENCES [Redmine].[custom_fields] ([id])
GO
ALTER TABLE [Redmine].[custom_values] CHECK CONSTRAINT [FK_custom_values_custom_fields]
GO
ALTER TABLE [Redmine].[custom_values]  WITH CHECK ADD  CONSTRAINT [FK_custom_values_issues] FOREIGN KEY([customized_id])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [Redmine].[custom_values] CHECK CONSTRAINT [FK_custom_values_issues]
GO
ALTER TABLE [Redmine].[issue_categories]  WITH CHECK ADD  CONSTRAINT [FK_issue_categories_projects] FOREIGN KEY([project_id])
REFERENCES [Redmine].[projects] ([id])
GO
ALTER TABLE [Redmine].[issue_categories] CHECK CONSTRAINT [FK_issue_categories_projects]
GO
ALTER TABLE [Redmine].[issue_relations]  WITH CHECK ADD  CONSTRAINT [FK_issue_relations_issues] FOREIGN KEY([issue_from_id])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [Redmine].[issue_relations] CHECK CONSTRAINT [FK_issue_relations_issues]
GO
ALTER TABLE [Redmine].[issue_relations]  WITH CHECK ADD  CONSTRAINT [FK_issue_relations_issues2] FOREIGN KEY([issue_to_id])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [Redmine].[issue_relations] CHECK CONSTRAINT [FK_issue_relations_issues2]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_enumerations] FOREIGN KEY([priority_id])
REFERENCES [Redmine].[enumerations] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_enumerations]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_issue_categories] FOREIGN KEY([category_id])
REFERENCES [Redmine].[issue_categories] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_issue_categories]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_issue_statuses] FOREIGN KEY([status_id])
REFERENCES [Redmine].[issue_statuses] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_issue_statuses]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_projects] FOREIGN KEY([project_id])
REFERENCES [Redmine].[projects] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_projects]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_trackers] FOREIGN KEY([tracker_id])
REFERENCES [Redmine].[trackers] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_trackers]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_users] FOREIGN KEY([author_id])
REFERENCES [Redmine].[users] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_users]
GO
ALTER TABLE [Redmine].[issues]  WITH CHECK ADD  CONSTRAINT [FK_issues_versions] FOREIGN KEY([fixed_version_id])
REFERENCES [Redmine].[versions] ([id])
GO
ALTER TABLE [Redmine].[issues] CHECK CONSTRAINT [FK_issues_versions]
GO
ALTER TABLE [Redmine].[journal_details]  WITH CHECK ADD  CONSTRAINT [FK_journal_details_journals] FOREIGN KEY([journal_id])
REFERENCES [Redmine].[journals] ([id])
GO
ALTER TABLE [Redmine].[journal_details] CHECK CONSTRAINT [FK_journal_details_journals]
GO
ALTER TABLE [Redmine].[journals]  WITH CHECK ADD  CONSTRAINT [FK_journals_issues] FOREIGN KEY([journalized_id])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [Redmine].[journals] CHECK CONSTRAINT [FK_journals_issues]
GO
ALTER TABLE [Redmine].[time_entries]  WITH CHECK ADD  CONSTRAINT [FK_time_entries_enumerations] FOREIGN KEY([activity_id])
REFERENCES [Redmine].[enumerations] ([id])
GO
ALTER TABLE [Redmine].[time_entries] CHECK CONSTRAINT [FK_time_entries_enumerations]
GO
ALTER TABLE [Redmine].[time_entries]  WITH CHECK ADD  CONSTRAINT [FK_time_entries_issues] FOREIGN KEY([issue_id])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [Redmine].[time_entries] CHECK CONSTRAINT [FK_time_entries_issues]
GO
ALTER TABLE [Redmine].[time_entries]  WITH CHECK ADD  CONSTRAINT [FK_time_entries_projects] FOREIGN KEY([project_id])
REFERENCES [Redmine].[projects] ([id])
GO
ALTER TABLE [Redmine].[time_entries] CHECK CONSTRAINT [FK_time_entries_projects]
GO
ALTER TABLE [Redmine].[time_entries]  WITH CHECK ADD  CONSTRAINT [FK_time_entries_users] FOREIGN KEY([user_id])
REFERENCES [Redmine].[users] ([id])
GO
ALTER TABLE [Redmine].[time_entries] CHECK CONSTRAINT [FK_time_entries_users]
GO
ALTER TABLE [Redmine].[versions]  WITH CHECK ADD  CONSTRAINT [FK_versions_projects] FOREIGN KEY([project_id])
REFERENCES [Redmine].[projects] ([id])
GO
ALTER TABLE [Redmine].[versions] CHECK CONSTRAINT [FK_versions_projects]
GO
ALTER TABLE [Redmine].[watchers]  WITH CHECK ADD  CONSTRAINT [FK_watchers_issues] FOREIGN KEY([watchable_id])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [Redmine].[watchers] CHECK CONSTRAINT [FK_watchers_issues]
GO

-- Change NTEXT fields to use NVARCHAR(MAX).
ALTER TABLE [Redmine].[projects] ALTER COLUMN [description] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[custom_fields] ALTER COLUMN [possible_values] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[custom_fields] ALTER COLUMN [default_value] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[issues] ALTER COLUMN [description] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[custom_values] ALTER COLUMN [value] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[journals] ALTER COLUMN [notes] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[journal_details] ALTER COLUMN [old_value] NVARCHAR(MAX) NULL
ALTER TABLE [Redmine].[journal_details] ALTER COLUMN [value] NVARCHAR(MAX) NULL

-- Move data from LOB.
UPDATE [Redmine].[projects] SET [description] = [description]
UPDATE [Redmine].[custom_fields] SET [possible_values] = [possible_values]
UPDATE [Redmine].[custom_fields] SET [default_value] = [default_value]
UPDATE [Redmine].[issues] SET [description] = [description]
UPDATE [Redmine].[custom_values] SET [value] = [value]
UPDATE [Redmine].[journals] SET [notes] = [notes]
UPDATE [Redmine].[journal_details] SET [old_value] = [old_value]
UPDATE [Redmine].[journal_details] SET [value] = [value]
